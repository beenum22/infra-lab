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

    resource "kubernetes_daemonset" "zfs_auto_pooler" {
      metadata {
        name = "zfs-auto-pool"
        namespace = kubernetes_namespace.storage.metadata[0].name
      }
      spec {
        selector {
          match_labels = {
            "app.kubernetes.io/name" = "zfs-auto-pool"
          }
        }
        template {
          metadata {
            labels = {
              "app.kubernetes.io/name" = "zfs-auto-pool"
            }
          }
          spec {
            host_pid = true
            host_network = true
            restart_policy = "Always"
            container {
              name  = "zfs"
              image = "alpine:latest"
              security_context {
                privileged = true
              }
              command = [
                "/bin/sh",
                "-c",
                join("\n", [
                  "apk add --no-cache zfs lsblk",
                  "echo \"[ZFS Init] Detecting available disks on $(hostname)...\"",
                  "",
                  "while true; do",

                  " DEVICES=$(lsblk -ndo NAME,TYPE | awk '$2 == \"disk\" { print \"/dev/\" $1 }' | grep -vE 'sda|vda|nvme0n1')",
                  " POOL_DEVICES=\"\"",
                  " for dev in $DEVICES; do",
                  "   if [ -z \"$(lsblk -n $dev | tail -n +2)\" ] && [ -z \"$(blkid $dev)\" ]; then",
                  "      POOL_DEVICES=\"$POOL_DEVICES $dev\"",
                  "   fi",
                  " done",
                  " echo \"[ZFS Init] Found devices: $POOL_DEVICES\"",
                  " if [ -z \"$POOL_DEVICES\" ]; then",
                  "   echo \"[ZFS Init] No clean disks found. Skipping.\"",
                  " else",
                  "   if zpool list openebs-localpv >/dev/null 2>&1; then",
                  "     echo \"[ZFS Init] Pool 'openebs-localpv' already exists. Skipping creation.\"",
                  "   else",
                  "     echo \"[ZFS Init] Creating ZFS pool 'openebs-localpv' with: $POOL_DEVICES\"",
                  "     zpool create -f openebs-localpv $POOL_DEVICES",
                  "   fi",
                  " fi",
                  " sleep 5",
                  "done",

                ])
              ]
            }
          }
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