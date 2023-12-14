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

resource "local_file" "ssh_private_key" {
  filename = pathexpand("~/.ssh/lab_id_rsa")
  content = tls_private_key.this.private_key_pem
  file_permission = "0400"
}

resource "local_file" "ssh_public_key" {
  filename = pathexpand("~/.ssh/lab_id_rsa.pub")
  content = tls_private_key.this.public_key_openssh
  file_permission = "0400"
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
  block_volumes = each.value["provider_config"]["block_volumes"]
  subnets = [
    {
      id = module.oracle_vcn.public_subnet_id
      public_access = false
    }
  ]
  ssh_public_keys = concat([trimspace(tls_private_key.this.public_key_openssh)], var.ssh_public_keys)
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
  tailscale_mtu = each.value["tailscale_config"]["mtu"]
  set_flags = [
    "--advertise-routes=10.42.2.0/24,2001:cafe:42:3::/64"
  ]
}

# Packages needed in the machines:
#  - jq

# TODO:
# Disable root SSH access and password based SSH access
# Setup a k3s user
# Disable sudo password prompt for k3s user # https://medium.com/@jimmashuke/how-to-stop-that-annoying-sudo-password-prompt-in-linux-b2b72b9c2f55
# Install firewall-cmd # https://linux.how2shout.com/how-to-install-and-use-firewalld-on-almalinux-8/
# Install jq

#PasswordAuthentication,PermitRootLogin,ChallengeResponseAuthentication
#sudo vi /etc/ssh/sshd_config
#sudo systemctl reload sshd
#
#sudo visudo
#k3s ALL=(ALL) NOPASSWD: ALL

#PasswordAuthentication,PermitRootLogin,ChallengeResponseAuthentication
#sudo nano /etc/ssh/sshd_config
#sudo systemctl reload sshd
