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

    resource "kubernetes_persistent_volume_claim" "nfs_misc" {
      metadata {
        name = "nfs-misc"
        namespace = kubernetes_namespace.apps.metadata[0].name
        labels = {
          "app.kubernetes.io/name" = "nfs-misc"
        }
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

    resource "kubernetes_persistent_volume_claim" "nfs_media" {
      metadata {
        name = "nfs-media"
        namespace = kubernetes_namespace.apps.metadata[0].name
        labels = {
          "app.kubernetes.io/name" = "nfs-media"
        }
      }
      spec {
        access_modes = ["ReadWriteMany"]
        resources {
          requests = {
            storage = "50Gi"
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
     node_selectors = {
       "moinmoin.fyi/country" = "germany"
     }
     config_storage = "1Gi"
     data_storage = "30Gi"
     storage_class = global.project.storage_class
     shared_pvcs = [
       {
         name = kubernetes_persistent_volume_claim.nfs_media.metadata.0.name
         path = kubernetes_persistent_volume_claim.nfs_media.metadata.0.name
       },
#        {
#          name = kubernetes_persistent_volume_claim.nfs_misc.metadata.0.name
#          path = "filebrowser"
#        }
     ]
     domains = [
       "jellyfin.moinmoin.fyi"
     ]
     depends_on = [kubernetes_namespace.apps]
   }

#    module "radarr" {
#      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/radarr"
#      namespace = kubernetes_namespace.apps.metadata[0].name
#      ingress_hostname = global.project.ingress_hostname
#      issuer = global.project.cert_manager_issuer
#      config_storage = "1Gi"
#      storage_class = global.project.storage_class
#      shared_pvcs = [
#        kubernetes_persistent_volume_claim.nfs_share.metadata.0.name
#      ]
#      domains = [
#        "radarr.moinmoin.fyi"
#      ]
#      depends_on = [kubernetes_namespace.apps]
#    }

#    module "prowlarr" {
#      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/prowlarr"
#      namespace = kubernetes_namespace.apps.metadata[0].name
#      ingress_hostname = global.project.ingress_hostname
#      issuer = global.project.cert_manager_issuer
#      config_storage = "1Gi"
#      storage_class = global.project.storage_class
#      shared_pvcs = [
#        kubernetes_persistent_volume_claim.nfs_share.metadata.0.name
#      ]
#      domains = [
#        "prowlarr.moinmoin.fyi"
#      ]
#      depends_on = [kubernetes_namespace.apps]
#    }

    module "dashy" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/dashy"
      namespace = kubernetes_namespace.apps.metadata[0].name
      ingress_hostname = global.project.ingress_hostname
      issuer = global.project.cert_manager_issuer
      domains = [
        "dashy.moinmoin.fyi"
      ]
      depends_on = [kubernetes_namespace.apps]
    }

    module "filebrowser" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/filebrowser"
      namespace = kubernetes_namespace.apps.metadata[0].name
      admin_password = global.secrets.filebrowser_password
      issuer = global.project.cert_manager_issuer
      domains = [
        "filebrowser.moinmoin.fyi"
      ]
      ingress_hostname = global.project.ingress_hostname
      data_storage = "16Gi"
      data_storage_class = "openebs-zfs"
      config_storage = "1Gi"
      config_storage_class = global.project.storage_class
      shared_pvcs = [
       kubernetes_persistent_volume_claim.nfs_media.metadata.0.name,
       kubernetes_persistent_volume_claim.nfs_misc.metadata.0.name
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
        "homebox.moinmoin.fyi"
      ]
      depends_on = [kubernetes_namespace.apps]
    }

    module "http_echo" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/http-echo"
      namespace = kubernetes_namespace.apps.metadata[0].name
      issuer = global.project.cert_manager_issuer
      domains = [
        "echo.moinmoin.fyi"
      ]
      ingress_class = "nginx"
      ingress_hostname = global.project.ingress_hostname
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
            "ttl" = "168h"
          }
        }
      }
    }
  }
}
