terraform {
  required_providers {
    tailscale = {
      source = "tailscale/tailscale"
      version = ">= 0.13.13"
    }
    ssh = {
      source = "loafoe/ssh"
      version = "2.6.0"
    }
    local = {
      source = "hashicorp/local"
      version = "2.4.0"
    }
  }
}

// Fetch the last version of k3s
data "http" "version" {
  url = "https://update.k3s.io/v1-release/channels"
}

# Fetch the k3s installation script
data "http" "installer" {
  url = "https://raw.githubusercontent.com/rancher/k3s/${var.k3s_version}/install.sh"
}

locals {
  // Use the fetched version if 'lastest' is specified
  k3s_version = var.k3s_version == "latest" ? jsondecode(data.http.version.response_body).data[1].latest : var.k3s_version
}

locals {
  base_cmd = [
    var.cluster_role,
    var.cluster_role == "server" ? "--egress-selector-mode=disabled" : null,
    var.cluster_role == "server" ? "--flannel-backend=host-gw" : null,
#    "--vpn-auth='name=tailscale,joinKey=${var.tailscale_authkey}'",
    "--flannel-iface=${var.flannel_interface}",
    var.cluster_role == "server" ? "--flannel-ipv6-masq" : null,
    "--kubelet-arg=node-ip=::",
    "--token='${var.token}'",
    var.cluster_role == "server" ? "--disable=servicelb,traefik,local-storage" : null,
  ]
  init_cmd = var.cluster_init ? concat(compact(local.base_cmd), ["--cluster-init"]) : concat(compact(local.base_cmd), ["--server=https://${var.api_host}:6443"])
  final_cmd = var.cluster_role == "server" ? concat(local.init_cmd, ["--cluster-cidr=${var.cluster_cidrs}", "--service-cidr=${var.service_cidrs}"]) : local.init_cmd
  kubectl_args = var.kubeconfig != null ? "--kubeconfig <(echo \"${var.kubeconfig}\") " : "--kubeconfig /etc/rancher/k3s/k3s.yaml "
}

resource "ssh_resource" "tls" {
  for_each = { for path, content in var.tls_config : path => content if var.cluster_role == "server" }
#  for_each = var.tls_config
  when = "create"
  host = var.connection_info.host
  user = var.connection_info.user
  private_key = var.connection_info.private_key
  timeout = "1m"
  retry_delay = "5s"
  commands = [
    "${ var.use_sudo ? "sudo " : "" }mkdir -p /var/lib/rancher/k3s/server/tls/",
    "echo '${each.value}' | ${ var.use_sudo ? "sudo " : "" }tee -a /var/lib/rancher/k3s/server/tls/${each.key}"
  ]
#  file {
#    content     = each.value
#    destination = "/var/lib/rancher/k3s/server/tls/${each.key}"
#    permissions = "0400"
#  }
}

resource "ssh_resource" "install" {
  when = "create"
  host = var.connection_info.host
  user = var.connection_info.user
  private_key = var.connection_info.private_key
  timeout = "15m"
  retry_delay = "5s"
  file {
    content     = data.http.installer.response_body
    destination = "/tmp/k3s-installer"
    permissions = "0700"
  }
  commands = [
    "INSTALL_K3S_VERSION=${local.k3s_version} sh /tmp/k3s-installer ${join(" ", local.final_cmd)}",
  ]
}

resource "ssh_resource" "check_status" {
  host = var.connection_info.host
  user = var.connection_info.user
  when = "create"
  private_key = var.connection_info.private_key
  timeout = "1m"
  retry_delay = "5s"
  pre_commands = [
    var.kubeconfig == null ? "${ var.use_sudo ? "sudo " : "" }chown ${var.connection_info.user}:$USER /etc/rancher/k3s/k3s.yaml" : "echo 'Using provided kubeconfig'",
  ]
  commands = [
    "until kubectl ${local.kubectl_args}get node ${var.hostname}; do sleep 1; done"
  ]
  depends_on = [
    ssh_resource.install
  ]
}

resource "ssh_resource" "node_cidrs" {
  host = var.connection_info.host
  user = var.connection_info.user
  when = "create"
  private_key = var.connection_info.private_key
  timeout = "1m"
  retry_delay = "5s"
  commands = [
    "kubectl ${local.kubectl_args}get nodes ${var.hostname} -o json | jq -r '.spec.podCIDRs | join(\",\")'"
  ]
  depends_on = [
    ssh_resource.check_status
  ]
}

resource "ssh_resource" "add_node_labels" {
  for_each = var.node_labels
  host = var.connection_info.host
  user = var.connection_info.user
  when = "create"
  private_key = var.connection_info.private_key
  timeout = "1m"
  retry_delay = "5s"
  commands = [
    "kubectl ${local.kubectl_args}label nodes ${var.hostname} ${each.key}=${each.value}"
  ]
  depends_on = [
    ssh_resource.install
  ]
}

resource "ssh_resource" "advertise_routes" {
  host = var.connection_info.host
  user = var.connection_info.user
  when = "create"
  private_key = var.connection_info.private_key
  timeout = "1m"
  retry_delay = "5s"
  commands = [
    "${ var.use_sudo ? "sudo " : "" }tailscale set --advertise-routes=''",
    "${ var.use_sudo ? "sudo " : "" }tailscale set --advertise-routes=${trimspace(ssh_resource.node_cidrs.result)}"
  ]
  depends_on = [
    ssh_resource.install
  ]
}

resource "ssh_resource" "remove_node_labels" {
  for_each = var.graceful_destroy ? var.node_labels : {}
  host = var.connection_info.host
  user = var.connection_info.user
  when = "destroy"
  private_key = var.connection_info.private_key
  timeout = "1m"
  retry_delay = "5s"
  commands = [
    "kubectl ${local.kubectl_args}--request-timeout 15s label --overwrite nodes ${var.hostname} ${each.key}-"
  ]
  depends_on = [
    ssh_resource.uninstall,
    ssh_resource.drain_node,
  ]
}

resource "ssh_resource" "remove_routes" {
  host = var.connection_info.host
  user = var.connection_info.user
  when = "destroy"
  private_key = var.connection_info.private_key
  timeout = "1m"
  retry_delay = "5s"
  commands = [
    "${ var.use_sudo ? "sudo " : "" }tailscale set --advertise-routes="
  ]
#  depends_on = [
#    ssh_resource.drain_node,
#    ssh_resource.uninstall,
#  ]
}

resource "ssh_resource" "drain_node" {
  count = var.graceful_destroy ? 1 : 0
  host = var.connection_info.host
  user = var.connection_info.user
  when = "destroy"
  private_key = var.connection_info.private_key
  timeout = "5m"
  retry_delay = "5s"
  commands = [
    "kubectl ${local.kubectl_args}--request-timeout 15s drain --ignore-daemonsets --delete-emptydir-data ${var.hostname}"
  ]
  depends_on = [
    ssh_resource.uninstall
  ]
}

resource "ssh_resource" "uninstall" {
  when = "destroy"
  host = var.connection_info.host
  user = var.connection_info.user
  private_key = var.connection_info.private_key
  timeout = "15m"
  retry_delay = "5s"
  commands = [
    var.cluster_role == "server" ? "/usr/local/bin/k3s-uninstall.sh" : "/usr/local/bin/k3s-agent-uninstall.sh"
  ]
}
