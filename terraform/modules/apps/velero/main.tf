#locals {
#  ingress_annotations = {
#    "cert-manager\\.io/cluster-issuer" = var.issuer
#    "kubernetes\\.io/ingress\\.class" = var.ingress_class
#    "external-dns\\.alpha\\.kubernetes\\.io/internal-hostname" = replace(join("\\,", var.domains), ".", "\\.")
#    "external-dns\\.alpha\\.kubernetes\\.io/target" = var.ingress_hostname
#    "hajimari\\.io/enable" = var.publish
#    "hajimari\\.io/icon" = "https://upload.wikimedia.org/wikipedia/commons/0/00/Pi-hole_Logo.png"
#    "hajimari\\.io/appName" = "pihole"
#    "hajimari\\.io/group" = "Cluster"
#    "hajimari\\.io/url" = "https://${var.domains[0]}/admin"
#    "hajimari\\.io/info" = "DNS Server with Adblocker"
#  }
#}

terraform {
  required_version = ">=1.2.9"
  required_providers {
    b2 = {
      source = "Backblaze/b2"
    }
  }
}

resource "b2_bucket" "backup_storage" {
  bucket_name = "k3s-${var.name}-backup-storage"
  bucket_type = "allPrivate"
}

resource "b2_bucket" "volume_snapshots" {
  bucket_name = "k3s-${var.name}-volume-snapshots"
  bucket_type = "allPrivate"
}

resource "helm_release" "this" {
  name       = var.name
  repository = var.chart_url
  chart      = var.chart_name
  version    = var.chart_version
  namespace   = var.namespace
  set {
    name  = "metrics.enabled"
    value = false
  }
#  set {
#    name  = "configuration.backupStorageLocation[0].name"
#    value = "${var.name}-zfs"
#  }
  set {
    name  = "configuration.backupStorageLocation[0].provider"
    value = var.backup_storage_provider
  }
  set {
    name  = "configuration.backupStorageLocation[0].bucket"
    value = b2_bucket.backup_storage.bucket_name
  }
  set {
    name  = "configuration.backupStorageLocation[0].config.region"
    value = "eu-central-003"
  }
  set {
    name  = "configuration.backupStorageLocation[0].config.s3Url"
    value = "https://s3.eu-central-003.backblazeb2.com"
  }
  set {
    name  = "configuration.backupStorageLocation[0].credential.name"
    value = var.name
  }
  set {
    name  = "configuration.backupStorageLocation[0].credential.key"
    value = "cloud"
  }
#  set {
#    name  = "configuration.volumeSnapshotLocation[0].name"
#    value = "${var.name}-zfs"
#  }
  set {
    name  = "configuration.volumeSnapshotLocation[0].provider"
    value = var.volume_snapshot_provider
  }
#  set {
#    name  = "configuration.volumeSnapshotLocation[0].bucket"
#    value = b2_bucket.volume_snapshots.bucket_name
#  }
  set {
    name  = "configuration.volumeSnapshotLocation[0].config.bucket"
    value = b2_bucket.volume_snapshots.bucket_name
  }
  set {
    name  = "configuration.volumeSnapshotLocation[0].config.region"
    value = "eu-central-003"
  }
  set {
    name  = "configuration.volumeSnapshotLocation[0].config.s3Url"
    value = "https://s3.eu-central-003.backblazeb2.com"
  }
  set {
    name  = "configuration.volumeSnapshotLocation[0].config.s3ForcePathStyle"
    value = true
  }
  set {
    name  = "configuration.volumeSnapshotLocation[0].config.namespace"
    value = var.storage_namespace
  }
  set {
    name  = "configuration.volumeSnapshotLocation[0].config.incrBackupCount"
    value = "3"
  }
#  set {
#    name  = "configuration.volumeSnapshotLocation[0].config.prefix"
#    value = "zfs"
#  }
  set {
    name  = "configuration.volumeSnapshotLocation[0].config.provider"
    value = "aws"
  }
  set {
    name  = "configuration.volumeSnapshotLocation[0].config.snapshotType"
    value = "volume"
  }
  set {
    name  = "configuration.volumeSnapshotLocation[0].credential.name"
    value = var.name
  }
  set {
    name  = "configuration.volumeSnapshotLocation[0].credential.key"
    value = "cloud"
  }
  set {
    name  = "configuration.namespace"
    value = var.namespace
  }
#  set {
#    name  = "configuration.features"
#    value = "EnableCSI"
#  }
  set {
    name  = "credentials.name"
    value = var.name
  }
  set {
    name  = "credentials.secretContents.cloud"
    value = <<EOT
[default]
aws_access_key_id=${var.access_key_id}
aws_secret_access_key=${var.secret_access_key}
EOT
  }
  set {
    name  = "initContainers[0].name"
    value = "velero-plugin-for-aws"
  }
  set {
    name  = "initContainers[0].image"
    value = "velero/velero-plugin-for-aws:v1.8.0"
  }
  set {
    name  = "initContainers[0].imagePullPolicy"
    value = "IfNotPresent"
  }
  set {
    name  = "initContainers[0].volumeMounts[0].name"
    value = "plugins"
  }
  set {
    name  = "initContainers[0].volumeMounts[0].mountPath"
    value = "/target"
  }
  set {
    name  = "initContainers[1].name"
    value = "velero-plugin-for-openebs"
  }
  set {
    name  = "initContainers[1].image"
    value = "openebs/velero-plugin:3.6.0"
  }
  set {
    name  = "initContainers[1].imagePullPolicy"
    value = "IfNotPresent"
  }
  set {
    name  = "initContainers[1].volumeMounts[0].name"
    value = "plugins"
  }
  set {
    name  = "initContainers[1].volumeMounts[0].mountPath"
    value = "/target"
  }
#  set {
#    name  = "initContainers[2].name"
#    value = "velero-plugin-for-csi"
#  }
#  set {
#    name  = "initContainers[2].image"
#    value = "velero/velero-plugin-for-csi:v0.6.2"
#  }
#  set {
#    name  = "initContainers[2].imagePullPolicy"
#    value = "IfNotPresent"
#  }
#  set {
#    name  = "initContainers[2].volumeMounts[0].name"
#    value = "plugins"
#  }
#  set {
#    name  = "initContainers[2].volumeMounts[0].mountPath"
#    value = "/target"
#  }
  set {
    name  = "deployNodeAgent"
    value = false
  }
}
