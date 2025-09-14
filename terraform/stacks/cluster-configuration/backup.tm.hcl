generate_hcl "_backup.tf" {
  content {
    resource "kubernetes_namespace" "backup" {
      metadata {
        name = "backup"
        labels = {
          "pod-security.kubernetes.io/enforce" = "privileged"
          "pod-security.kubernetes.io/audit" = "privileged"
          "pod-security.kubernetes.io/warn" = "privileged"
        }
      }
    }

    module "velero" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/velero"
      flux_managed = true
      chart_version = "10.*.*"  # Use latest upstream version
      namespace = kubernetes_namespace.backup.metadata[0].name
      access_key_id = global.secrets.b2.key_id
      secret_access_key = global.secrets.b2.application_key
      backup_storage = {
        location_name = "b2"
        provider      = "aws"
        bucket        = "talos-velero-backup-storage"
      }
      volume_snapshot = {
        location_name = "b2"
        provider      = "openebs.io/zfspv-blockstore"
        bucket        = "talos-velero-volume-snapshots"
        namespace     = "storage"
      }
      depends_on = [
        kubernetes_namespace.backup
      ]
    }
  }
}