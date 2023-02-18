#!/bin/bash

set -e

# Usage: arguments_exception 2 $#
arguments_exception() {
  if [ "$1" -ne "$2" ]; then
    echo Insufficient argments provided
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
  echo "n/a"
  pass
}

exec 3>&2 # logging stream (file descriptor 3) defaults to STDERR
verbosity=3 # default to show warnings
silent_lvl=0
crt_lvl=1
err_lvl=2
wrn_lvl=3
inf_lvl=4
dbg_lvl=5

notify() {
  log $silent_lvl "NOTE: $1";
} # Always prints
critical() { log $crt_lvl "CRITICAL: $1"; }
error() { log $err_lvl "ERROR: $1"; }
warn() { log $wrn_lvl "WARNING: $1"; }
inf() { log $inf_lvl "INFO: $1"; } # "info" is already a command
debug() { log $dbg_lvl "DEBUG: $1"; }
log() {
    if [ $verbosity -ge $1 ]; then
        datestring=`date +'%Y-%m-%d %H:%M:%S'`
        # Expand escaped characters, wrap at 70 chars, indent wrapped lines
        echo -e "$datestring $2" | fold -w70 -s | sed '2~1s/^/  /' >&3
    fi
}

PIPE_OUTPUT=" > /dev/null"
DEFAULT_K3S_UNINSTALL_PATH="/usr/local/bin/k3s-uninstall.sh"
DEFAULT_IPV4_CLUSTER_CIDR="10.42.0.0/16"
DEFAULT_IPV4_SERVICE_CIDR="10.43.0.0/16"
DEFAULT_IPV6_CLUSTER_CIDR="2001:cafe:42:0::/56"
DEFAULT_IPV6_SERVICE_CIDR="2001:cafe:42:1::/112"

deploy_k3s() {
  # Downloads and deploys the K3s cluster
  K3S_INSTALL_CMD="curl -sfL https://get.k3s.io | \
  INSTALL_K3S_EXEC=\"--cluster-cidr=${DEFAULT_IPV4_CLUSTER_CIDR},${DEFAULT_IPV6_CLUSTER_CIDR} \
  --service-cidr=${DEFAULT_IPV4_SERVICE_CIDR},${DEFAULT_IPV6_SERVICE_CIDR} \
  --kubelet-arg=node-ip=:: \
  --disable servicelb\" \
  sh -s -${PIPE_OUTPUT}"

  root_requirement_exception

  if ! eval "${K3S_INSTALL_CMD}"; then
    echo "Failed to deploy the K3s cluster"
  fi
}

destroy_k3s() {
  # Destroys the K3s cluster
  K3S_UNINSTALL_CMD="/usr/local/bin/k3s-uninstall.sh${PIPE_OUTPUT}"

  root_requirement_exception

  if test -f "${DEFAULT_K3S_UNINSTALL_PATH}"; then
    error "K3s uninstall script not found"
  fi

  if ! eval "${K3S_UNINSTALL_CMD}"; then
    error "Failed to destroy the K3s cluster"
  fi
}
#
#help()
#{
#   # Display Help
#   echo "Handle all the operations related to home Pi cluster."
#   echo
#   echo "Syntax: scriptTemplate [-g|h|v|V]"
#   echo "options:"
#   echo "g     Print the GPL license notification."
#   echo "h     Print this Help."
#   echo "v     Verbose mode."
#   echo "V     Print software version and exit."
#   echo
#}

# Main
main() {
  destroy_k3s
}

main
