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
  }
}