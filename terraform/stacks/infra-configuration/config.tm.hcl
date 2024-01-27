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

generate_hcl "_ansible.tf" {
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
        port             = each.value.port
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

generate_hcl "_tailscale.tf" {
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
  }
}

generate_hcl "_outputs.tf" {
  content {
    output "k3s_passwords" {
      value = { for node, info in module.ansible_config : node => info.passwords["k3s"]}
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
  }
}
