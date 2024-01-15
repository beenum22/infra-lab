generate_hcl "_terramate-common.tf" {
  content {

    resource "tls_private_key" "this" {
      algorithm = "RSA"
      rsa_bits  = "2048"
    }

    resource "local_file" "ssh_private_key" {
      filename        = pathexpand("~/.ssh/${global.infrastructure.config.ssh_key_file_name}")
      content         = tls_private_key.this.private_key_pem
      file_permission = "0400"
    }

    resource "local_file" "ssh_public_key" {
      filename        = pathexpand("~/.ssh/${global.infrastructure.config.ssh_key_file_name}.pub")
      content         = tls_private_key.this.public_key_openssh
      file_permission = "0400"
    }
  }
}
