terraform {
  required_providers {
    ansible = {
      source = "NefixEstrada/ansible"
    }
  }
}

resource "random_password" "users" {
  for_each = var.users
  length           = 16
  special          = true
}

locals {
  users_with_password = {
    for user, info in var.users : user => merge(info, { password = try(random_password.users[user].bcrypt_hash, null) })
  }
  merged_ssh_keys = concat(var.ssh_keys, [var.default_ssh_key])
}

resource "ansible_host" "target" {
  name = var.connection_info.host
}

resource "ansible_playbook" "users" {
  for_each = local.users_with_password
  playbook   = "${path.module}/playbooks/users.yml"
  timeout = 300
  name       = ansible_host.target.name
  replayable = var.replay
  ignore_playbook_failure = var.debug
  extra_vars = jsonencode({
    ansible_user = var.connection_info.user
    ansible_ssh_private_key_file = var.connection_info.private_key_file
    ansible_port = var.connection_info.port
    user_state = "present"
    user = each.key
    user_password = each.value.password
    ssh_keys = join(", ", local.merged_ssh_keys)
  })
}

resource "ansible_playbook" "env" {
  playbook   = "${path.module}/playbooks/env.yml"
  name       = ansible_host.target.name
  timeout    = 300
  replayable = var.replay
  ignore_playbook_failure = var.debug
  extra_vars = jsonencode({
    ansible_user = var.connection_info.user
    ansible_ssh_private_key_file = var.connection_info.private_key_file
    ansible_port = var.connection_info.port
    packages =  join(",", var.packages)
    hostname = var.hostname
  })
}

locals {
  ssh = {
    ports = ["${var.connection_info.port}/tcp"]
  }
  k3s = {
    ports = [
      "80/tcp",
      "443/tcp",
      "2376/tcp",
      "2379/tcp",
      "2380/tcp",
      "4421/tcp",
      "4421/udp",
      "6443/tcp",
      "6443/tcp",
      "8420/tcp",
      "8420/udp",
      "8472/udp",
      "9099/tcp",
      "10124/udp",
      "10124/tcp",
      "10250/tcp",
      "10254/tcp",
      "30000-32767/tcp",
      "30000-32767/udp",
    ]
    sources = [
      "10.42.0.0/16",
      "2001:cafe:42:0::/56",
      "10.43.0.0/16",
      "2001:cafe:42:1::/112",
    ]
  }
  tailscale = {
    ports = [
      "41641/tcp",
      "41641/udp",
    ]
    interface = "tailscale0"
    sources = []
  }
}

resource "ansible_playbook" "firewall" {
  playbook   = "${path.module}/playbooks/firewall.yml"
  name       = ansible_host.target.name
  timeout    = 300
  replayable = var.replay
  ignore_playbook_failure = var.debug
  extra_vars = jsonencode({
    ansible_user = var.connection_info.user
    ansible_ssh_private_key_file = var.connection_info.private_key_file
    ansible_port = var.connection_info.port
    k3s_ports = join(",", local.k3s.ports)
    k3s_sources = join(",", local.k3s.sources)
    tailscale_ports = join(",", local.tailscale.ports)
    tailscale_interface = local.tailscale.interface
  })
  depends_on = [ansible_playbook.env]
}

resource "ansible_playbook" "zfs" {
  count = var.zfs_config.enable ? 1 : 0
  playbook   = "${path.module}/playbooks/zfs.yml"
  name       = ansible_host.target.name
  replayable = var.replay
  timeout    = 100
  ignore_playbook_failure = var.debug
  extra_vars = jsonencode({
    ansible_user = var.connection_info.user
    ansible_ssh_private_key_file = var.connection_info.private_key_file
    ansible_port = var.connection_info.port
    zfs_loopback_pool = length(var.zfs_config.loopback) > 0 ? true : false
    zfs_loopback_config = var.zfs_config.loopback
    zfs_devices_config = var.zfs_config.devices
  })
  depends_on = [ansible_playbook.env]
}
