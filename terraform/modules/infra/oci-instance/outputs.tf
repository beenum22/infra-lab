output "instance_name" {
  value = var.name
}

output "instance_user" {
  value = "opc"
}

output "instance_id" {
  value = try(module.instance.instance_id[0], null)
}

output "primary_ipv4_address" {
  value = try(module.instance.private_ip[0], null)
}

output "primary_public_ipv4_address" {
  value = try(module.instance.public_ip[0], null)
}

output "primary_ipv6_address" {
  value = try(oci_core_ipv6.instance_ipv6.ip_address, null)
}

output "secondary_ipv4_addressses" {
  value = length(var.subnets) > 1 ? [for i, vnic in data.oci_core_vnic.additional_interfaces_ips : vnic.private_ip_address] : []
}

output "secondary_public_ipv4_addresses" {
  value = length(var.subnets) > 1 ? [for i, vnic in data.oci_core_vnic.additional_interfaces_ips : vnic.public_ip_address] : []
}

output "secondardy_ipv6_addresses" {
  value = length(var.subnets) > 1 ? [for i, vnic in oci_core_ipv6.additional_interfaces_ipv6 : vnic.ip_address] : []
}
