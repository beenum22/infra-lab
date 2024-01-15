globals "terraform" {
  providers = [
    "ansible",
    "tailscale",
  ]

  remote_states = {
    stacks = [
      "infra-deployment"
    ]
  }
}

generate_hcl "_terramate-ansible.tf" {
  content {
    locals {
      nodes = global.infrastructure.instances
    }

    module "ansible_config" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/infra/ansible-config"
      for_each = local.nodes
      debug  = global.infrastructure.config.ansible_settings.debug
      replay = global.infrastructure.config.ansible_settings.replay
      connection_info = {
        host             = tm_hcl_expression("data.terraform_remote_state.infra_deployment_stack_state.outputs.node_ips[each.key].ipv6")
        user             = each.value.user
        private_key_file = pathexpand("~/.ssh/${global.infrastructure.config.ssh_key_file_name}")
      }
      users           = global.infrastructure.config.users
      default_ssh_key = tm_hcl_expression("data.terraform_remote_state.infra_deployment_stack_state.outputs.ssh_public_key")
      ssh_keys        = global.infrastructure.config.ssh_keys
      packages        = global.infrastructure.config.packages
      hostname        = each.key
      zfs_config      = each.value.zfs_config
    }
  }
}

generate_hcl "_terramate-tailscale.tf" {
  content {
    locals {
      use_ipv6 = global.infrastructure.config.use_ipv6
    }

    module "tailscale" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/infra/tailscale"
      for_each = local.nodes
      connection_info = {
        host             = local.use_ipv6 == true ? tm_hcl_expression("data.terraform_remote_state.infra_deployment_stack_state.outputs.node_ips[each.key].ipv6") : tm_hcl_expression("data.terraform_remote_state.infra_deployment_stack_state.outputs.node_ips[each.key].ipv4")
        user             = each.value.user
        private_key = tm_hcl_expression("data.terraform_remote_state.infra_deployment_stack_state.outputs.ssh_private_key")
      }
      authkey           = each.value.tailscale_config.auth_key
      tailscale_version = each.value.tailscale_config.version
      tailnet           = global.infrastructure.tailscale.tailnet
      hostname          = each.key
      exit_node         = each.value.tailscale_config.exit_node
      tailscale_mtu     = each.value.tailscale_config.mtu
      set_flags         = []
    }

    moved {
      from = module.tailscale_oci_fra_k3s_0
      to = module.tailscale["oci-fra-k3s-0"]
    }

    moved {
      from = module.tailscale_oci_fra_k3s_1
      to = module.tailscale["oci-fra-k3s-1"]
    }

    moved {
      from = module.tailscale_oci_fra_k3s_2
      to = module.tailscale["oci-fra-k3s-2"]
    }

    moved {
      from = module.tailscale_byte_fra_k3s_0
      to = module.tailscale["byte-fra-k3s-0"]
    }

    moved {
      from = module.tailscale_hzn_neu_k3s_0
      to = module.tailscale["hzn-neu-k3s-0"]
    }

    moved {
      from = module.tailscale_netcup_neu_k3s_0
      to = module.tailscale["netcup-neu-k3s-0"]
    }

#    tm_dynamic "module" {
#      for_each = global.infrastructure.instances
#      iterator = item
#      labels   = ["tailscale_${tm_replace(item.key, "-", "_")}"]
#      content {
#        source = "${terramate.root.path.fs.absolute}/terraform/modules/infra/tailscale"
#        connection_info = {
#          host             = tm_hcl_expression("data.terraform_remote_state.infra_deployment_stack_state.outputs.node_ips[\"${item.key}\"].ipv6")
#          user             = item.value.user
#          private_key = pathexpand("~/.ssh/${global.infrastructure.config.ssh_key_file_name}")
#          private_key = tm_hcl_expression("data.terraform_remote_state.infra_deployment_stack_state.outputs.ssh_private_key")
#        }
#        authkey           = item.value.tailscale_config.auth_key
#        tailscale_version = item.value.tailscale_config.version
#        tailnet           = global.infrastructure.tailscale.tailnet
#        hostname          = item.key
#        exit_node         = item.value.tailscale_config.exit_node
#        tailscale_mtu     = item.value.tailscale_config.mtu
#        set_flags         = []
#      }
#    }
  }
}

generate_hcl "_terramate-outputs.tf" {
  content {
    output "k3s_passwords" {
      value = { for node, info in local.nodes : node => module.ansible_config[node].passwords["k3s"].bcrypt_hash}
      sensitive = true
    }

    output "tailscale_ips" {
      value = {
        for node, info in local.nodes : node => {
          ipv4 = module.tailscale[node].ipv4_address
          ipv6 = module.tailscale[node].ipv6_address
        }
      }
    }

#    tm_dynamic "output" {
#      for_each = global.infrastructure.instances
#      iterator = item
#      labels   = ["${tm_replace(item.key, "-", "_")}_tailscale_ips"]
#      attributes = {
#        value = {
#          ipv4 = tm_hcl_expression("module.tailscale_${tm_replace(item.key, "-", "_")}.ipv4_address")
#          ipv6 = tm_hcl_expression("module.tailscale_${tm_replace(item.key, "-", "_")}.ipv6_address")
#        }
#      }
#    }
  }
}
