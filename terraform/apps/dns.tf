resource "kubernetes_namespace" "dns" {
  metadata {
    name = "dns"
  }
}

module "pihole" {
  source = "./modules/pihole"
  namespace = "dns"
  expose = true
  domains = [
    "pihole.dera.ovh"
  ]
  password = var.pihole_password
  ingress_class = "nginx"
  ingress_hostname = "wormhole.dera.ovh"
  issuer = module.cert_manager.issuer
  publish = true
  depends_on = [
    kubernetes_namespace.dns,
    module.cert_manager
  ]
}

module "external_dns" {
  source = "./modules/external-dns"
  namespace = "dns"
  pihole_server = "http://pihole-web.dns.svc.cluster.local"
  pihole_password = var.pihole_password
  depends_on = [
    kubernetes_namespace.dns,
    module.pihole
  ]
}