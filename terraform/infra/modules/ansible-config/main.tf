terraform {
  required_providers {
    ansible = {
      source = "ansible/ansible"
    }
  }
}

resource "ansible_host" "target" {
  name = var.connection_info.host
}

resource "ansible_playbook" "users" {
  for_each = var.users
  playbook   = "${path.module}/playbooks/users.yml"
  name       = ansible_host.target.name
  replayable = var.replay
  ignore_playbook_failure = var.debug
  extra_vars = {
    ansible_user = var.connection_info.user
    ansible_ssh_private_key_file = var.connection_info.private_key_file
    default_state = var.default_state
    user_state = each.value.exists ? "present" : "absent"
    user = each.key
    user_groups = each.value.sudo ? "sudo" : ""  # TODO: Unused. Need to refractor usage
    user_password = each.value.password
    ssh_keys = "\"${join(", ", var.ssh_keys)}\""
  }
}

resource "ansible_playbook" "env" {
  playbook   = "${path.module}/playbooks/env.yml"
  name       = ansible_host.target.name
  replayable = var.replay
  ignore_playbook_failure = var.debug
  extra_vars = {
    ansible_user = var.connection_info.user
    ansible_ssh_private_key_file = var.connection_info.private_key_file
    default_state = var.default_state
    packages =  join(",", var.packages)
    hostname = var.hostname
#    tailscale_auth_key = var.tailscale_config.auth_key
#    tailscale_args = "--accept-dns=true --accept-routes=true --advertise-exit-node=${var.tailscale_config.exit_node}"
#    tailscale_state = var.tailscale_config.upgrade ? "latest" : var.default_state
  }
}

locals {
  k3s = {
    ports = [
      "80/tcp",
      "443/tcp",
      "2376/tcp",
      "2379/tcp",
      "2380/tcp",
      "6443/tcp",
      "6443/tcp",
      "8472/udp",
      "9099/tcp",
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
  replayable = var.replay
  ignore_playbook_failure = var.debug
  extra_vars = {
    ansible_user = var.connection_info.user
    ansible_ssh_private_key_file = var.connection_info.private_key_file
    default_state = var.default_state
    k3s_ports = join(",", local.k3s.ports)
    k3s_sources = join(",", local.k3s.sources)
    tailscale_ports = join(",", local.tailscale.ports)
    tailscale_interface = local.tailscale.interface
  }
}
