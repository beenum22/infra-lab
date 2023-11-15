resource "kubernetes_namespace" "security" {
  metadata {
    name = "security"
  }
}

module "cert_manager" {
  source = "./modules/cert-manager"
  namespace = kubernetes_namespace.security.metadata[0].name
  domain_email = "muneebahmad22@live.com"
  group_name = "acme.dera.ovh"
  ovh_app_key = var.cert_manager_ovh_app_key
  ovh_app_secret = var.cert_manager_ovh_app_secret
  ovh_consumer_key = var.cert_manager_ovh_consumer_key
  ingress_class = "nginx"
  depends_on = [kubernetes_namespace.security]
}
