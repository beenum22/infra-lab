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
      namespace = kubernetes_namespace.network.metadata.0.name
      domain = "ingress.cluster.${global.infrastructure.dns.zone}"
      expose_on_tailnet = true
      tailnet_hostname = "ingress"
      depends_on = [kubernetes_namespace.network]
    }

    resource "kubernetes_manifest" "tailscale_subnet_router" {
      manifest = {
        "apiVersion" = "tailscale.com/v1alpha1"
        "kind"       = "Connector"
        "metadata" = {
          "name"      = "tailscale-router"
        }
        "spec" = {
          "hostname" = "talos-subnet-router"
          "subnetRouter" = {
            "advertiseRoutes" = global.infrastructure.talos.service_cidrs
          }
        }
      }
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