# NOTE: If needed, find the Hetnzer VM setup code in c6bb21d1daef7f005d3e15b9b695b5a6172a8278
globals "terraform" {
  providers = [
    "tailscale",
    "talos",
    "helm",
    "external",
    "time",
    "local",
    "null",
  ]

  remote_states = {
    stacks = [
      "infra-deployment",
    ]
  }
}

generate_hcl "_talos_cluster.tf" {
  content {
    locals {
      nodes = global.infrastructure.talos_instances
      talos_nodes = {for node, info in local.nodes : node => info if info.enable == true}
    }

    data "helm_template" "flannel" {
      name  = "flannel"
      chart = "https://github.com/flannel-io/flannel/releases/download/v0.27.3/flannel.tgz"
      namespace = "kube-system"
      set = [{
        name = "podCidr"
        value = global.infrastructure.talos.cluster_cidrs[0]
      },
      {
        name = "podCidrv6"
        value = global.infrastructure.talos.cluster_cidrs[1]
      },
      {
        name = "flannel.backend"
        value = "host-gw"
      },
      {
        name  = "flannel.args[0]"
        value = "--iface=tailscale0"
      },
      {
        name  = "flannel.args[1]"
        value = "--ip-masq"
      },
      {
        name  = "flannel.args[2]"
        value = "--kube-subnet-mgr"
      }]
    }

    module "talos_node" {
      for_each = local.talos_nodes
      source = "${terramate.root.path.fs.absolute}/terraform/modules/infra/talos-node"
      talos_version = each.value.talos_config.version
      k8s_version = each.value.talos_config.k8s_version
      machine_secret = data.terraform_remote_state.infra_deployment_stack_state.outputs.talos_machine_secrets
      machine_name = each.key
      machine_type = each.value.talos_config.machine_type
      machine_domain = "${each.key}.cluster.moinmoin.fyi"
      machine_bootstrap = each.value.talos_config.bootstrap
      machine_network_overlay = {
        tailscale = {
          advertise_exit_node = each.value.tailscale_config.exit_node
          accept_routes = true
          accept_dns = false
          tailnet = global.infrastructure.tailscale.tailnet
        }
      }
      machine_cert_sans = []
      cluster_config = {
        cluster = {
          allowSchedulingOnControlPlanes = true
          etcd = {
            advertisedSubnets = global.infrastructure.tailscale.cidrs
          }
          network = {
            podSubnets = global.infrastructure.talos.cluster_cidrs
            serviceSubnets = global.infrastructure.talos.service_cidrs
            cni = {
              name = "none"
            }
          }
          inlineManifests = [
            {
              name = "flannel"
              contents = data.helm_template.flannel.manifest
            },
          ]
        }
      }
      cluster_endpoint   = global.infrastructure.talos.cluster_endpoint
      cluster_name       = global.infrastructure.talos.cluster_name
      cluster_advertised_subnets = global.infrastructure.tailscale.cidrs
    }

    data "talos_client_configuration" "this" {
      cluster_name = global.infrastructure.talos.cluster_name
      client_configuration = data.terraform_remote_state.infra_deployment_stack_state.outputs.talos_machine_secrets.client_configuration
      endpoints = [global.infrastructure.talos.cluster_endpoint]
    }

    resource "local_sensitive_file" "export_talosconfig" {
      content    = data.talos_client_configuration.this.talos_config
      filename   = pathexpand("~/.talos/talosconfig")
    }

    resource "talos_cluster_kubeconfig" "this" {
      client_configuration = data.terraform_remote_state.infra_deployment_stack_state.outputs.talos_machine_secrets["client_configuration"]
      node                 = global.infrastructure.talos.cluster_endpoint
    }

    resource "local_sensitive_file" "export_kubeconfig" {
      content    = talos_cluster_kubeconfig.this.kubeconfig_raw
      filename   = pathexpand("~/.kube/config")
    }

    output "talos" {
      value = {
        for node, info in local.talos_nodes : node => {
          node_cidrs = split(",", module.talos_node[node].node_cidrs)
          tailscale_ips = module.talos_node[node].node_tailscale_ips
          hostname = "${node}.cluster.moinmoin.fyi"
        }
      }
    }
    
    output "talos_kubeconfig" {
      value = talos_cluster_kubeconfig.this.kubeconfig_raw
      sensitive = true
    }
  }
}
