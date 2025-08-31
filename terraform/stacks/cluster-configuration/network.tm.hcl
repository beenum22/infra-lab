generate_hcl "_network.tf" {
  content {
    resource "kubernetes_namespace" "network" {
      metadata {
        name = "network"
        labels = {
          "pod-security.kubernetes.io/enforce" = "privileged"
        }
      }
    }

    module "tailscale_operator" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/tailscale-operator"
      name = "talos-ts-operator"
      namespace = kubernetes_namespace.network.metadata.0.name
      client_id = global.secrets.tailscale.client_id
      client_secret = global.secrets.tailscale.client_secret
      depends_on = [kubernetes_namespace.network]
    }

    module "nginx" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/nginx"
      flux_managed = true
      chart_version = "4.*.*"  # Use latest upstream version
      namespace = kubernetes_namespace.network.metadata.0.name
      domain = "ingress.cluster.${global.infrastructure.dns.zone}"
      expose_on_tailnet = true
      tailnet_hostname = "talos-ingress"
      depends_on = [kubernetes_namespace.network]
    }

    module "tailscale_router" {
      depends_on = [module.tailscale_operator]
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/tailscale-router"
      name = "talos-ts-router"
      hostname = "talos-router"
      namespace = kubernetes_namespace.network.metadata.0.name
      routes = global.infrastructure.talos.service_cidrs
    }

    # NOTE:
    # Make sure host machines have the following set if QUIC is used:
    # sudo sysctl -w net.core.wmem_max=7500000 && sudo sysctl -w net.core.rmem_max=7500000
    module "cloudflared" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/cloudflared"
      name = "cloudflared-talos"
      namespace = kubernetes_namespace.network.metadata.0.name
      ingress_hostname = "ingress-nginx-controller"
      served_hostnames = flatten([
        for app, info in local.apps : info.hostnames if info.public == true
      ])
      account_id = global.infrastructure.cloudflare.account_id
    }
  }
}