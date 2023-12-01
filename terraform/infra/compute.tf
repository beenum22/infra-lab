data "oci_identity_availability_domains" "oracle_ads" {
  compartment_id = var.compartment_id
}

data "oci_core_images" "oracle_images" {
  compartment_id           = var.compartment_id
  operating_system         = "Oracle Linux"
  operating_system_version = "9"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "tls_private_key" "this" {
  algorithm   = "RSA"
  rsa_bits = "2048"
}

module "oracle_instances" {
  for_each = { for instance, info in local.instances : instance => info if info.provider == "oracle" }
  source = "./modules/oci_instance"
  name = each.key
  shape_name = each.value["provider_config"]["shape_name"]
  image_ocid  = each.value["provider_config"]["image_ocid"]
  vcpus = each.value["provider_config"]["vcpus"]
  memory = each.value["provider_config"]["memory"]
  boot_volume = each.value["provider_config"]["boot_volume"]
  subnets = [
    {
      id = module.oracle_vcn.public_subnet_id
      public_access = false
    }
  ]
  ssh_public_keys = concat([trimspace(tls_private_key.this.public_key_openssh)], var.ssh_public_keys)
}

module "hardening" {
  for_each = local.instances
  source = "./modules/firewall-cmd"
  connection_info = {
    user = each.value["user"]
    host = each.value["managed"] == false && each.value["provider"] == "oracle" ? module.oracle_instances[each.key].primary_ipv6_address : each.value["host"]["ipv6"]
    private_key = tls_private_key.this.private_key_openssh
  }
  services = [
    "k3s",
    "tailscale"
  ]
}

module "mesh" {
  for_each = local.instances
  source = "./modules/tailscale"
  connection_info = {
    user = each.value["user"]
    host = each.value["managed"] == false && each.value["provider"] == "oracle" ? module.oracle_instances[each.key].primary_ipv6_address : each.value["host"]["ipv6"]
    private_key = tls_private_key.this.private_key_openssh
  }
  authkey = each.value["tailscale_config"]["auth_key"]
  tailscale_version = each.value["tailscale_config"]["version"]
  tailnet = var.tailscale_tailnet
  hostname = each.key
  exit_node = each.value["tailscale_config"]["exit_node"]
}