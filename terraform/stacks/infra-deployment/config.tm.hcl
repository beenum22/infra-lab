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

generate_hcl "_terramate-oci-vcn.tf" {
  content {
    module "oci_vcn" {
      source         = "${terramate.root.path.fs.absolute}/terraform/modules/infra/oci-vcn"
      compartment_id = global.infrastructure.oci.compartment_id
      name           = tm_replace(global.project.name, "-", "")
      enable_ssh     = true
    }
  }
}

generate_hcl "_terramate-oci-instance.tf" {
  content {
    locals {
      nodes = global.infrastructure.instances
      oci_nodes = {
        for node, info in local.nodes : node => info if info.provider == "oracle"
      }
    }

    module "oci_instances" {
      source        = "${terramate.root.path.fs.absolute}/terraform/modules/infra/oci-instance"
      for_each = local.oci_nodes
      name          = each.key
      shape_name    = each.value.provider_config.shape_name
      image_ocid    = each.value.provider_config.image_ocid
      vcpus         = each.value.provider_config.vcpus
      memory        = each.value.provider_config.memory
      boot_volume   = each.value.provider_config.boot_volume
      block_volumes = each.value.provider_config.block_volumes
      subnets = [
        {
          id            = module.oci_vcn.public_subnet_id
          public_access = false
        }
      ]
      ssh_public_keys = concat(try([trimspace(tls_private_key.this.public_key_openssh)], []), global.infrastructure.config.ssh_keys)
    }

    output "node_ips" {
      value = {
        for node, info in local.nodes : node => {
          ipv4 = try(info.host.ipv4, module.oci_instances[node].primary_ipv4_address)
          ipv6 = try(info.host.ipv6, module.oci_instances[node].primary_ipv6_address)
        }
      }
    }
  }
}
