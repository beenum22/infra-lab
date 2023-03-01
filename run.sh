#!/bin/bash

#set -e
set -o pipefail

# Defaults
PIPE_OUTPUT=""
DEFAULT_K3S_UNINSTALL_PATH="/usr/local/bin/k3s-uninstall.sh"
DEFAULT_IPV4_CLUSTER_CIDR="10.42.0.0/16"
DEFAULT_IPV4_SERVICE_CIDR="10.43.0.0/16"
DEFAULT_IPV6_CLUSTER_CIDR="2001:cafe:42:0::/56"
DEFAULT_IPV6_SERVICE_CIDR="2001:cafe:42:1::/112"

#
APPS_TIMEOUT=20
KUBECONFIG_PATH=$HOME/.kube/config

# Reference: https://gist.github.com/goodmami/6556701
exec 3>&2 # logging stream (file descriptor 3) defaults to STDERR

SILENT=0
CRITICAL=1
ERROR=2
WARN=3
INFO=4
DEBUG=5

BLUE='\033[0;34m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
LIGHT_BROWN='\033[2;33m'
WHITE='\033[0;37m'
LIGHT_RED='\033[2;31m'
BOLD_RED='\033[4;31m'
RED='\033[0;31m'
NOCOLOR='\033[0m'

notify() { log $SILENT "NOTE: $1" ${WHITE}; } # Always prints
critical() { log $CRITICAL "CRITICAL: $1" ${BOLD_RED}; }
error() { log $ERROR "ERROR: $1" ${RED}; }
warn() { log $WARN "WARNING: $1" ${YELLOW}; }
info() { log $INFO "INFO: $1" ${GREEN}; } # "info" is already a command
debug() { log $DEBUG "DEBUG: $1" ${LIGHT_BROWN}; }
log() {
  if [ $verbosity -ge $1 ]; then
    datestring=`date +'%Y-%m-%d %H:%M:%S'`
    # Expand escaped characters, wrap at 70 chars, indent wrapped lines
   echo -e "${3}$datestring $2${NOCOLOR}" | fold -w70 -s | sed '2~1s/^/  /' >&3
  fi
}

# Usage: arguments_exception 2 $#
arguments_exception() {
  if [ "$1" -ne "$2" ]; then
    error "Insufficient arguments provided to function '$3'"
    exit 1
  fi
}

# Root privileges check
root_requirement_exception(){
  if [[ $EUID -ne 0 ]]; then
    error "You must be a root user" 2>&1
    exit 1
  fi
}

show_node_status() {
  pass
}

run_cmd(){
  arguments_exception 1 $# ${FUNCNAME}
  debug "Executing the command\n\t'$1'"

  out=$(eval "$1" 2>&1)

  if [ $? -ne 0 ]; then
    if [ ${verbosity} -eq ${DEBUG} ]; then
      error "Stderr: ${out}"
    fi
    return 1
  else
    return 0
  fi
}

get_k3s_status() {
  if run_cmd "systemctl is-active --quiet k3s.service" && run_cmd "kubectl --kubeconfig ${KUBECONFIG_PATH} cluster-info"; then
    debug "K3s cluster service is active"
    return 0
  else
    error "k3s cluster service is inactive or doesn't exist."
    return 1
  fi
}

install_k3s() {
  # Downloads and deploys the K3s cluster
  K3S_INSTALL_CMD="curl -sfL https://get.k3s.io | \
  INSTALL_K3S_EXEC=\"--cluster-cidr=${DEFAULT_IPV4_CLUSTER_CIDR},${DEFAULT_IPV6_CLUSTER_CIDR} \
  --service-cidr=${DEFAULT_IPV4_SERVICE_CIDR},${DEFAULT_IPV6_SERVICE_CIDR} \
  --kubelet-arg=node-ip=:: \
  --disable servicelb\" \
  sh -s -${PIPE_OUTPUT}"

#  root_requirement_exception

  if get_k3s_status; then
    error "K3s cluster is already installed. Check the status using 'kubectl cluster-info'."
    exit 1
  fi

  info "Installing K3s cluster ..."

  if run_cmd "${K3S_INSTALL_CMD}" && get_k3s_status; then
    info "Copying the K3s config to '$HOME/.kube/config' and setting KUBECONFIG env var"
    run_cmd "sudo cp /etc/rancher/k3s/k3s.yaml ${KUBECONFIG_PATH} && chown $USER ${KUBECONFIG_PATH} && chmod 600 ${KUBECONFIG_PATH}"
    run_cmd "if ! sudo grep -qF 'KUBECONFIG=$HOME/.kube/config' /etc/environment; then echo "KUBECONFIG=${KUBECONFIG_PATH}" | sudo tee -a /etc/environment; fi"
    info "Successfully installed the K3s cluster"
  else
    error "Failed to uninstall the K3s cluster"
    exit 1
  fi
}

uninstall_k3s() {
  # Destroys the K3s cluster
  K3S_UNINSTALL_CMD="/usr/local/bin/k3s-uninstall.sh"

#  root_requirement_exception

  if [ ! -f "${DEFAULT_K3S_UNINSTALL_PATH}" ]; then
    error "K3s cluster uninstall script doesn't exist at '${DEFAULT_K3S_UNINSTALL_PATH}'. Probably the cluster is already deleted."
    exit 1
  fi

  info "Uninstalling K3s cluster ..."

  if run_cmd "${K3S_UNINSTALL_CMD}"; then
    info "Successfully uninstalled the K3s cluster"
  else
    error "Failed to uninstall the K3s cluster"
    exit 1
  fi
}

join_k3s() {
  error "Joining K3s cluster is currently not supported by the script."
  exit 1
}

leave_k3s() {
  error "Leaving K3s cluster is currently not supported by the script."
  exit 1
}

expose_traefik() {
  # Install all the kubernetes apps using Helm file or optionally kustomize/normal patches
  if ! get_k3s_status; then
    error "K3s cluster status checked failed. Apps need K3s cluster to be up. Are you sure the cluster is running?"
    exit 1
  fi
  if [ $(yq '.apps.traefik.dashboard.expose' helm-vars.yaml) == true ]; then
    PATCH_TIMESTAMP=$(date +"%s")
    TRAEFIK_DASHBOARD_PORT=$(yq '.apps.traefik.dashboard.port' helm-vars.yaml)
    METALLB_POOL_NAME=$(yq '.apps.metallb.pool.name' helm-vars.yaml)
    info "Exposing built-in Traefik Dashboard on '${TRAEFIK_PORT}' port and '${METALLB_POOL_NAME}' MetalLB pool"
    debug "Copying Traefik Dashboard patch at '/var/lib/rancher/k3s/server/manifests/traefik-patch.yaml' that will be applied by K3s automatically."
    run_cmd "cat traefik/traefik-patch.yaml | sed \"s/{{ PATCH_TIMESTAMP }}/${PATCH_TIMESTAMP}/g\" | sed \"s/{{ METALLB_POOL_NAME }}/${METALLB_POOL_NAME}/g\" | sed \"s/{{ TRAEFIK_DASHBOARD_PORT }}/${TRAEFIK_DASHBOARD_PORT}/g\"  | sudo tee /var/lib/rancher/k3s/server/manifests/traefik-patch.yaml"
#    sed "s/{{ METALLB_POOL_NAME }}/${METALLB_POOL_NAME}/g" traefik/traefik-patch.yaml | sed "s/{{ TRAEFIK_DASHBOARD_PORT }}/${TRAEFIK_DASHBOARD_PORT}/g"  | sudo tee /var/lib/rancher/k3s/server/manifests/traefik-patch.yaml
    info "Waiting ${APPS_TIMEOUT} sec for K3s to expose Traefik Dasbhoard"
    TIMEOUT=${APPS_TIMEOUT}
    until [ ${TIMEOUT} -eq 5 ] || run_cmd "kubectl -n kube-system get svc traefik -o json | jq --exit-status '.spec.ports[] | select(.port==${TRAEFIK_DASHBOARD_PORT})'"; do
      info "Sleeping for a second..."
      sleep 1
      let TIMEOUT-=1
    done

    if [ ${TIMEOUT} -eq 0 ]; then
      error "Failing to expose the built-in Traefik Dasbhoard"
    else
      info "Traefik Dashboard is successfully exposed"
    fi
  fi
}

install_metallb() {
  # Install MetalLB helm chart
  info "Installing Metallb on '${TRAEFIK_PORT}' port and '${METALLB_POOL_NAME}' MetalLB pool"
}

# Main
main() {
  for arg in "$@"; do
    shift
    case "$arg" in
#      'help') set -- "$@" '-h'   ;;
      '--installk3s') set -- "$@" '-i'   ;;
      '--uninstallk3s')   set -- "$@" '-u'   ;;
      '--joink3s')   set -- "$@" '-j'   ;;
      '--leavek3s')   set -- "$@" '-l'   ;;
      '--exposetraefik')   set -- "$@" '-e'   ;;
      '--installmetallb')   set -- "$@" '-e'   ;;
      '--verbosity')   set -- "$@" '-v'   ;;
      *)          set -- "$@" "$arg" ;;
    esac
  done

  # Default behavior
  installk3s=false
  uninstallk3s=false
  joink3s=false
  leavek3s=false
  exposetraefik=false
  metallb=false
  verbosity=4

  # Parse short options
  OPTIND=1
  while getopts "i:u:j:l:e:v:m:" opt
#  while getopts "hi:u" opt
  do
    case "$opt" in
#      'h') print_usage; exit 0 ;;
      'i') installk3s=$OPTARG ;;
      'u') uninstallk3s=true ;;
      'j') joink3s=true ;;
      'l') leavek3s=true ;;
      'e') exposetraefik=true ;;
      'v') verbosity=$OPTARG ;;
      'v') installmetallb=true ;;
#      '?') print_usage >&2; exit 1 ;;
    esac
  done
  shift $(expr $OPTIND - 1) # remove options from positional parameters

  if [ ${installk3s} == true ]; then
    install_k3s
  fi

  if [ ${uninstallk3s} == true ]; then
    uninstall_k3s
  fi

  if [ ${joink3s} == true ]; then
    join_k3s
  fi

  if [ ${leavek3s} == true ]; then
    leave_k3s
  fi

  if [ ${exposetraefik} == true ]; then
      expose_traefik
  fi

  if [ ${installmetallb} == true ]; then
      expose_traefik
  fi

}

main "$@"
