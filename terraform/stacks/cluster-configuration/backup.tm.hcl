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
      backup_storage_bucket = "k3s-backup"
      volume_snapshot_bucket = "k3s-snapshots"
      access_key_id = global.secrets.b2.key_id
      secret_access_key = global.secrets.b2.application_key
      depends_on = [
        kubernetes_namespace.backup
      ]
    }

    import {
      id = "cdffc0d87ceecfa880c10e17"
      to = module.velero.b2_bucket.backup_storage
    }

    import {
      id = "8d9ff0688c1ecfa880c10e17"
      to = module.velero.b2_bucket.volume_snapshots
    }
  }
}