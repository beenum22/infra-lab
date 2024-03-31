generate_hcl "_network.tf" {
  content {
    resource "kubernetes_namespace" "network" {
      metadata {
        name = "network"
      }
    }

    module "tailscale_operator" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/tailscale-operator"
      namespace = kubernetes_namespace.network.metadata.0.name
      client_id = global.secrets.tailscale.client_id
      client_secret = global.secrets.tailscale.client_secret
      depends_on = [kubernetes_namespace.network]
    }

    module "nginx" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/nginx"
      namespace = kubernetes_namespace.network.metadata.0.name
      domain = "wormhole.${global.project.zone}"
      expose_on_tailnet = true
      tailnet_hostname = "wormhole"
      depends_on = [kubernetes_namespace.network]
    }

    data "tailscale_device" "nginx" {
      count = module.nginx.lb_hostname != null ? 1 : 0
      name     = module.nginx.lb_hostname
      wait_for = "60s"
    }

    moved {
      from = kubernetes_manifest.test-configmap
      to = kubernetes_manifest.tailscale_subnet_router
    }

    resource "kubernetes_manifest" "tailscale_subnet_router" {
      manifest = {
        "apiVersion" = "tailscale.com/v1alpha1"
        "kind"       = "Connector"
        "metadata" = {
          "name"      = "tailscale-router"
        }
        "spec" = {
          "hostname" = "k8s-subnet-router"
          "subnetRouter" = {
            "advertiseRoutes" = [
              "10.43.0.0/16",
              "2001:cafe:42:1::/112"
            ]
          }
        }
      }
    }

#    resource "tailscale_tailnet_key" "auth_key" {
#      reusable      = true
#      ephemeral     = true
#      preauthorized = true
#      expiry        = 3600
#      description   = "K3s Tailscale Apps"
#    }
#
#    module "tailscale_router" {
#      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/tailscale-router"
#      namespace = kubernetes_namespace.network.metadata.0.name
#      tag = "v1.56.1"
#      replicas = 1
#      authkey = tailscale_tailnet_key.auth_key.key
#      routes = [
#        "10.43.0.0/16",
#        "2001:cafe:42:1::/112"
#      ]
#      mtu = "1280"
#      userspace_mode = true
#      extra_args = []
#      depends_on = [kubernetes_namespace.network]
#    }

    #    module "tailscale_vpn" {
    #      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/tailscale-vpn"
    #      namespace = kubernetes_namespace.network.metadata.0.name
    #      replicas = 1
    #      tag = "v1.56.1"
    #      authkey = tailscale_tailnet_key.auth_key.key
    #      mtu = "1280"  # Consider 1350 in case of MTU issues with IPv6
    #      userspace_mode = true
    #      routes = []
    #      depends_on = [kubernetes_namespace.network]
    #    }
  }
}