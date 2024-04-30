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

# Function to fetch all pod names for a given label
fetch_pod_names() {
    local namespace="$1"
    local label="$2"
    kubectl get pods -n "${namespace}" -l "${label}" -o jsonpath="{.items[*].metadata.name}"
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

# Function to get node name for a specific pod
get_node_name_for_pod() {
    local namespace="$1"
    local pod_name="$2"
    kubectl get pod -n "${namespace}" "${pod_name}" -o jsonpath="{.spec.nodeName}"
}


select_random_node() {
    local node_names="$1"
    local num_nodes=$(echo "$node_names" | wc -l)
    local random_index=$(( RANDOM % num_nodes + 1 ))
    local random_node=$(echo "$node_names" | sed -n "${random_index}p")
    echo "$random_node"
}

# Function to deploy Netperf Server Kubernetes manifest
deploy_netperf_server() {
    local namespace="$1"
    local node="$2"
    local manifest="netperf-server.yaml"

    # Define cleanup function
    cleanup() {
        rm -f "_${manifest}"
    }
    trap cleanup EXIT

    title "Deploying Netperf Server on '${node}' node in a '$namespace' namespace"

    # Run sed command to replace the placeholder and check for errors
    sed "s/NODE/${node}/g" "${manifest}" > "_${manifest}" || { log "Error: Failed to replace placeholder using sed."; exit 1; }

    # Apply the modified manifest file and check for errors
    kubectl apply -f "_${manifest}" -n "${namespace}" &> /dev/null || { log "Error deploying Netperf Server."; exit 1; }

    # Clean up the temporary file
    rm "_${manifest}"

    # Log additional details
    log "Netperf Server is deployed successfully."
    log "Fetching Netperf Server Details..."
    log "Netperf Server Domain: \n\t$(kubectl get svc -n "${namespace}" -l "app.kubernetes.io/name=netperf-server" -o jsonpath="{.items[*].metadata.name}")"
    log "Netperf Server IP: \n\t$(fetch_pod_ips "${namespace}" "app.kubernetes.io/name=netperf-server")"
}

# Function to destroy Netperf Server Kubernetes manifest
destroy_netperf_server() {
    local namespace="$1"
    local node="$2"
    local manifest="netperf-server.yaml"

    # Define cleanup function
    cleanup() {
        rm -f "_${manifest}"
    }
    trap cleanup EXIT

    title "Deleting Netperf Server on '${node}' node in a '$namespace' namespace"

    # Run sed command to replace the placeholder and check for errors
    sed "s/NODE/${node}/g" "${manifest}" > "_${manifest}" || { log "Error: Failed to replace placeholder using sed."; exit 1; }

    # Delete the modified manifest file and check for errors
    kubectl delete -f "_${manifest}" -n "${namespace}" &> /dev/null || { log "Error deploying Netperf Server."; exit 1; }

    # Log additional details
    log "Netperf Server is deleted successfully."
}

# Function to deploy Netperf Client Kubernetes DaemonSet manifest
deploy_netperf_client_ds() {
    local namespace="$1"
    local manifest="netperf-client.yaml"

    # Define cleanup function
    cleanup() {
        rm -f "_${manifest}"
    }
    trap cleanup EXIT

    title "Deploying Netperf Client for all the nodes in '$namespace' namespace"

    # Apply the manifest and check for errors
    if kubectl apply -f "${manifest}" -n "${namespace}" &> /dev/null; then
        log "Netperf Clients are deployed successfully."
    else
        log "Error deploying Netperf Clients."
        exit 1
    fi

    # Wait for all client pods to be running and healthy
    log "Waiting for all Netperf Clients to be ready..."
    until kubectl get pods -n "${namespace}" -l "app.kubernetes.io/name=netperf-client" --field-selector=status.phase=Running 2>&1 | grep -q "Running"; do
        sleep 5
    done

    # Log additional details
    log "Fetching Netperf Client Details..."
    log "Netperf Client Pods: \n\t$(fetch_pod_names "${namespace}" "app.kubernetes.io/name=netperf-client")"
    log "Netperf Client IPs: \n\t$(fetch_pod_ips "${namespace}" "app.kubernetes.io/name=netperf-client")"
}

destroy_netperf_client_ds() {
    local namespace="$1"
    local manifest="netperf-client.yaml"

    # Define cleanup function
    cleanup() {
        rm -f "_${manifest}"
    }
    trap cleanup EXIT

    title "Deleting Netperf Clients for all the nodes in '$namespace' namespace"

    # Delete the manifest and check for errors
    if kubectl delete -f "${manifest}" -n "${namespace}" &> /dev/null; then
        log "Netperf Clients are deleted successfully."
    else
        log "Error deleting Netperf Clients."
        exit 1
    fi
}

# Function to convert Bytes to Kilo Bytes
to_kb() {
    echo "scale=2; $1 / 1024" | bc
}

# Function to convert seconds to minutes
to_minutes() {
    echo "scale=2; $1 / 60" | bc
}

# Function to parse and format netperf TCP_STREAM
format_netperf_tcp_stream() {
    local output="$1"

    # Parse the last line to extract values
    read socket_size recv_size send_size elapsed_time throughput <<< "$output"

    log " TCP Throughput:
    \tSocket Buffer Size (Recv): $(to_kb ${socket_size}), Socket Buffer Size (Send): $(to_kb ${recv_size}) KB
    \tMessage Size: $(to_kb ${send_size}) KB, Elapsed Time: ${elapsed_time} seconds
    \tThroughput: ${throughput} Mbps"
}

# Function to parse and format netperf TCP_RR
format_netperf_tcp_rr() {
    local output="$1"

    # Parse the last line to extract values
    read socket_size recv_size req_size resp_size elapsed_time transaction <<< "$output"
#    exit 0
    log " TCP Latency:
    \tSocket Buffer Size (Recv): $(to_kb ${socket_size}), Socket Buffer Size (Send): $(to_kb ${recv_size}) KB
    \tRequest Size: ${req_size} B, Response Size: ${resp_size} B, Elapsed Time: ${elapsed_time} seconds
    \tTransaction Rate: ${transaction} tps"
}

# Function to perform internode netperf tests
perform_internode_netperf_tests() {
    local namespace="$1"
    local server_label="$2"
    local client_label="$3"
    local server_ip
    local client_pods
    local netperf_output

    # Get the IP of the netperf server
    server_ip=$(fetch_pod_ips "${namespace}" "${server_label}")
    server_name=$(fetch_pod_names "${namespace}" "${server_label}")
    server_node=$(get_node_name_for_pod "${namespace}" "${server_name}")

    # Get the names of all netperf client pods
    client_pods=$(fetch_pod_names "${namespace}" "${client_label}")

    # Iterate over each client pod and perform netperf tests for TCP and UDP protocols
    tcp_stream_results=()
    tcp_rr_results=()
    for client_pod in $client_pods; do
        client_pod_node=$(get_node_name_for_pod "${namespace}" "${client_pod}")
        log "Performing netperf tests from ${client_pod} (${client_pod_node}) to netperf-server (${server_node})..."

        # Execute netperf client command for TCP_STREAM test
        tcp_stream_result=$(kubectl exec -n "${namespace}" "${client_pod}" -- sh -c "./netperf -H "${server_ip}" -l 15 -t TCP_STREAM -P 0")
        format_netperf_tcp_stream "${tcp_stream_result}"
        tcp_stream_results+=("${tcp_stream_result}")

        # Execute netperf client command for TCP_RR test
        tcp_rr_result=$(kubectl exec -n "${namespace}" "${client_pod}" -- sh -c "./netperf -H "${server_ip}" -l 15 -t TCP_RR -P 0")
        format_netperf_tcp_rr "${tcp_rr_result}"
        tcp_rr_results+=("${tcp_rr_result}")

        # Execute netperf client command for UDP_STREAM test
#        netperf_output=$(kubectl exec -n "${namespace}" "${client_pod}" -- netperf -H "${server_ip}" -l 10 -t UDP_STREAM -- -o THROUGHPUT,99th_LATENCY,JITTER,MIN_LATENCY,MAX_LATENCY,PRL -P 0)
#        format_netperf_output "${netperf_output}"

        log "Netperf tests completed from ${client_pod} (${client_pod_node}) to netperf-server (${server_node})."
    done

#        format_netperf_output ${tcp_stream_result}
#        echo "${netperf_output}"

#        # Execute netperf client command for UDP_STREAM test
#        log "UDP Throughput Test Results:"
#        netperf_output=$(kubectl exec -n "${namespace}" "${client_pod}" -- netperf -H "${server_ip}" -l 10 -t UDP_STREAM -- -o THROUGHPUT,99th_LATENCY,JITTER,MIN_LATENCY,MAX_LATENCY,PRL -P 0)
#        format_netperf_output "${netperf_output}"
#
#        # Execute netperf client command for TCP_RR test
#        log "TCP Request-Response Test Results:"
#        netperf_output=$(kubectl exec -n "${namespace}" "${client_pod}" -- netperf -H "${server_ip}" -l 10 -t TCP_RR -- -o REQUEST_RESPONSE_LATENCY,THROUGHPUT,PRL -P 0)
#        format_netperf_output "${netperf_output}"
#
#        # Execute netperf client command for UDP_RR test
#        log "UDP Request-Response Test Results:"
#        netperf_output=$(kubectl exec -n "${namespace}" "${client_pod}" -- netperf -H "${server_ip}" -l 10 -t UDP_RR -- -o REQUEST_RESPONSE_LATENCY,THROUGHPUT,PRL -P 0)
#        format_netperf_output "${netperf_output}"
#
#        # Execute netperf client command for TCP_CRR test
#        log "TCP Connection Request-Response Test Results:"
#        netperf_output=$(kubectl exec -n "${namespace}" "${client_pod}" -- netperf -H "${server_ip}" -l 10 -t TCP_CRR -- -o CONNECTION_REQUEST_RESPONSE_LATENCY,THROUGHPUT,PRL -P 0)
#        format_netperf_output "${netperf_output}"
#
#        # Execute netperf client command for UDP_CRR test
#        log "UDP Connection Request-Response Test Results:"
#        netperf_output=$(kubectl exec -n "${namespace}" "${client_pod}" -- netperf -H "${server_ip}" -l 10 -t UDP_CRR -- -o CONNECTION_REQUEST_RESPONSE_LATENCY,THROUGHPUT,PRL -P 0)
#        format_netperf_output "${netperf_output}"
#
#        # Execute netperf client command for TCP_MAERTS test
#        log "TCP Round-Trip Time and Throughput Test Results:"
#        netperf_output=$(kubectl exec -n "${namespace}" "${client_pod}" -- netperf -H "${server_ip}" -l 10 -t TCP_MAERTS -- -o ROUND_TRIP_TIME,THROUGHPUT,PRL -P 0)
#        format_netperf_output "${netperf_output}"
#
#        # Execute netperf client command for TCP_MAERTS_C test
#        log "TCP Round-Trip Time, Throughput, and Connection Handling Test Results:"
#        netperf_output=$(kubectl exec -n "${namespace}" "${client_pod}" -- netperf -H "${server_ip}" -l 10 -t TCP_MAERTS_C -- -o ROUND_TRIP_TIME,THROUGHPUT,CONNECTION_HANDLING,PRL -P 0)
#        format_netperf_output "${netperf_output}"

#        log "Netperf tests completed from ${client_pod} to netperf-server."
#        return
}

title() {
    local message="$1"
    echo -e "\e[1;33m----- $message -----\e[0m"
}

log() {
    local message="$1"
    echo -e "\e[1;34m===>\e[0m $message"
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
    title "Setting up pre-requisites for benchmark tasks"
    local namespace="${NAMESPACE}"

    if [ -z "$namespace" ]; then
        log "Usage: $0 <namespace>"
        exit 1
    fi
    log "Setting '${namespace}' as benchmark Kubernetes namespace"

    check_kubectl
    create_namespace "${namespace}"

    title "Starting benchmarking tasks"
    local nodes=$(get_node_names)
    server_node=$(select_random_node ${nodes})
    log "Target Nodes: \n\t${nodes}"
    deploy_netperf_server "${namespace}" "${server_node}"

    deploy_netperf_client_ds "${namespace}"

    perform_internode_netperf_tests "${namespace}" "app.kubernetes.io/name=netperf-server" "app.kubernetes.io/name=netperf-client"

    destroy_netperf_client_ds "${namespace}"

    destroy_netperf_server "${namespace}" "${server_node}"
}

# Execute main function with command-line argument
main "$1"
