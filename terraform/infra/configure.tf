locals {
  users = {
    muneeb = {
      sudo = true
      exists = true
      password = null
    }
    k3s = {
      sudo = true
      exists = true
      password = null
    }
  }
  ssh_keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC9iQnzPq0/lLg359hzQiVSnf33PAzCYaFu8gW1OIaftA2+/fUtJoPCoMBNB4TDTA5ZnHfKEmR9/ktFr4AWOQ/4oCQP2uC12zci9Lpep/aYMmXmgAGs+35sZvf1Ob44CuEw/vvwfViYNt8HAc0BTo1+Sj5gKp8QuBVY70ezS0yw+VEvHnxbXDbXxVRId1w7gANwBAhyRviKjFWSULPJsPY+t0HNoFozERnBDaov3wL7TPIy2WIHr6BE/lOwlzoqRMd8qtAIEbrDTNfZwmY+2AYvhjicLQ6H5jCfHW6UFptlV4UN9UijdVZ+thF4vM8i6huHUx87ljsyOtqwLqrwfh9t muneebahmad@beenum.local"
  ]
  packages = [
    "jq",
    "net-tools",
    "firewalld",
    "curl"
  ]
}
resource "random_password" "users" {
  for_each = { for user, info in local.users : user => info if info.exists}
  length           = 16
  special          = true
}

locals {
  users_with_password = {
    for user, info in local.users : user => merge(info, { password = try(random_password.users[user].bcrypt_hash, null) })
  }
  merged_ssh_keys = concat(local.ssh_keys, [trimspace(tls_private_key.this.public_key_openssh)])
}

module "ansible_post_deployment" {
  for_each = local.instances
  source = "./modules/ansible-config"
  default_state = var.ansible_destroy ? "absent" : "present"
  debug = var.ansible_debug
  replay = var.ansible_replay
  connection_info = {
    host = each.value["managed"] == false && each.value["provider"] == "oracle" ? module.oracle_instances[each.key].primary_ipv6_address : each.value["host"]["ipv6"]
    user = each.value.user
    private_key_file = local_file.ssh_private_key.filename
  }
  users = local.users_with_password
  ssh_keys = local.merged_ssh_keys
  packages = local.packages
  hostname = each.key
#  tailscale_auth_key = each.value.tailscale_config.auth_key
#  tailscale_config = merge(each.value.tailscale_config, {upgrade = false})
}