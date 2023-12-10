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

module "velero" {
  source = "./modules/velero"
  namespace = kubernetes_namespace.storage.metadata[0].name
  backup_provider = "aws"
  backup_storage_bucket = "lab-k3s-backup"
  volume_snapshot_bucket = "lab-k3s-snapshots"
  access_key_id = var.velero_b2_key_id
  secret_access_key = var.velero_b2_application_key
  depends_on = [
    kubernetes_namespace.storage
  ]
}
