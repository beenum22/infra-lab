terraform {
  required_providers {
    tailscale = {
      source = "tailscale/tailscale"
      version = "0.13.6"
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
  url = "https://raw.githubusercontent.com/rancher/k3s/${jsondecode(data.http.version.response_body).data[1].latest}/install.sh"
}

locals {
  // Use the fetched version if 'lastest' is specified
  k3s_version = var.k3s_version == "latest" ? jsondecode(data.http.version.response_body).data[1].latest : var.k3s_version
}

locals {
  base_cmd = [
    var.cluster_role,
    "--egress-selector-mode=disabled",
    "--flannel-backend=host-gw",
#    "--vpn-auth='name=tailscale,joinKey=${var.tailscale_authkey}'",
    "--flannel-iface=${var.flannel_interface}",
    "--flannel-ipv6-masq",
    "--kubelet-arg=node-ip=::",
    "--token=${var.token}",
    "--disable=traefik"
  ]
  init_cmd = var.cluster_init ? concat(local.base_cmd, ["--cluster-init", "--disable=servicelb"]) : concat(local.base_cmd, ["--server=https://${var.api_host}:6443"])
  final_cmd = var.cluster_role == "server" ? concat(local.init_cmd, ["--cluster-cidr=${var.cluster_cidrs}", "--service-cidr=${var.service_cidrs}"]) : local.init_cmd
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
    "${ var.use_sudo ? "sudo " : "" }chown ${var.connection_info.user}:$USER /etc/rancher/k3s/k3s.yaml"
  ]
  commands = [
    "until kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml get node ${var.hostname}; do sleep 1; done"
  ]
  depends_on = [
    ssh_resource.install
  ]
}

resource "ssh_resource" "node_token" {
  count = var.cluster_init ? 1 : 0
  host = var.connection_info.host
  user = var.connection_info.user
  when = "create"
  private_key = var.connection_info.private_key
  timeout = "1m"
  retry_delay = "5s"
  commands = [
    "${ var.use_sudo ? "sudo " : "" }cat /var/lib/rancher/k3s/server/token"
  ]
  depends_on = [
    ssh_resource.check_status
  ]
}

resource "ssh_resource" "copy_kubeconfig" {
  count = var.copy_kubeconfig ? 1 : 0
  host = var.connection_info.host
  user = var.connection_info.user
  when = "create"
  private_key = var.connection_info.private_key
  timeout = "1m"
  retry_delay = "5s"
  commands = [
    "${ var.use_sudo ? "sudo " : "" }cat /etc/rancher/k3s/k3s.yaml"
  ]
  depends_on = [
    ssh_resource.check_status
  ]
}

resource "local_file" "copy_kubeconfig" {
  count = var.copy_kubeconfig ? 1 : 0
  content  = replace(trimspace(ssh_resource.copy_kubeconfig[0].result), "127.0.0.1", var.api_host)
  filename = "${pathexpand("~")}/.kube/config"
  file_permission = "0700"
}

resource "ssh_resource" "node_cidrs" {
  host = var.connection_info.host
  user = var.connection_info.user
  when = "create"
  private_key = var.connection_info.private_key
  timeout = "5m"
  retry_delay = "5s"
  commands = [
    "kubectl get nodes ${var.hostname} -o json | jq -r '.spec.podCIDRs | join(\",\")'"
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
  timeout = "5m"
  retry_delay = "5s"
  commands = [
    "kubectl label nodes ${var.hostname} ${each.key}=${each.value}"
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
  timeout = "5m"
  retry_delay = "5s"
  commands = [
    "${ var.use_sudo ? "sudo " : "" }tailscale set --advertise-routes=${trimspace(ssh_resource.node_cidrs.result)}"
  ]
  depends_on = [
    ssh_resource.install
  ]
}

resource "ssh_resource" "remove_node_labels" {
  for_each = var.cluster_init ? {} : var.node_labels
  host = var.connection_info.host
  user = var.connection_info.user
  when = "destroy"
  private_key = var.connection_info.private_key
  timeout = "1m"
  retry_delay = "5s"
  commands = [
    "kubectl --request-timeout 15s label --overwrite nodes ${var.hostname} ${each.key}-"
  ]
  depends_on = [
    ssh_resource.uninstall,
    ssh_resource.drain_node,
    local_file.copy_kubeconfig[0]
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
  depends_on = [
    ssh_resource.drain_node,
    ssh_resource.uninstall,
  ]
}

resource "ssh_resource" "drain_node" {
  count = var.cluster_init ? 0 : 1
  host = var.connection_info.host
  user = var.connection_info.user
  when = "destroy"
  private_key = var.connection_info.private_key
  timeout = "5m"
  retry_delay = "5s"
  commands = [
    "kubectl --request-timeout 15s drain --ignore-daemonsets --delete-emptydir-data ${var.hostname}"
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
    "/usr/local/bin/k3s-uninstall.sh"
  ]
}
