terraform {
  required_providers {
    tailscale = {
      source = "tailscale/tailscale"
      version = "0.13.6"
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
  kubectl_cmd = var.use_sudo ? "sudo kubectl" : "kubectl"
}

locals {
  base_cmd = [
    var.cluster_role,
//    "--node-ip=${join(",", values(var.node_ips))}",
//    "--node-ip=100.120.220.57,fd7a:115c:a1e0:ab12:4843:cd96:6278:dc39",
    "--egress-selector-mode=disabled",
    "--flannel-backend=host-gw",
    "--vpn-auth='name=tailscale,joinKey=${var.tailscale_authkey}'",
    "--flannel-iface=${var.flannel_interface}",
    "--flannel-ipv6-masq",
    "--kubelet-arg=node-ip=::",
    "--token=${var.token}",
    "--disable=traefik"
  ]
  init_cmd = var.cluster_init ? concat(local.base_cmd, ["--cluster-init", "--disable=servicelb"]) : concat(local.base_cmd, ["--server=https://${var.api_host}:6443"])
  final_cmd = var.cluster_role == "server" ? concat(local.init_cmd, ["--cluster-cidr=${var.cluster_cidrs}", "--service-cidr=${var.service_cidrs}"]) : local.init_cmd
}

//resource "null_resource" "drain" {
//  depends_on = [null_resource.node]
//  triggers = {
//    name = var.name
//    hostname = var.hostname
//    host = var.connection_info.host
//    user = var.connection_info.user
//    private_key = var.connection_info.private_key
//  }
//  connection {
//    type     = "ssh"
//    user     = self.triggers.user
//    private_key = self.triggers.private_key
//    host     = self.triggers.host
//  }
//  provisioner "local-exec" {
//    when = destroy
//    command = <<EOD
//if [ -f ${pathexpand("~/.kube/config")} ]; then
//  if [ $(kubectl get nodes -o name | wc -l) -ne 1 ]; then
//    kubectl drain ${self.triggers.hostname} --delete-emptydir-data --ignore-daemonsets --force --timeout=360s
//  fi
//else
//echo "No kubeconfig exists. Skipping."
//fi
//EOD
//  }
//}
//
//resource "null_resource" "delete" {
//  triggers = {
//    name = var.name
//    hostname = var.hostname
//    host = var.connection_info.host
//    user = var.connection_info.user
//    private_key = var.connection_info.private_key
//  }
//  connection {
//    type     = "ssh"
//    user     = self.triggers.user
//    private_key = self.triggers.private_key
//    host     = self.triggers.host
//  }
//  provisioner "local-exec" {
//    when = destroy
//    command = <<EOD
//if [ -f ${pathexpand("~/.kube/config")} ]; then
//  if [ $(kubectl get nodes -o name | wc -l) -ne 1 ]; then
//    kubectl delete node ${self.triggers.hostname}
//  fi
//else
//  echo "No kubeconfig exists. Skipping."
//fi
//EOD
//  }
//}

resource "null_resource" "install" {
  depends_on = [
//    null_resource.delete
  ]
  triggers = {
    name = var.name
    hostname = var.hostname
    host = var.connection_info.host
    user = var.connection_info.user
    private_key = var.connection_info.private_key
    cmd = join(" ", local.final_cmd)
  }
  connection {
    type     = "ssh"
    user     = self.triggers.user
    private_key = self.triggers.private_key
    host     = self.triggers.host
  }
  provisioner "file" {
    content     = data.http.installer.response_body
    destination = "/tmp/k3s-installer"
  }
  provisioner "remote-exec" {
    on_failure = fail
    inline = [
      "INSTALL_K3S_VERSION=${local.k3s_version} sh /tmp/k3s-installer ${join(" ", local.final_cmd)}",
    ]
  }
  provisioner "remote-exec" {
    when = destroy
    on_failure = continue
    inline = [
      "/usr/local/bin/k3s-uninstall.sh"
    ]
  }
}

//resource "null_resource" "uninstall" {
//  depends_on = [
//    null_resource.install
//  ]
//  triggers = {
//    name = var.name
//    hostname = var.hostname
//    host = var.connection_info.host
//    user = var.connection_info.user
//    private_key = var.connection_info.private_key
//    cmd = join(" ", local.final_cmd)
//  }
//  connection {
//    type     = "ssh"
//    user     = self.triggers.user
//    private_key = self.triggers.private_key
//    host     = self.triggers.host
//  }
//  provisioner "remote-exec" {
//    when = destroy
//    on_failure = continue
//    inline = [
//      "/usr/local/bin/k3s-uninstall.sh"
//    ]
//  }
//}

data "tailscale_device" "device" {
  name     = "${var.hostname}.${var.tailnet}"
  wait_for = "60s"
  depends_on = [null_resource.install]
}

resource "tailscale_device_key" "disable_key_expiry" {
  device_id = data.tailscale_device.device.id
  key_expiry_disabled = true
  depends_on = [
    null_resource.install,
    data.tailscale_device.device
  ]
}

resource "null_resource" "check_status" {
  depends_on = [
    null_resource.install
  ]
  triggers = {
//    name = var.name
    hostname = var.hostname
    host = var.connection_info.host
    user = var.connection_info.user
    private_key = var.connection_info.private_key
  }
  connection {
    type     = "ssh"
    user     = self.triggers.user
    private_key = self.triggers.private_key
    host     = self.triggers.host
  }
  provisioner "remote-exec" {
    inline = [
      "${ var.use_sudo ? "sudo " : "" }cp /etc/rancher/k3s/k3s.yaml /tmp/config_temp",
      "${ var.use_sudo ? "sudo " : "" }chown $USER:$USER /tmp/config_temp",
//      "sed -i 's/127.0.0.1/${self.triggers.api_host}/g' /tmp/config_temp",
      "until kubectl --kubeconfig /tmp/config_temp get node ${self.triggers.hostname}; do sleep 1; done",
      "rm /tmp/config_temp"
    ]
  }
//  provisioner "local-exec" {
//    command = "scp -i ~/.ssh/id_rsa ${self.triggers.user}@${self.triggers.host}:/tmp/config_temp ~/.kube/config"
//  }
//  provisioner "remote-exec" {
//    inline = [
//      "rm /tmp/config_temp"
//    ]
//  }
//  provisioner "local-exec" {
//    command = "until kubectl get node ${self.triggers.hostname}; do sleep 1; done"
//  }
}

resource "null_resource" "copy_kubeconfig" {
  count = var.copy_kubeconfig ? 1 : 0
  triggers = {
    name = var.name
    api_host = var.hostname
    host = var.connection_info.host
    user = var.connection_info.user
    private_key = var.connection_info.private_key
  }
  connection {
    type     = "ssh"
    user     = self.triggers.user
    private_key = self.triggers.private_key
    host     = self.triggers.host
  }
  provisioner "remote-exec" {
    inline = [
      "sudo cp /etc/rancher/k3s/k3s.yaml /tmp/config",
      "sudo chown $USER:$USER /tmp/config",
      "sed -i 's/127.0.0.1/${self.triggers.api_host}/g' /tmp/config"
    ]
  }
  provisioner "local-exec" {
    command = var.use_ipv6 ? "scp -i ~/.ssh/id_rsa ${self.triggers.user}@[${self.triggers.host}]:/tmp/config ~/.kube/config" : "scp -i ~/.ssh/id_rsa ${self.triggers.user}@${self.triggers.host}:/tmp/config ~/.kube/config"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo cp /var/lib/rancher/k3s/server/token /tmp/node-token",
      "sudo chown $USER:$USER /tmp/node-token"
    ]
  }
  provisioner "local-exec" {
    command = var.use_ipv6 ? "scp -i ~/.ssh/id_rsa ${self.triggers.user}@[${self.triggers.host}]:/tmp/node-token ~/.kube/node-token" : "scp -i ~/.ssh/id_rsa ${self.triggers.user}@${self.triggers.host}:/tmp/node-token ~/.kube/node-token"
  }
  provisioner "remote-exec" {
    inline = [
      "rm /tmp/node-token",
      "rm /tmp/config"
    ]
  }
  depends_on = [
    null_resource.install
  ]
}

resource "null_resource" "node_labels" {
  for_each = var.node_labels
  triggers = {
    hostname = var.hostname
  }
  provisioner "local-exec" {
    command = "kubectl label nodes ${self.triggers.hostname} ${each.key}=${each.value}"
  }
  depends_on = [
    null_resource.install,
  ]
}
