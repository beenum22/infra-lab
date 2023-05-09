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

//data "oci_identity_availability_domains" "oracle_ads" {
//  compartment_id = var.compartment_id
//}

//data "oci_core_shapes" "shapes" {
//  compartment_id      = var.compartment_id
//  availability_domain = var.availability_domain
//}

data "oci_core_images" "oracle_images" {
  compartment_id           = var.compartment_id
  operating_system         = var.operating_system
  operating_system_version = var.operating_system_version
  shape                    = var.shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

//output "test" {
//  value = data.oci_core_subnet.subnets
//}
//
//locals {
//  ads = [
//    for ad in data.oci_identity_availability_domains.oracle_ads.availability_domains : ad.name
//  ]
//  shapes_config = {
//  // prepare data with default values for flex shapes. Used to populate shape_config block with default values
//  // Iterate through data.oci_core_shapes.current_ad.shapes (this exclude duplicate data in multi-ad regions) and create a map { name = { memory_in_gbs = "xx"; ocpus = "xx" } }
//  for i in data.oci_core_shapes.shapes.shapes : i.name => {
//    memory_in_gbs = i.memory_in_gbs
//    ocpus         = i.ocpus
//  }
//  }
//  shape_is_flex = length(regexall("^*.Flex", var.shape)) > 0 # evaluates to boolean true when var.shape contains .Flex
//}

data "template_file" "cloud_config" {
  template = <<YAML
#cloud-config
runcmd:
  %{ for cmd in var.cloud_init_commands ~}
  - ${cmd}
  %{ endfor ~}
YAML
}

//data "template_file" "cloud_config" {
//  template = <<YAML
//#cloud-config
//runcmd:
//  - echo 'This instance was provisioned by Terraform.' >> /etc/motd
//  - echo 'Downloading OCI secondary interface configuration script'
//  - wget -O /tmp/secondary_vnic_all_configure.sh https://docs.oracle.com/en-us/iaas/Content/Resources/Assets/secondary_vnic_all_configure.sh
//  - chmod +x /tmp/secondary_vnic_all_configure.sh
//  - until [ $(basename -a /sys/class/net/* | wc -l) -gt 2 ]; do echo "Waiting for secondary VNIC"; sleep 1; done
//  - until sudo /tmp/secondary_vnic_all_configure.sh -c; do echo "Waiting for secondary VNIC configuration"; done
//  - echo 'Installing and configuring Docker'
//  - dnf install -y dnf-utils zip unzip
//  - dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
//  - dnf remove -y runc
//  - dnf install -y docker-ce --nobest
//  - systemctl enable docker.service
//  - systemctl start docker.service
//  - systemctl status docker.service
//  - usermod -aG docker opc
//  - echo 'Allowing ports for K3s'
//  - firewall-cmd --permanent --add-port=22/tcp
//  - firewall-cmd --permanent --add-port=80/tcp
//  - firewall-cmd --permanent --add-port=443/tcp
//  - firewall-cmd --permanent --add-port=2376/tcp
//  - firewall-cmd --permanent --add-port=2379/tcp
//  - firewall-cmd --permanent --add-port=2380/tcp
//  - firewall-cmd --permanent --add-port=6443/tcp
//  - firewall-cmd --permanent --add-port=8472/udp
//  - firewall-cmd --permanent --add-port=9099/tcp
//  - firewall-cmd --permanent --add-port=10250/tcp
//  - firewall-cmd --permanent --add-port=10254/tcp
//  - firewall-cmd --permanent --add-port=30000-32767/tcp
//  - firewall-cmd --permanent --add-port=30000-32767/udp
//  - firewall-cmd --reload
//YAML
//}

module "instance" {
  source = "oracle-terraform-modules/compute-instance/oci"
  instance_count             = 1
  ad_number                  = null
  compartment_ocid           = var.compartment_id
  instance_display_name      = "${var.name}"
  source_ocid                = data.oci_core_images.oracle_images.images[0].id
  subnet_ocids               = [var.subnets[0]["id"]]
  public_ip                  = "NONE" # NONE, RESERVED or EPHEMERAL
  ssh_public_keys            = join("\n", var.ssh_public_keys)
  block_storage_sizes_in_gbs = []
  shape                      = data.oci_core_images.oracle_images.shape
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
