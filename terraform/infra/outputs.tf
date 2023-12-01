output "oracle_vcn" {
  description = "Oracle VCN and Gateways information"
  value = module.oracle_vcn.vcn
}

output "oracle_instances" {
  description = "Oracle compute instances"
  value       = module.oracle_instances
}

output "tailscale_ips" {
  value = module.mesh
}

output "nodes" {
  value = {
    for node, info in local.instances : node => {
      user = info.user
      hostname = node
      ips = {
        ipv4 = info["managed"] == false ? (info["provider"] == "oracle" ? module.oracle_instances[node].primary_ipv4_address : "") : node["host"]
        ipv6 = info["managed"] == false ? (info["provider"] == "oracle" ? module.oracle_instances[node].primary_ipv6_address : "") : node["host"]
      }
      tailscale_ips = {
        ipv4 = module.mesh[node].ipv4_address
        ipv6 = module.mesh[node].ipv6_address
      }
    }
  }
}

output "ssh_private_key" {
  value = trimspace(tls_private_key.this.private_key_openssh)
  sensitive = true
}

output "ssh_public_key" {
  value = trimspace(tls_private_key.this.public_key_openssh)
}
