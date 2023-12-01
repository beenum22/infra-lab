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
    k3s = [
      "echo 'Allowing ports for K3s'",
      "firewall-cmd --permanent --add-port=80/tcp",
      "firewall-cmd --permanent --add-port=443/tcp",
      "firewall-cmd --permanent --add-port=2376/tcp",
      "firewall-cmd --permanent --add-port=2379/tcp",
      "firewall-cmd --permanent --add-port=2380/tcp",
      "firewall-cmd --permanent --add-port=6443/tcp",
      "firewall-cmd --permanent --add-port=8472/udp",
      "firewall-cmd --permanent --add-port=9099/tcp",
      "firewall-cmd --permanent --add-port=10250/tcp",
      "firewall-cmd --permanent --add-port=10254/tcp",
      "firewall-cmd --permanent --add-port=30000-32767/tcp",
      "firewall-cmd --permanent --add-port=30000-32767/udp",
      "firewall-cmd --permanent --zone=trusted --add-source=10.42.0.0/16",
      "firewall-cmd --permanent --zone=trusted --add-source=2001:cafe:42:0::/56",
      "firewall-cmd --permanent --zone=trusted --add-source=10.43.0.0/16",
      "firewall-cmd --permanent --zone=trusted --add-source=2001:cafe:42:1::/112",
      "firewall-cmd --reload"
    ]
    tailscale = [
      "echo 'Allowing ports for Tailscale'",
      "firewall-cmd --permanent --add-port=41641/tcp",
      "firewall-cmd --permanent --add-port=41641/udp",
      "firewall-cmd --permanent --zone=trusted --add-interface=tailscale0",
      "firewall-cmd --reload"
    ]
  }
  uninstall = {
    k3s = [
      "echo 'Removing rules added for K3s'",
      "firewall-cmd --permanent --remove-port=80/tcp",
      "firewall-cmd --permanent --remove-port=443/tcp",
      "firewall-cmd --permanent --remove-port=2376/tcp",
      "firewall-cmd --permanent --remove-port=2379/tcp",
      "firewall-cmd --permanent --remove-port=2380/tcp",
      "firewall-cmd --permanent --remove-port=6443/tcp",
      "firewall-cmd --permanent --remove-port=8472/udp",
      "firewall-cmd --permanent --remove-port=9099/tcp",
      "firewall-cmd --permanent --remove-port=10250/tcp",
      "firewall-cmd --permanent --remove-port=10254/tcp",
      "firewall-cmd --permanent --remove-port=30000-32767/tcp",
      "firewall-cmd --permanent --remove-port=30000-32767/udp",
      "firewall-cmd --permanent --zone=trusted --remove-source=10.42.0.0/16",
      "firewall-cmd --permanent --zone=trusted --remove-source=2001:cafe:42:0::/56",
      "firewall-cmd --permanent --zone=trusted --remove-source=10.43.0.0/16",
      "firewall-cmd --permanent --zone=trusted --remove-source=2001:cafe:42:1::/112",
      "firewall-cmd --reload"
    ]
    tailscale = [
      "echo 'Removing rules added for Tailscale'",
      "firewall-cmd --permanent --remove-port=41641/tcp",
      "firewall-cmd --permanent --remove-port=41641/udp",
      "firewall-cmd --permanent --zone=trusted --remove-interface=tailscale0",
      "firewall-cmd --reload"
    ]
  }
}

resource "null_resource" "install" {
  for_each = toset(var.services)
  triggers = {
     host = var.connection_info.host
     user = var.connection_info.user
     private_key = var.connection_info.private_key
    install_script = join(";", formatlist("${var.use_sudo ? "sudo " : ""}%s", local.install[each.key]))
    uninstall_script = join(";", formatlist("${var.use_sudo ? "sudo " : ""}%s", local.uninstall[each.key]))
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
  provisioner "remote-exec" {
    when = destroy
    on_failure = fail
    inline = [
      self.triggers.uninstall_script
    ]
  }
}

#resource "null_resource" "uninstall" {
#  for_each = toset(var.services)
#  triggers = {
#    host = var.connection_info.host
#    user = var.connection_info.user
#    private_key = var.connection_info.private_key
#    uninstall_script = join(";", local.uninstall[each.key])
##    uninstall_script = join(
##      ";", formatlist(
##        "${var.use_sudo ? "sudo " : ""}%s",
##        concat(local.uninstall[each.key], ["firewall-cmd --reload"])
##      )
##    )
#  }
#  connection {
#    type     = "ssh"
#    user     = self.triggers.user
#    private_key = self.triggers.private_key
#    host     = self.triggers.host
#  }
#  provisioner "remote-exec" {
#    when = destroy
#    on_failure = fail
#    inline = split(";", self.triggers.uninstall_script)
#  }
#}

//data "tailscale_device" "device" {
//  name     = "${var.hostname}.${var.tailnet}"
//  wait_for = "60s"
//  depends_on = [null_resource.install]
//}
//
//resource "tailscale_device_key" "disable_key_expiry" {
//  device_id = data.tailscale_device.device.id
//  key_expiry_disabled = true
//  depends_on = [
//    null_resource.install,
//    data.tailscale_device.device
//  ]
//}
