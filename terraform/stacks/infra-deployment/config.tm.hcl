globals "terraform" {
  providers = [
    "oci"
  ]
}

globals "infrastructure" "oci" {}

globals "infrastructure" "instances" {}

globals "infrastructure" "config" {
  ssh_keys = []
}

generate_hcl "_oci.tf" {
  content {
    locals {
      oci_nodes = {
        for node, info in local.nodes : node => info if info.provider == "oracle"
      }
    }

    module "oci_vcn" {
      source         = "${terramate.root.path.fs.absolute}/terraform/modules/infra/oci-vcn"
      compartment_id = global.infrastructure.oci.compartment_id
      name           = tm_replace(global.project.name, "-", "")
      enable_ssh     = true
      enable_ipv4_nat_egress = false
      ssh_ports      = [22, 2203]
    }

    module "oci_instances" {
      source        = "${terramate.root.path.fs.absolute}/terraform/modules/infra/oci-instance"
      for_each      = local.oci_nodes
      name          = each.key
      shape_name    = each.value.provider_config.shape_name
      image_ocid    = each.value.provider_config.image_ocid
      vcpus         = each.value.provider_config.vcpus
      memory        = each.value.provider_config.memory
      boot_volume   = each.value.provider_config.boot_volume
      block_volumes = each.value.provider_config.block_volumes
      subnets       = [
        {
          id            = module.oci_vcn.public_subnet_id
          public_access = true
        }
      ]
      ssh_public_keys = concat(try([trimspace(tls_private_key.this.public_key_openssh)], []), global.infrastructure.config.ssh_keys)
      cloud_init_commands = [
        for cmd in local.ssh_port_config : replace(cmd, "SSH_PORT", each.value.port)
      ]
    }
  }
}

# generate_hcl "_hetzner.tf" {
#   content {
#     locals {
#       hetzner_nodes = {
#         for node, info in local.nodes : node => info if info.provider == "hetzner"
#       }
#     }
#
#     resource "hcloud_ssh_key" "this" {
#       name       = "Terraform Key"
#       public_key = trimspace(tls_private_key.this.public_key_openssh)
#     }
#
#     resource "hcloud_network" "this" {
#       name     = "lab"
#       ip_range = "10.0.0.0/16"
#     }
#
#     resource "hcloud_network_subnet" "this" {
#       type         = "cloud"
#       network_id   = hcloud_network.this.id
#       network_zone = "eu-central"
#       ip_range     = "10.0.0.0/24"
#     }
#
#     moved {
#       from = module.hetzner_instances["hzn-neu-0"]
#       to = module.hetzner_instances["hzn-hel-0"]
#     }
#
#     module "hetzner_instances" {
#       source        = "${terramate.root.path.fs.absolute}/terraform/modules/infra/hetzner-instance"
#       for_each      = local.hetzner_nodes
#       name          = each.key
#       server_type   = each.value.provider_config.server_type
#       image         = each.value.provider_config.image
#       datacenter    = each.value.provider_config.datacenter
#       block_volumes = each.value.provider_config.block_volumes
#       enable_ipv4   = true
#       enable_ipv6   = true
#       subnets       = [
#         hcloud_network.this.id
#       ]
#       ssh_public_keys = [hcloud_ssh_key.this.id]
# #       ssh_public_keys     = concat(try([
# #         trimspace(tls_private_key.this.public_key_openssh)
# #       ], []), global.infrastructure.config.ssh_keys)
#       cloud_init_commands = [
#         for cmd in local.ssh_port_config : replace(cmd, "SSH_PORT", each.value.port)
#       ]
#     }
#
#     moved {
#       from = hcloud_server.this["hzn-neu-k3s-0"]
#       to = module.hetzner_instances["hzn-neu-0"].hcloud_server.this
#     }
#
#     moved {
#       from = hcloud_volume.this["hzn-neu-k3s-0"]
#       to = module.hetzner_instances["hzn-neu-0"].hcloud_volume.this["20"]
#     }
#   }
# }
