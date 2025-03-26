generate_hcl "_backup.tf" {
  content {
    resource "kubernetes_namespace" "backup" {
      metadata {
        name = "backup"
      }
    }

    module "velero" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/velero"
      namespace = kubernetes_namespace.backup.metadata[0].name
      backup_storage_provider = "aws"
      volume_snapshot_provider = "openebs.io/zfspv-blockstore"
      backup_storage_bucket = "talos-velero-backup-storage"
      volume_snapshot_bucket = "talos-velero-volume-snapshots"
      access_key_id = global.secrets.b2.key_id
      secret_access_key = global.secrets.b2.application_key
      depends_on = [
        kubernetes_namespace.backup
      ]
    }
  }
}