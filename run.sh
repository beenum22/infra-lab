#!/bin/bash

set -e

# Defaults
PIPE_OUTPUT=""
DEFAULT_K3S_UNINSTALL_PATH="/usr/local/bin/k3s-uninstall.sh"
DEFAULT_IPV4_CLUSTER_CIDR="10.42.0.0/16"
DEFAULT_IPV4_SERVICE_CIDR="10.43.0.0/16"
DEFAULT_IPV6_CLUSTER_CIDR="2001:cafe:42:0::/56"
DEFAULT_IPV6_SERVICE_CIDR="2001:cafe:42:1::/112"

# Reference: https://gist.github.com/goodmami/6556701
exec 3>&2 # logging stream (file descriptor 3) defaults to STDERR
verbosity=4 # default to show warnings
SILENT=0
CRITICAL=1
ERROR=2
WARN=3
INFO=4
DEBUG=5

notify() { log $SILENT "NOTE: $1"; } # Always prints
critical() { log $CRITICAL "CRITICAL: $1"; }
error() { log $ERROR "ERROR: $1"; }
warn() { log $WARN "WARNING: $1"; }
info() { log $INFO "INFO: $1"; } # "info" is already a command
debug() { log $DEBUG "DEBUG: $1"; }
log() {
  if [ $verbosity -ge $1 ]; then
    datestring=`date +'%Y-%m-%d %H:%M:%S'`
    # Expand escaped characters, wrap at 70 chars, indent wrapped lines
   echo -e "$datestring $2" | fold -w70 -s | sed '2~1s/^/  /' >&3
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
      error "${out}"
    fi
    return 1
  else
    return 0
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

  root_requirement_exception

  if run_cmd "kubectl cluster-info"; then
    error "K3s cluster is already installed. Check the status using 'kubectl cluster-info'."
    exit
  fi

  info "Installing K3s cluster ..."

  if run_cmd "${K3S_INSTALL_CMD}"; then
    info "Successfully installed the K3s cluster"
  else
    error "Failed to uninstall the K3s cluster"
    exit 1
  fi
}

uninstall_k3s() {
  # Destroys the K3s cluster
  K3S_UNINSTALL_CMD="/usr/local/bin/k3s-uninstall.sh"

  root_requirement_exception

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

# Main
main() {
  for arg in "$@"; do
    shift
    case "$arg" in
#      'help') set -- "$@" '-h'   ;;
      '--installk3s') set -- "$@" '-i'   ;;
      '--uninstallk3s')   set -- "$@" '-u'   ;;
      *)          set -- "$@" "$arg" ;;
    esac
  done

  # Default behavior
  installk3s=false; uninstallk3s=false

  # Parse short options
  OPTIND=1
  while getopts "i:u" opt
#  while getopts "hi:u" opt
  do
    case "$opt" in
#      'h') print_usage; exit 0 ;;
      'i') installk3s=$OPTARG ;;
      'u') uninstallk3s=true ;;
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
}

main "$@"
