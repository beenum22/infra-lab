resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

module "netdata" {
  source = "./modules/netdata"
  namespace = kubernetes_namespace.monitoring.metadata[0].name
  issuer = module.cert_manager.issuer
  domains = [
    "netdata.dera.ovh"
  ]
  publish = true
  ingress_password = var.netdata_password
//  password = var.netdata_password
  storage_class = "local-path"
  ingress_hostname = "wormhole.dera.ovh"
  ingress_protection = false
  depends_on = [kubernetes_namespace.monitoring]
}