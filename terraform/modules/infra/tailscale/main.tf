terraform {
  required_providers {
    tailscale = {
      source = "tailscale/tailscale"
    }
  }
}

# TODO: --accept-routes=true is not working. Probably because the condition you have set to check the state file is not working.
locals {
  install = {
    oracle = join(";", [
      "curl -fsSL https://tailscale.com/install.sh | sh",
      "if [ -f /etc/debian_version ]; then ${var.use_sudo ? "sudo " : ""}apt-get update && ${var.use_sudo ? "sudo " : ""} apt-get install -y --allow-downgrades tailscale=${var.tailscale_version}; elif [ -f /etc/redhat-release ]; then ${var.use_sudo ? "sudo " : ""}dnf install -y tailscale-${var.tailscale_version}; else echo \"Unsupported operating system\" && exit 1; fi",
      "if [ ! $(cat /etc/default/tailscaled  | grep MTU) ]; then echo 'TS_DEBUG_MTU=${var.tailscale_mtu}' | ${var.use_sudo ? "sudo " : ""}tee -a /etc/default/tailscaled; fi",
      "${var.use_sudo ? "sudo " : ""}systemctl restart tailscaled",
      "if ! ${var.use_sudo ? "sudo " : ""}grep -q '{}' /var/lib/tailscale/tailscaled.state; then ${var.use_sudo ? "sudo " : ""}tailscale up; else ${var.use_sudo ? "sudo " : ""}tailscale up --auth-key=${nonsensitive(tailscale_tailnet_key.node_key.key)}; fi"
#      "if ${var.use_sudo ? "sudo " : ""}test -f '/var/lib/tailscale/tailscaled.state'; then ${var.use_sudo ? "sudo " : ""}tailscale up; else ${var.use_sudo ? "sudo " : ""}tailscale up --auth-key=${nonsensitive(tailscale_tailnet_key.node_key.key)}; fi"
    ])
  }
  upgrade = {
    oracle = "curl -fsSL https://tailscale.com/install.sh | sh"
  }
  set_config_flags = join(";", concat([
    "${var.use_sudo ? "sudo " : ""}tailscale set --advertise-exit-node=${var.exit_node}",
    "${var.use_sudo ? "sudo " : ""}tailscale set --accept-dns=true",
    "${var.use_sudo ? "sudo " : ""}tailscale set --accept-routes=true",
  ], [
    for flag in var.set_flags : "${var.use_sudo ? "sudo " : ""}tailscale set ${flag}"
  ]))
  uninstall = {
    oracle = join(";", [
      "${var.use_sudo ? "sudo " : ""}tailscale down",
      "if [ -f /etc/debian_version ]; then ${var.use_sudo ? "sudo " : ""} apt-get remove -y tailscale; elif [ -f /etc/redhat-release ]; then ${var.use_sudo ? "sudo " : ""}dnf remove -y tailscale; else echo \"Unsupported operating system\" && exit 1; fi",
      "${var.use_sudo ? "sudo " : ""} rm -rf /var/lib/tailscale"
    ])
  }
}

resource "tailscale_tailnet_key" "node_key" {
  reusable      = true
  ephemeral     = false
  preauthorized = true
  expiry        = 3600
  description   = "${var.hostname} node key generated using Terraform"
  tags          = ["tag:k3s"]
}

resource "null_resource" "install" {
  triggers = {
    host = var.connection_info.host
    user = var.connection_info.user
    port = var.connection_info.port
    private_key = var.connection_info.private_key
    install_script = local.install.oracle
    mtu = var.tailscale_mtu
    authkey = nonsensitive(tailscale_tailnet_key.node_key.key)
  }
  connection {
    type     = "ssh"
    user     = self.triggers.user
    private_key = self.triggers.private_key
    host     = self.triggers.host
    port     = self.triggers.port
  }
  provisioner "remote-exec" {
    on_failure = fail
    inline = [
      self.triggers.install_script
    ]
  }
}

resource "null_resource" "uninstall" {
  triggers = {
    host = var.connection_info.host
    user = var.connection_info.user
    port = var.connection_info.port
    private_key = var.connection_info.private_key
    uninstall_script = local.uninstall.oracle
  }
  connection {
    type     = "ssh"
    user     = self.triggers.user
    private_key = self.triggers.private_key
    host     = self.triggers.host
    port     = self.triggers.port
  }
  provisioner "remote-exec" {
    when = destroy
    on_failure = fail
    inline = [
      self.triggers.uninstall_script
    ]
  }
}

resource "null_resource" "config" {
  depends_on = [null_resource.install]
  triggers = {
    host = var.connection_info.host
    user = var.connection_info.user
    port = var.connection_info.port
    private_key = var.connection_info.private_key
    config_flags = local.set_config_flags
  }
  connection {
    type     = "ssh"
    user     = self.triggers.user
    private_key = self.triggers.private_key
    host     = self.triggers.host
    port     = self.triggers.port
  }
  provisioner "remote-exec" {
    on_failure = fail
    inline = [
      self.triggers.config_flags
    ]
  }
}

data "tailscale_device" "device" {
  name     = "${var.hostname}.${var.tailnet}"
  wait_for = "60s"
  depends_on = [null_resource.install]
}

resource "tailscale_device_key" "disable_key_expiry" {
  device_id = data.tailscale_device.device.id
  key_expiry_disabled = true
  depends_on = [
    data.tailscale_device.device
  ]
}
