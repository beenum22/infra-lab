terraform {
  required_version = ">=1.2.9"
  required_providers {
    b2 = {
      source = "Backblaze/b2"
    }
  }
}

locals {
  values = {
    deployNodeAgent = false
    initContainers = [
      {
        name  = "velero-plugin-for-aws"
        image = "velero/velero-plugin-for-aws:v1.8.0"
        imagePullPolicy = "IfNotPresent"
        volumeMounts = [
          {
            name      = "plugins"
            mountPath = "/target"
          }
        ]
      },
      {
        name = "velero-plugin-for-openebs"
        image = "openebs/velero-plugin:3.6.0"
        imagePullPolicy = "IfNotPresent"
        volumeMounts = [
          {
            name      = "plugins"
            mountPath = "/target"
          }
        ]
      }
    ]
    metrics = {
      enabled = false
    }
    credentials = {
      name = var.name
      secretContents = {
        cloud = <<EOT
[default]
aws_access_key_id=${var.access_key_id}
aws_secret_access_key=${var.secret_access_key}
EOT
      }
    }
    configuration = {
      namespace = var.namespace
      backupStorageLocation = [
        {
          provider = var.backup_storage_provider
          bucket  = b2_bucket.backup_storage.bucket_name
          config = {
            region = "eu-central-003"
            s3Url  = "https://s3.eu-central-003.backblazeb2.com"
          }
          credential = {
            name = var.name
            key  = "cloud"
          }
        }
      ]
      volumeSnapshotLocation = [
        {
          provider = var.volume_snapshot_provider
          bucket  = b2_bucket.volume_snapshots.bucket_name
          config = {
            region = "eu-central-003"
            s3Url  = "https://s3.eu-central-003.backblazeb2.com"
          }
          credential = {
            name = var.name
            key  = "cloud"
          }
        }
      ]
    }
  }
}

resource "b2_bucket" "backup_storage" {
  bucket_name = var.backup_storage_bucket
  bucket_type = "allPrivate"
}

resource "b2_bucket" "volume_snapshots" {
  bucket_name = var.volume_snapshot_bucket
  bucket_type = "allPrivate"
}

resource "helm_release" "this" {
  count = var.flux_managed ? 0 : 1
  name       = var.name
  repository = var.chart_url
  chart      = var.chart_name
  version    = var.chart_version
  namespace  = var.namespace
  values     = [yamlencode(local.values)]
}

resource "kubernetes_manifest" "helm_repo" {
  count = var.flux_managed ? 1 : 0
  manifest = {
    apiVersion = "source.toolkit.fluxcd.io/v1"
    kind       = "HelmRepository"
    metadata = {
      name      = var.chart_name
      namespace = var.namespace
    }
    spec = {
      interval = "5m"
      url      = var.chart_url
    }
  }
}

resource "kubernetes_manifest" "helm_release" {
  count = var.flux_managed ? 1 : 0
  manifest = {
    apiVersion = "helm.toolkit.fluxcd.io/v2"
    kind       = "HelmRelease"
    metadata = {
      name      = var.name
      namespace = var.namespace
    }
    spec = {
      interval = "1m"
      releaseName = var.name
      chart = {
        spec = {
          chart   = var.chart_name
          version = var.chart_version
          sourceRef = {
            kind     = "HelmRepository"
            name     = var.chart_name
            namespace = var.namespace
          }
        }
      }
      targetNamespace = var.namespace
      values = local.values
    }
  }
}
