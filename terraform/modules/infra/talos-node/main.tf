terraform {
  required_providers {
    tailscale = {
      source = "tailscale/tailscale"
    }
    talos = {
      source = "siderolabs/talos"
    }
  }
}

resource "tailscale_tailnet_key" "this" {
  reusable      = false  # TODO: Check if it can be disabled
  ephemeral     = true
  preauthorized = true
  expiry        = 3600
  recreate_if_invalid = "never"
  description   = "Talos Cluster Node - ${var.machine_name}"
  tags          = ["tag:talos"]
}

data "talos_machine_configuration" "machine_init" {
  cluster_endpoint   = "https://${var.cluster_endpoint}:6443"
  cluster_name       = var.cluster_name
  talos_version      = var.talos_version
  kubernetes_version = var.k8s_version
  machine_secrets    = var.machine_secret.machine_secrets
  machine_type       = var.machine_type
  config_patches     = [
    yamlencode({
      machine = {
        certSANs = concat(var.machine_cert_sans, [
          var.cluster_endpoint,
          var.machine_domain
        ])
        sysctls = {
          "net.ipv4.ip_forward" = 1
          "net.ipv6.conf.all.forwarding" = 1
        }
        kubelet = {
          nodeIP = {
            validSubnets = var.cluster_advertised_subnets
          }
        }
        kernel = {
          modules = var.machine_kernel_modules
        }
      }
    }),
    yamlencode({
      apiVersion = "v1alpha1"
      kind = "ExtensionServiceConfig"
      name = "tailscale"
      environment = [
        "TS_AUTHKEY=${tailscale_tailnet_key.this.key}",
        # NOTE: mem state currently doesn't work due to readonly Talos file system.
        # "TS_TAILSCALED_EXTRA_ARGS=--state=mem"
        # "TS_AUTH_ONCE=true"
      ]
    }),
    yamlencode(var.cluster_config),
  ]
}

resource "talos_machine_configuration_apply" "machine_init" {
  client_configuration = var.machine_secret.client_configuration
  machine_configuration_input = data.talos_machine_configuration.machine_init.machine_configuration
  node = var.machine_domain
}

data "tailscale_device" "this" {
  name     = "${var.machine_name}.${var.machine_network_overlay.tailscale.tailnet}"
  wait_for = "60s"
  depends_on = [ talos_machine_configuration_apply.machine_init ]
}

resource "time_sleep" "wait_30_seconds" {
  # count = var.machine_bootstrap ? 1 : 0
  create_duration = "30s"
}

resource "talos_machine_bootstrap" "this" {
  count = var.machine_bootstrap ? 1 : 0
  client_configuration = var.machine_secret.client_configuration
  endpoint             = var.cluster_endpoint
  node                 = var.machine_domain
  depends_on = [
    time_sleep.wait_30_seconds,
    talos_machine_configuration_apply.machine_init,
  ]
}

data "external" "node_cidrs" {
  program = ["bash", "-c", <<EOT
    until kubectl --kubeconfig <(echo "${talos_cluster_kubeconfig.this.kubeconfig_raw}") get node "${var.machine_name}" >/dev/null 2>&1; do
      sleep 5
    done

    CIDRS=$(kubectl --kubeconfig <(echo "${talos_cluster_kubeconfig.this.kubeconfig_raw}") get nodes ${var.machine_name} -o json | jq -r '.spec.podCIDRs | join(",")')

    echo "{\"node_cidrs\": \"$CIDRS\"}"
  EOT
  ]
  depends_on = [
    talos_machine_bootstrap.this,
    talos_cluster_kubeconfig.this,
    talos_machine_configuration_apply.machine_init,
  ]
}

data "talos_machine_configuration" "post_deployment" {
  cluster_endpoint   = "https://${var.cluster_endpoint}:6443"
  cluster_name       = var.cluster_name
  talos_version      = var.talos_version
  kubernetes_version = var.k8s_version
  machine_secrets    = var.machine_secret.machine_secrets
  machine_type       = var.machine_type
  config_patches     = concat(data.talos_machine_configuration.machine_init.config_patches, [
    # NOTE: This is a workaround to add routes for IPv4 Node CIDRs.
    # yamlencode({
    #   machine = {
    #     network = {
    #       interfaces = [{
    #         interface = "tailscale0"
    #         routes = [ for node, info in local.talos_nodes : {
    #           network = local.node_cidrs[node].node_cidrs[0]
    #           # gateway = data.tailscale_device.this[node].addresses[0]
    #         } if node != each.key ]
    #       }]
    #     }
    #   }
    # }),
    yamlencode({
      apiVersion = "v1alpha1"
      kind = "ExtensionServiceConfig"
      name = "tailscale"
      environment = [
        "TS_ROUTES=${data.external.node_cidrs.result.node_cidrs}",
        "TS_EXTRA_ARGS=--reset --accept-routes=${var.machine_network_overlay.tailscale.accept_routes}${var.machine_network_overlay.tailscale.advertise_exit_node ? " --advertise-exit-node" : ""}",
        "TS_ACCEPT_DNS=${var.machine_network_overlay.tailscale.accept_dns}",
        "TS_USERSPACE=false",
        # "TS_AUTH_ONCE=true"
      ]
    }),
  ])
}

resource "talos_machine_configuration_apply" "post_deployment" {
  client_configuration        = var.machine_secret.client_configuration
  machine_configuration_input = data.talos_machine_configuration.post_deployment.machine_configuration
  node = var.machine_domain
  on_destroy = {
    graceful = true
    reset    = true
    reboot   = false
  }
  depends_on = [
    null_resource.delete_k8s_node
  ]
}

data "talos_client_configuration" "this" {
  cluster_name = var.cluster_name
  client_configuration = var.machine_secret.client_configuration
  endpoints = [var.cluster_endpoint]
}

resource "talos_cluster_kubeconfig" "this" {
  client_configuration = var.machine_secret.client_configuration
  node                 = var.cluster_endpoint
}

# data "talos_cluster_health" "this" {
#   for_each = local.talos_nodes
#   client_configuration = var.machine_secret.client_configuration
#   control_plane_nodes = flatten([
#     for node, info in data.tailscale_device.this : info.addresses if local.talos_nodes[node].talos_config.machine_type == "controlplane"
#   ])
#   endpoints = [
#     cloudflare_dns_record.endpoint.name
#   ]
#   timeouts = {
#     read = "30s"
#   }
#   skip_kubernetes_checks = true
#   depends_on = [
#     talos_machine_bootstrap.this,
#     # helm_release.this
#   ]
# }

resource "null_resource" "delete_k8s_node" {
  triggers = {
    kubeconfig = talos_cluster_kubeconfig.this.kubeconfig_raw
    node = var.machine_name
  }
  provisioner "local-exec" {
    when = destroy
    # command = "kubectl --kubeconfig <(echo \"${self.triggers.kubeconfig}\") delete node ${self.triggers.node}"
    interpreter = ["bash", "-c"]
    command = <<EOT
kubectl --kubeconfig <(echo "${self.triggers.kubeconfig}") delete node "${self.triggers.node}"
EOT
  }
}
