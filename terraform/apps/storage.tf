resource "kubernetes_namespace" "storage" {
  metadata {
    name = "storage"
  }
}

#module "longhorn" {
#  source = "./modules/longhorn"
#  namespace = kubernetes_namespace.storage.metadata[0].name
#  domains = [
#    "longhorn.dera.ovh"
#  ]
#  ingress_class = "nginx"
#  ingress_hostname = "wormhole.dera.ovh"
#  issuer = "letsencrypt-ovh"
#  publish = true
#  extra_values = {
#    "image.longhorn.ui.repository": "beenum/longhorn-ui"
#    "image.longhorn.ui.tag": "latest"
#  }
#  depends_on = [
#    kubernetes_namespace.storage
#  ]
#}
