generate_hcl "_storage.tf" {
  content {
    resource "kubernetes_namespace" "storage" {
      metadata {
        name = "storage"
        labels = {
          "pod-security.kubernetes.io/enforce" = "privileged"
        }
      }
    }

    module "openebs" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/openebs"
      namespace = kubernetes_namespace.storage.metadata[0].name
      depends_on = [
        kubernetes_namespace.storage
      ]
    }

    resource "kubernetes_manifest" "zfs_snapshot" {
      manifest = {
        apiVersion = "snapshot.storage.k8s.io/v1"
        kind       = "VolumeSnapshotClass"
        metadata = {
          name      = "openebs-zfs"
          labels = {
            "velero.io/csi-volumesnapshot-class" = "true"
          }
          annotations = {
            "snapshot.storage.kubernetes.io/is-default-class" = "true"
          }
        }
        driver = "zfs.csi.openebs.io"
        deletionPolicy = "Delete"
      }
      depends_on = [
        module.openebs
      ]
    }
  }
}