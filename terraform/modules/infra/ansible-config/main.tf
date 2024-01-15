terraform {
  required_providers {
    ansible = {
      source = "NefixEstrada/ansible"
    }
  }
}

locals {
  users = {
    muneeb = {
      sudo = true
      exists = true
      password = null
    }
    k3s = {
      sudo = true
      exists = true
      password = null
    }
  }
  ssh_keys = [
    trimspace("ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC9iQnzPq0/lLg359hzQiVSnf33PAzCYaFu8gW1OIaftA2+/fUtJoPCoMBNB4TDTA5ZnHfKEmR9/ktFr4AWOQ/4oCQP2uC12zci9Lpep/aYMmXmgAGs+35sZvf1Ob44CuEw/vvwfViYNt8HAc0BTo1+Sj5gKp8QuBVY70ezS0yw+VEvHnxbXDbXxVRId1w7gANwBAhyRviKjFWSULPJsPY+t0HNoFozERnBDaov3wL7TPIy2WIHr6BE/lOwlzoqRMd8qtAIEbrDTNfZwmY+2AYvhjicLQ6H5jCfHW6UFptlV4UN9UijdVZ+thF4vM8i6huHUx87ljsyOtqwLqrwfh9t muneebahmad@beenum.local")
  ]
  packages = [
    "jq",
    "net-tools",
    "firewalld",
    "curl"
  ]
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
    user_state = "present"
    user = each.key
    user_groups = each.value.sudo ? "sudo" : ""  # TODO: Unused. Need to refractor usage
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
    packages =  join(",", var.packages)
    hostname = var.hostname
#    tailscale_auth_key = var.tailscale_config.auth_key
#    tailscale_args = "--accept-dns=true --accept-routes=true --advertise-exit-node=${var.tailscale_config.exit_node}"
#    tailscale_state = var.tailscale_config.upgrade ? "latest" : var.default_state
  })
}

locals {
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
    k3s_ports = join(",", local.k3s.ports)
    k3s_sources = join(",", local.k3s.sources)
    tailscale_ports = join(",", local.tailscale.ports)
    tailscale_interface = local.tailscale.interface
  })
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
    zfs_loopback_pool = length(var.zfs_config.loopback) > 0 ? true : false
#    zfs_loopback_pool_size = var.zfs_config.loopback.size
    zfs_loopback_config = var.zfs_config.loopback
    zfs_devices_config = var.zfs_config.devices
  })
}