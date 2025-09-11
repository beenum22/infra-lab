generate_hcl "_oci_talos_vms.tf" {
  content {
    data "oci_identity_availability_domains" "this" {
      compartment_id = global.infrastructure.oci.compartment_id
    }

    resource "oci_core_instance" "this" {
      for_each = local.oci_talos_nodes
      display_name = each.key
      availability_domain = data.oci_identity_availability_domains.this.availability_domains.0.name
      compartment_id      = global.infrastructure.oci.compartment_id
      shape               = each.value.provider_config.shape_name

      create_vnic_details {
        subnet_id = module.oci_vcn.public_subnet_id
        assign_public_ip = true
        assign_ipv6ip = true
        # use_ipv6 = true
      }
      metadata = {
        ssh_authorized_keys = null
        user_data           = base64encode(data.talos_machine_configuration.this[each.key].machine_configuration)
      }
      source_details {
        source_type = "image"
        source_id   = oci_core_image.this["talos-oci-arm64-${each.value.talos_config.version}"].id
        boot_volume_size_in_gbs = each.value.provider_config.boot_volume
      }
      shape_config {
        memory_in_gbs = each.value.provider_config.memory
        ocpus = each.value.provider_config.vcpus
      }
    }

    resource "oci_core_volume" "this" {
      for_each = { for item in flatten([
        for node, info in local.oci_talos_nodes : [
          for index, vol in info.provider_config.block_volumes : {
            node   = node
            name   = "${node}-volume-${index}"
            volume = vol
          }
        ]
      ]) : "${item.name}" => item }
      availability_domain = data.oci_identity_availability_domains.this.availability_domains.0.name
      compartment_id      = global.infrastructure.oci.compartment_id
      display_name        = each.value.name
      size_in_gbs         = each.value.volume
    }

    resource "oci_core_volume_attachment" "this" {
      for_each = { for item in flatten([
        for node, info in local.oci_talos_nodes : [
          for index, vol in info.provider_config.block_volumes : {
            node   = node
            name   = "${node}-volume-${index}"
            volume = vol
          }
        ]
      ]) : "${item.name}" => item }
      attachment_type = "paravirtualized"
      instance_id     = oci_core_instance.this[each.value.node].id
      volume_id       = oci_core_volume.this[each.key].id
      use_chap        = false
    }

    resource "cloudflare_dns_record" "cluster" {
      for_each = local.talos_nodes
      zone_id  = global.infrastructure.cloudflare.zone_id
      name     = global.infrastructure.talos.cluster_endpoint
      content  = each.value.provider == "oracle" ? oci_core_instance.this[each.key].public_ip : each.value.provider_config.address
      comment  = "Talos Cluster Endpoint"
      type     = "A"
      proxied  = false
      ttl      = "60"
    }

    resource "cloudflare_dns_record" "nodes" {
      for_each = local.talos_nodes
      zone_id  = global.infrastructure.cloudflare.zone_id
      name     = global.infrastructure.talos_instances[each.key].hostname
      content  = each.value.provider == "oracle" ? oci_core_instance.this[each.key].public_ip : each.value.provider_config.address
      comment  = "Talos Cluster Node"
      type     = "A"
      proxied  = false
      ttl      = "60"
    }
  }
}