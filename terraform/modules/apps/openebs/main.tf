locals {
  values = {
    loki = {
      enabled = false
      localpvScConfig = {
        enabled = false
      }
      minio = {
        enabled = false
      }
    }
    alloy = {
      enabled = false
    }
    engines = {
      lvm = {
        enabled = false
      }
      zfs = {
        enabled = true
      }
      rawfile = {
        enabled = false
      }
      replicated = {
        mayastor = {
          enabled = false
        }
      }
    }
    zfs-localpv = {
      crds = {
        zfsLocalPv = {
          enabled = true
        }
        csi = {
          volumeSnapshots = {
            enabled = true
          }
        }
      }
      # enabled = true
      zfsNode = {
        encrKeysDir = "/var/zfs"
        nodeSelector = {
          "openebs.io/localpv-zfs" = "true"
        }
        # allowedTopologyKeys = "openebs.io/localpv-zfs"
      }
    }
    nfs-provisioner = {
      # enabled = true
      nfsStorageClass = {
        backendStorageClass = "${var.name}-zfs"
      }
      # nfsProvisioner = {
      #   nfsServerNodeAffinity = "openebs.io/localpv-zfs,openebs.io/nfs-server"
      # }
    }
    snapshotOperator = {
      enabled = true
    }
    defaultStorageConfig = false
    openebs-crds = {
      csi = {
        volumeSnapshots = {
          enabled = false
        }
      }
    }
  }
}

data "kubernetes_nodes" "this" {
  metadata {
    labels = {
      "openebs.io/localpv-zfs" = true
    }
  }
}

resource "helm_release" "openebs" {
  name       = var.name
  repository = var.chart_url
  chart      = var.chart_name
  version    = var.chart_version
  namespace  = var.namespace
  values     = [yamlencode(local.values)]
#   set {
#     name  = "nfs-provisioner.nfsProvisioner.nfsServerNodeAffinity"
#     value = "openebs.io/localpv-zfs\\,openebs.io/nfs-server"
#   }
#  set {
#    name  = "zfs-localpv.zfsNode.allowedTopologyKeys"
#    value = "openebs.io/localpv-zfs"
#  }
}

resource "kubernetes_storage_class" "zfs_loopback" {
  metadata {
    name = "${var.name}-zfs"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  allow_volume_expansion = true
  parameters = {
    poolname = "openebs-localpv"
    compression = "off"
    dedup = "off"
    fstype = "zfs"
    recordsize = "128k"
  }
  storage_provisioner = "zfs.csi.openebs.io"
  volume_binding_mode = "WaitForFirstConsumer"
#   allowed_topologies {
#     match_label_expressions {
#       key = "kubernetes.io/hostname"
#       values = [for node in data.kubernetes_nodes.this.nodes : node.metadata.0.name]
#     }
#   }
}

# NOTE: Temporary workaround for kubernetes_manifest issue where the it fails because the CRD doesn't exist yet.
resource "helm_release" "snapshot" {
  name       = "${var.name}-snapshot"
  depends_on = [ helm_release.openebs ]
  chart = "${path.module}/snapshot"
  namespace  = var.namespace
  set = [{
    name = "name"
    value = "${var.name}-snapshot"
  }]
}
