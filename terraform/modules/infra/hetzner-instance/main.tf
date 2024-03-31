terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
    template = {
      source = "hashicorp/template"
    }
  }
}

data "template_file" "cloud_config" {
  template = <<YAML
#cloud-config
runcmd:
  - echo 'This instance was provisioned by Terraform.' >> /etc/motd
  - sleep 10
  %{ for cmd in var.cloud_init_commands }
  - ${cmd}
  %{ endfor ~}
YAML
}

resource "hcloud_server" "this" {
  name        = var.name
  image       = var.image
  server_type = var.server_type
  dynamic "network" {
    for_each = var.subnets
    content {
      network_id = network.value
      alias_ips  = []
    }
  }
  public_net {
    ipv4_enabled = var.enable_ipv4
    ipv6_enabled = var.enable_ipv6
  }
  ssh_keys = var.ssh_public_keys
  user_data = base64encode(data.template_file.cloud_config.rendered)
}

resource "hcloud_volume" "this" {
  for_each = toset(var.block_volumes)
  name      = "${var.name}-${each.key}"
  size      = each.value
  server_id = hcloud_server.this.id
  automount = false
  format    = "ext4"
}
