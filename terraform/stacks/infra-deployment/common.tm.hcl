generate_hcl "_common.tf" {
  content {
    locals {
      nodes = global.infrastructure.instances
      ssh_port_config = [
        "echo 'Setting SSH port'",
        "echo 'Allowing SSH Port SSH_PORT in SELinux'",
        "semanage port -a -t ssh_port_t -p tcp SSH_PORT",  # Might not work for certain OSs with no SELinux
        "echo 'Adding SSH port SSH_PORT as default port to SSH daemon configuration'",
        "echo 'Port SSH_PORT' >> /etc/ssh/sshd_config",
        "systemctl restart sshd",
        "echo 'Allowing SSH port SSH_PORT in firewall-cmd configuration'",  # Might not work if there's no firewall-cmd
        "firewall-cmd --permanent --add-port=SSH_PORT/tcp",
        "firewall-cmd --reload"
      ]
    }

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
