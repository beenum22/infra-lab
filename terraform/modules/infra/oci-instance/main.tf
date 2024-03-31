terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
      version = "4.111.0"
    }
    template = {
      source = "hashicorp/template"
      version = "2.2.0"
    }
    time = {
      source = "hashicorp/time"
      version = "0.9.1"
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

module "instance" {
  source = "oracle-terraform-modules/compute-instance/oci"
  instance_count             = 1
  ad_number                  = null
  compartment_ocid           = var.compartment_id
  instance_display_name      = var.name
  source_ocid                = var.image_ocid
  subnet_ocids               = [var.subnets[0]["id"]]
  public_ip                  = var.subnets[0].public_access ? "EPHEMERAL" : "NONE" # NONE, RESERVED or EPHEMERAL
  ssh_public_keys            = join("\n", var.ssh_public_keys)
  instance_flex_ocpus        = length(regexall("Flex", var.shape_name)) > 0 ? var.vcpus : null
  instance_flex_memory_in_gbs = length(regexall("Flex", var.shape_name)) > 0 ? var.memory : null
  boot_volume_size_in_gbs    = var.boot_volume
  block_storage_sizes_in_gbs = var.block_volumes
  shape                      = var.shape_name
  instance_state             = "RUNNING" # RUNNING or STOPPED
  boot_volume_backup_policy  = "disabled" # disabled, gold, silver or bronze
  user_data                  = base64encode(data.template_file.cloud_config.rendered)
}

data "oci_core_vnic_attachments" "instance_vnic_attachments" {
  compartment_id = var.compartment_id
  instance_id    = module.instance.instance_id[0]
  depends_on = [
    module.instance
  ]
}

resource "oci_core_ipv6" "instance_ipv6" {
  vnic_id = [for k, vnic in data.oci_core_vnic_attachments.instance_vnic_attachments.vnic_attachments : vnic.vnic_id if vnic.state == "ATTACHED" && vnic.subnet_id == var.subnets[0].id][0]
}

resource "oci_core_vnic_attachment" "additional_interfaces" {
//  for_each = toset(slice(var.subnets, 0, length(var.subnets) - 1))
  for_each = {
    for index, subnet in slice(var.subnets, 1, length(var.subnets)):
    index => subnet
  }
  create_vnic_details {
    //    assign_private_dns_record = var.vnic_attachment_create_vnic_details_assign_private_dns_record
    assign_public_ip = each.value["public_access"]
    display_name = "${var.name}-int-${each.key}"
    subnet_id = each.value["id"]
    //    private_ip = cidrhost(oci_core_subnet.public[0].cidr_block, -20 + each.key)
  }
  instance_id = module.instance.instance_id[0]
}

resource "time_sleep" "wait" {
  depends_on = [oci_core_vnic_attachment.additional_interfaces]

  create_duration = "10s"
}

resource "oci_core_ipv6" "additional_interfaces_ipv6" {
  for_each = {
    for index, subnet in slice(var.subnets, 1, length(var.subnets)):
    index => subnet
  }
  vnic_id = oci_core_vnic_attachment.additional_interfaces[each.key].vnic_id
  depends_on = [
    time_sleep.wait,
    oci_core_vnic_attachment.additional_interfaces
  ]
}

data "oci_core_vnic" "additional_interfaces_ips" {
  for_each = {
    for index, subnet in slice(var.subnets, 1, length(var.subnets)):
    index => subnet
  }
  vnic_id = oci_core_vnic_attachment.additional_interfaces[each.key].vnic_id
}
