output "vcn" {
  description = "VCN and resources information"
  value = {
    internet_gateway_id = oci_core_internet_gateway.igw.id
    nat_gateway_id      = oci_core_nat_gateway.nat_gw.id
    vcn_id              = oci_core_vcn.vcn.id
    ipv4_cidr           = oci_core_vcn.vcn.cidr_blocks
    ipv6_cidr           = oci_core_vcn.vcn.ipv6cidr_blocks
  }
}

output "private_subnet_id" {
  value = oci_core_subnet.private.id
}

output "public_subnet_id" {
  value = oci_core_subnet.public.id
}
