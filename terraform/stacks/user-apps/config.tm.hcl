globals "terraform" {
  providers = [
    "helm",
    "kubernetes"
  ]

  remote_states = {
    stacks = []
  }
}

generate_hcl "_apps.tf" {
  content {
    resource "kubernetes_namespace" "apps" {
      metadata {
        name = "apps"
      }
    }

    resource "kubernetes_persistent_volume_claim" "shared_data" {
      metadata {
        name = "shared-data"
        namespace = kubernetes_namespace.apps.metadata[0].name
      }
      spec {
        access_modes = ["ReadWriteMany"]
        resources {
          requests = {
            storage = "30Gi"
          }
        }
        storage_class_name = "openebs-kernel-nfs"
      }
    }

    module "jellyfin" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/jellyfin"
      namespace = kubernetes_namespace.apps.metadata[0].name
      ingress_hostname = global.project.ingress_hostname
      issuer = global.project.cert_manager_issuer
      config_storage = "1Gi"
      storage_class = global.project.storage_class
      shared_pvc = kubernetes_persistent_volume_claim.shared_data.metadata.0.name
      domains = [
        "jellyfin.dera.ovh"
      ]
      publish = true
      depends_on = [kubernetes_namespace.apps]
    }

    module "dashy" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/dashy"
      namespace = kubernetes_namespace.apps.metadata[0].name
      ingress_hostname = global.project.ingress_hostname
      issuer = global.project.cert_manager_issuer
      domains = [
        "dashy.dera.ovh"
      ]
      depends_on = [kubernetes_namespace.apps]
    }

    module "filebrowser" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/filebrowser"
      namespace = kubernetes_namespace.apps.metadata[0].name
      admin_password = global.secrets.filebrowser_password
      issuer = global.project.cert_manager_issuer
      domains = [
        "filebrowser.dera.ovh"
      ]
      ingress_hostname = global.project.ingress_hostname
      data_storage = "16Gi"
      data_storage_class = "openebs-zfs"
      config_storage = "1Gi"
      config_storage_class = global.project.storage_class
      shared_pvcs = [
#        kubernetes_persistent_volume_claim.shared_data.metadata.0.name
      ]
      depends_on = [kubernetes_namespace.apps]
    }

    module "homebox" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/homebox"
      namespace = kubernetes_namespace.apps.metadata[0].name
      ingress_hostname = global.project.ingress_hostname
      issuer = global.project.cert_manager_issuer
      storage_size = "10Gi"
      storage_class = global.project.storage_class
      domains = [
        "homebox.dera.ovh"
      ]
      depends_on = [kubernetes_namespace.apps]
    }

    resource "kubernetes_manifest" "backups" {
      for_each = toset(global.apps.backups)
      manifest = {
        "apiVersion" = "velero.io/v1"
        "kind" = "Schedule"
        "metadata" = {
          "name" = each.value
          "namespace" = "backup"
        }
        "spec" = {
          "schedule" = "5 0 * * *"
          "template" = {
            "includedNamespaces" = [
              kubernetes_namespace.apps.metadata.0.name
            ]
            "labelSelector" = {
              "matchLabels" = {
                "app.kubernetes.io/name" = each.value
              }
            }
            "snapshotVolumes" = true
            "storageLocation" = "default"
            "volumeSnapshotLocations" = ["default"]
            "ttl" = "60m"
          }
        }
      }
    }
  }
}
