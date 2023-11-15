resource "kubernetes_namespace" "network" {
  metadata {
    name = "network"
  }
}

module "nginx" {
  source = "./modules/nginx"
  namespace = "network"
  domain = "wormhole.dera.ovh"
  depends_on = [kubernetes_namespace.network]
}

module "tailscale_router" {
  source = "./modules/tailscale-router"
  namespace = "network"
  tag = "v1.50.1"
  replicas = 2
  authkey = var.tailscale_authkey
  routes = [
    "10.43.0.0/16",
    "2001:cafe:42:1::/112"
  ]
  mtu = "1350"
  extra_args = []
  depends_on = [kubernetes_namespace.network]
}

module "tailscale_vpn" {
  source = "./modules/tailscale-vpn"
  namespace = "network"
  replicas = 2
//  image = "beenum/tailscale"
  tag = "v1.50.1"
  authkey = var.tailscale_authkey
//  mtu = "1350"
  routes = []
  depends_on = [kubernetes_namespace.network]
}