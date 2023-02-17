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
    echo "You must be a root user" 2>&1
    exit 1
  fi
}

show_node_status() {
  echo "n/a"
  pass
}

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
  sh -s -"

  root_requirement_exception

  if ! eval "${K3S_INSTALL_CMD}"; then
    echo "Failed to deploy the K3s cluster"
  fi
}

destroy_k3s() {
  # Destroys the K3s cluster
  K3S_UNINSTALL_CMD="/usr/local/bin/k3s-uninstall.sh"

  root_requirement_exception

  if ! eval "${K3S_UNINSTALL_CMD}"; then
    echo "Failed to destroy the K3s cluster"
  fi
}
