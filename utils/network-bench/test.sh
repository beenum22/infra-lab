#!/usr/bin/env bash

NAMESPACE=testing

# Check if kubectl is installed
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        log "Error: kubectl is not installed."
        exit 1
    fi
}

# Function to create namespace if it doesn't exist
create_namespace() {
    local namespace="$1"
    log "Creating namespace '$namespace' if it doesn't exist..."
    if ! kubectl get namespace "$namespace" &> /dev/null; then
        if kubectl create namespace "$namespace"; then
            log "Namespace '$namespace' created successfully."
        else
            log "Error creating namespace '$namespace'."
            exit 1
        fi
    else
        log "Namespace '$namespace' already exists."
    fi
}

# Function to fetch Pod IP/IPs of the deployed Pod
fetch_pod_ips() {
    local namespace="$1"
    local label="$2"
    local pod_ips=$(kubectl get pods -n "$namespace" -l "${label}" -o jsonpath="{.items[*].status.podIP}")
    echo "${pod_ips}"
}

# Function to get all node names in the Kubernetes cluster
get_node_names() {
    local node_names=$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}')
    echo "${node_names}"
}

# Function to deploy Netperf Server Kubernetes manifest
deploy_netperf_server() {
    local namespace="$1"
    local manifest="./netperf-server.yaml"
    title "Deploying Netperf Server in namespace '$namespace'..."
    if kubectl apply -f "${manifest}" -n "${namespace}" &> /dev/null; then
        log "Netperf Server is deployed successfully."
    else
        log "Error deploying Netperf Server."
        exit 1
    fi
    log "Fetching Netperf Server Details..."
    log "Netperf Server Domain: \n\t$(kubectl get svc -n "${namespace}" -l "app.kubernetes.io/name=netperf-server" -o jsonpath="{.items[*].metadata.name}")"
    log "Netperf Server IP: \n\t$(fetch_pod_ips "${namespace}" "app.kubernetes.io/name=netperf-server")"
}

# Function to deploy Netperf Client Kubernetes DaemonSet manifest
deploy_netperf_client_ds() {
    local namespace="$1"
    local manifest="./netperf-client.yaml"
    title "Deploying Netperf Client for all the nodes in namespace '$namespace'..."
    if kubectl apply -f "${manifest}" -n "${namespace}" &> /dev/null; then
        log "Netperf Client is deployed successfully."
    else
        log "Error deploying Client Server."
        exit 1
    fi
    log "Fetching Netperf Client Details..."
    log "Netperf Client IPs: \n\t$(fetch_pod_ips "${namespace}" "app.kubernetes.io/name=netperf-client")"
}

# Function to format message with '=>' prefix
#log() {
#    local message="$1"
#    echo -e "=> $message"
#}

title() {
    local message="$1"
    echo -e "- $message"
}

log() {
    local message="$1"
    echo -e "====> $message"
}

# Main function
main() {
    cat <<'END_CAT'
      ___ ___       __   __
|\ | |__   |  |  | /  \ |__) |__/
| \| |___  |  |/\| \__/ |  \ |  \

 __   ___       __                   __               __
|__) |__  |\ | /  ` |__|  |\/|  /\  |__) |__/ | |\ | / _`
|__) |___ | \| \__, |  |  |  | /~~\ |  \ |  \ | | \| \__>

END_CAT
    title "Setting up pre-requisites for benchmark tasks..."
    local namespace="$1"
    # Check if namespace argument is provided
    if [ -z "$namespace" ]; then
        log "Usage: $0 <namespace>"
        exit 1
    fi
    log "Setting '${namespace}' as benchmark Kubernetes namespace"

    check_kubectl
    create_namespace "${namespace}"

    title "Starting benchmarking tasks..."
    local nodes=$(get_node_names)
    log "Target Nodes: \n\t${nodes}"
    deploy_netperf_server "${namespace}"

#    deploy_netperf_client_ds "${namespace}"
}

# Execute main function with command-line argument
main "$1"