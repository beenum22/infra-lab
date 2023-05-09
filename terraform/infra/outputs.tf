output "vcn" {
  description = "vcn and gateways information"
  value = module.vcn.vcn
}

output "instances" {
  description = "Compute Instances"
  value       = module.k3s_instances
}
