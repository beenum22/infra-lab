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
        port             = each.value.port
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

    resource "tailscale_acl" "this" {
      acl = jsonencode(
        {
          autoApprovers = {
            routes = {
              "10.42.0.0/16" = [
                "group:admin",
                "tag:k3s",
              ]
              "2001:cafe:42:0::/56" = [
                "group:admin",
                "tag:k3s",
              ]
              "10.43.0.0/16" = [
                "group:admin",
                "tag:k3s",
              ]
              "2001:cafe:42:1::/112" = [
                "group:admin",
                "tag:k3s",
              ]
            }
            exitNode = [
              "group:admin",
              "tag:k3s",
            ]
          }
          groups = {
            "group:admin" = global.infrastructure.tailscale.acl.admins
            "group:k3s-users" = global.infrastructure.tailscale.acl.k3s_web_apps_consumers
            "group:k3s-developers" = global.infrastructure.tailscale.acl.k3s_api_consumers
            "group:exit-node-users" = global.infrastructure.tailscale.acl.exit_node_consumers
          }
          tagOwners = {
            "tag:k3s" = [
              "group:admin"
            ]
            "tag:k8s-operator" = []
            "tag:k8s" = [
              "group:admin",
              "tag:k8s-operator"
            ]
            "tag:admin" = [
              "group:admin"
            ]
          }
          // Declare convenient hostname aliases to use in place of IP addresses.
          hosts = {
            k3s-cluster-ipv4 = "10.42.0.0/16"
            k3s-cluster-ipv6 = "2001:cafe:42:0::/56"
            k3s-service-ipv4 = "10.43.0.0/16"
            k3s-service-ipv6 = "2001:cafe:42:1::/112"
            wormhole-ipv4 = "10.43.217.93"
            wormhole-ipv6 = "2001:cafe:42:1::e33d"
            dns-ipv4 = "10.43.249.210"
            dns-ipv6 = "2001:cafe:42:1::f1b6"
            google = "8.8.8.8"
            google-ipv6 = "2001:4860:4860::8888"
            tailscale-dns = "100.100.100.100"
          }
          // Define access control lists for users, groups, autogroups, tags,
          // Tailscale IP addresses, and subnet ranges.
          acls = [
            // Match absolutely everything.
            // Comment this section out if you want to define specific restrictions.
            // {"action": "accept", "src": ["*"], "dst": ["*:*"]},
            // Allow resources in K3s subnets to communicate with each other
            {
              action = "accept"
              src = [
                "k3s-cluster-ipv4",
                "k3s-cluster-ipv6",
                "k3s-service-ipv4",
                "k3s-service-ipv6",
              ]
              dst = [
                "k3s-cluster-ipv4:*",
                "k3s-cluster-ipv6:*",
                "k3s-service-ipv4:*",
                "k3s-service-ipv6:*",
              ]
            },
            // Allow all k3s tagged devices to communicate with each other and cluster subnets
            {
              action = "accept"
              src = [
                "tag:k3s",
              ]
              dst = [
                "tag:k3s:*",
                "k3s-cluster-ipv4:*",
                "k3s-cluster-ipv6:*",
                "k3s-service-ipv4:*",
                "k3s-service-ipv6:*",
              ]
            },
            // Allow admind devices to access everything
            {
              action = "accept"
              src = [
                "group:admin",
              ]
              dst = [
                "autogroup:internet:*",
                "tag:k3s:*",
                "tag:k8s:*",
                "tag:k8s-operator:*",
                "k3s-cluster-ipv4:*",
                "k3s-cluster-ipv6:*",
                "k3s-service-ipv4:*",
                "k3s-service-ipv6:*",
              ]
            },
            // Allow user group to access DNS server and hosted HTTPS services
            {
              action = "accept"
              src = ["group:k3s-users"]
              dst = [
                "wormhole-ipv4:443",
                "wormhole-ipv6:443",
                "dns-ipv4:53",
                "dns-ipv6:53",
                "tag:k8s:443",
              ]
            },
            {
              action = "accept"
              dst    = [
                "tag:k3s:6443",
              ]
              src    = [
                "group:k3s-developers",
              ]
            },
            // Allow access to Internet through exit nodes
            {
              action = "accept"
              src = [
                "group:exit-node-users",
                "tag:k3s",
              ]
              dst = [
                "autogroup:internet:*",
              ]
            }
          ]
          // Define users and devices that can use Tailscale SSH.
          ssh = [
            // Allow all users to SSH into their own devices in check mode.
            // Comment this section out if you want to define specific restrictions.
            {
              action = "check"
              src = ["autogroup:member"]
              dst = ["autogroup:self"]
              users = ["autogroup:nonroot", "root"]
            },
            // {
            // 	"action": "check",
            // 	"src":    ["group:admin"],
            // 	"dst":    ["tag:k3s"],
            // 	"users":  ["autogroup:nonroot", "root"],
            // },
          ]
          nodeAttrs = [
            {
              attr = [
                "funnel",
              ]
              target = [
                "autogroup:member",
              ]
            }
          ]
          // Test access rules every time they're saved.
          tests = [
            {
              accept = [
                "wormhole-ipv4:443"
              ]
              src = "group:admin"
            },
            {
              accept = [
                "tag:k3s:443",
                "10.43.0.0:53",
                "10.43.0.10:443",
                "10.42.0.20:80",
              ]
              src = "tag:k3s"
            },
            {
              accept = [
                "wormhole-ipv4:443"
              ]
              deny = [
                "8.8.8.8:53"
              ]
              src = "group:k3s-users"
            },
            {
              accept = [
                "tag:k3s:6443"
              ]
              src = "group:k3s-developers"
            },
            {
              accept = [
                "8.8.8.8:53"
              ]
              deny = [
                "10.43.0.0:443"
              ]
              src = "group:exit-node-users"
            }
          ]
        }
      )
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
