resource "kubernetes_namespace" "storage" {
  metadata {
    name = "storage"
  }
}

//module "longhorn" {
//  source = "./modules/longhorn"
//  namespace = kubernetes_namespace.storage.metadata[0].name
//  domains = [
//    "longhorn.dera.ovh"
//  ]
//  ingress_class = "nginx"
//  issuer = "letsencrypt-ovh"
//  publish = true
//  depends_on = [
//    kubernetes_namespace.storage,
//    module.cert-manager
//  ]
//}
