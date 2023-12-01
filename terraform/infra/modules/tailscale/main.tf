terraform {
  required_providers {
    tailscale = {
      source = "tailscale/tailscale"
      version = "0.13.6"
    }
  }
}

locals {
  install = {
    oracle = join(";", [
      "curl -fsSL https://tailscale.com/install.sh | sh && sudo dnf install tailscale-${var.tailscale_version} -y",
      "if [ ! $(cat /etc/default/tailscaled  | grep MTU) ]; then echo 'TS_DEBUG_MTU=${var.tailscale_mtu}' | ${var.use_sudo ? "sudo " : ""}tee -a /etc/default/tailscaled; fi",
      "${var.use_sudo ? "sudo " : ""}systemctl restart tailscaled",
      "${var.use_sudo ? "sudo " : ""}tailscale up --auth-key=${var.authkey} --accept-dns=true --accept-routes=true"
    ])
  }
  upgrade = {
    oracle = "curl -fsSL https://tailscale.com/install.sh | sh"
  }
  uninstall = {
    oracle = join(";", [
      "${var.use_sudo ? "sudo " : ""}tailscale down",
      "${var.use_sudo ? "sudo " : ""}dnf remove tailscale -y"
    ])
  }
}

resource "null_resource" "install" {
//  depends_on = [null_resource.node]
  triggers = {
    host = var.connection_info.host
    user = var.connection_info.user
    private_key = var.connection_info.private_key
    install_script = local.install.oracle
    uninstall_script = local.uninstall.oracle
    mtu = var.tailscale_mtu
    authkey = var.authkey
  }
  connection {
    type     = "ssh"
    user     = self.triggers.user
    private_key = self.triggers.private_key
    host     = self.triggers.host
  }
  provisioner "remote-exec" {
    on_failure = fail
    inline = [
      self.triggers.install_script
    ]
  }
  # provisioner "remote-exec" {
  #   on_failure = fail
  #   inline = [
  #     "sudo tailscale up --auth-key=${var.authkey} --accept-dns=true",
  #   ]
  # }
  provisioner "remote-exec" {
    when = destroy
    on_failure = fail
    inline = [
//      "sudo tailscale down",
      self.triggers.uninstall_script
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

#resource "null_resource" "advertise" {
#  depends_on = [null_resource.install]
#  triggers = {
#    host = var.connection_info.host
#    user = var.connection_info.user
#    private_key = var.connection_info.private_key
#    routes = join(",", var.routes)
#    cmd = "${var.use_sudo ? "sudo " : ""}tailscale set"
#  }
#  connection {
#    type     = "ssh"
#    user     = self.triggers.user
#    private_key = self.triggers.private_key
#    host     = self.triggers.host
#  }
#  provisioner "remote-exec" {
#    on_failure = fail
#    inline = [
#      "${self.triggers.cmd} --advertise-routes=${self.triggers.routes}"
#    ]
#  }
#  provisioner "remote-exec" {
#    on_failure = fail
#    inline = [
#      "${self.triggers.cmd} --accept-routes=true"
#    ]
#  }
#  provisioner "remote-exec" {
#    when = destroy
#    on_failure = fail
#    inline = [
#      "${self.triggers.cmd} --advertise-routes="
#    ]
#  }
#}

//
//resource "tailscale_device_key" "disable_key_expiry" {
//  device_id = data.tailscale_device.device.id
//  key_expiry_disabled = true
//  depends_on = [
//    null_resource.install,
//    data.tailscale_device.device
//  ]
//}


# data "tailscale_device" "device" {
#   name     = "${var.hostname}.${var.tailnet}"
#   wait_for = "60s"
#   depends_on = [null_resource.install]
# }

# resource "tailscale_device_key" "disable_key_expiry" {
#   device_id = data.tailscale_device.device.id
#   key_expiry_disabled = true
#   depends_on = [
#     null_resource.install,
#     data.tailscale_device.device
#   ]
# }