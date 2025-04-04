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
  namespace   = var.namespace
  set {
    name  = "jiva.enabled"
    value = false
  }
  set {
    name  = "cstor.enabled"
    value = false
  }
  set {
    name  = "lvm-localpv.enabled"
    value = false
  }
  set {
    name  = "apiserver.enabled"
    value = false
  }
  set {
    name  = "provisioner.enabled"
    value = false
  }
  set {
    name  = "defaultStorageConfig"
    value = false
  }
  set {
    name  = "openebs-ndm.enabled"
    value = false
  }
  set {
    name  = "localprovisioner.enabled"
    value = true
  }
  set {
    name  = "localprovisioner.deviceClass.enabled"
    value = false
  }
  set {
    name  = "localprovisioner.hostpathClass.enabled"
    value = true
  }
  set {
    name  = "localprovisioner.hostpathClass.isDefaultClass"
    value = false
  }
  set {
    name  = "ndm.enabled"
    value = true
  }
  set {
    name  = "ndmOperator.enabled"
    value = true
  }
  set {
    name  = "ndmExporter.enabled"
    value = false
  }
  set {
    name  = "zfs-localpv.enabled"
    value = true
  }
  set {
    name  = "zfs-localpv.zfsNode.nodeSelector.openebs\\.io/localpv-zfs"
    value = "true"
    type  = "string"
  }
  set {
    name  = "nfs-provisioner.enabled"
    value = true
  }
  set {
    name  = "nfs-provisioner.nfsStorageClass.backendStorageClass"
    value = "${var.name}-zfs"
  }
#   set {
#     name  = "nfs-provisioner.nfsProvisioner.nfsServerNodeAffinity"
#     value = "openebs.io/localpv-zfs\\,openebs.io/nfs-server"
#   }
  set {
    name  = "snapshotOperator.enabled"
    value = true
  }
#  set {
#    name  = "zfs-localpv.zfsNode.allowedTopologyKeys"
#    value = "openebs.io/localpv-zfs"
#  }
 set {
   name  = "zfs-localpv.zfsNode.encrKeysDir"
   value = "/var/zfs"
 }
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
  set {
    name = "name"
    value = "${var.name}-snapshot"
  }
}
