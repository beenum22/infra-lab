generate_hcl "_outputs.tf" {
  lets {
    nodes = [
      for node, info in global.infrastructure.instances : node
    ]
  }

  content {
    output "ssh_private_key" {
      value     = trimspace(tls_private_key.this.private_key_openssh)
      sensitive = true
    }

    output "ssh_public_key" {
      value = trimspace(tls_private_key.this.public_key_openssh)
    }

    output "node_ips" {
      value = {
        for node, info in local.nodes : node => {
          ipv4 = try(info.host.ipv4, info.provider == "hetzner" ? module.hetzner_instances[node].ipv4_address : try(module.oci_instances[node].primary_public_ipv4_address, module.oci_instances[node].primary_ipv4_address))
          ipv6 = try(info.host.ipv6, info.provider == "hetzner" ? module.hetzner_instances[node].ipv6_address : module.oci_instances[node].primary_ipv6_address)
        }
      }
    }
  }
}
