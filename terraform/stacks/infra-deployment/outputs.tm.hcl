generate_hcl "_terramate-outputs.tf" {
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
  }
}
