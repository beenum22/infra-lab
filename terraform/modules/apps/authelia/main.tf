locals {
  values = {
    persistence = {
      enabled = true
      storageClass = var.storage_class
    }
    pod = {
      kind = "Deployment"  # Change to Daemonset when the storage is set to MySQL/Postgres
      extraVolumes = [
        {
          name = "users"
          secret = {
            secretName = "${var.name}-users"
            items = [{
                key = "users_database.yml"
                path = "users_database.yml"
            }]
          }
        }
      ]
      extraVolumeMounts = [
        {
          name      = "users"
          mountPath = "/config/mounts/users_database.yml"
          subPath   = "users_database.yml"
        }
      ]
    }
    ingress = {
      enabled = true
      annotations = {
        "cert-manager.io/cluster-issuer" = var.issuer
      }
      className = var.ingress_class
      tls = {
        enabled = true
        secret = "${var.name}-tls"
      }
      rulesOverride = [
        for domain in var.domains : {
          host = domain
          path = "/"
        }
      ]
    }
    configMap = {
      storage = {
        local = {
          enabled = true
        }
      }
      notifier = {
        filesystem = {
          enabled = true
        }
      }

      authentication_backend = {
        file = {
          enabled = true
          path = "/config/mounts/users_database.yml"
          watch = true
        }
      }
      session = {
        cookies = [
          for domain in var.domains : {
            subdomain = ""
            domain    = domain
            path      = ""
          }
        ]
      }
      telemetry = {
        metrics = {
          enabled = false
        }
      }
      log = {
        level = "info"
      }
    }
  }
}

resource "kubernetes_secret" "this" {
  metadata {
    name      = "${var.name}-users"
    namespace = var.namespace
  }
  data = {
    "users_database.yml" = yamlencode(var.credentials)
  }
  type = "Opaque"
}

resource "helm_release" "this" {
  count = var.flux_managed ? 0 : 1
  name       = var.name
  repository = var.chart_url
  chart      = var.chart_name
  version    = var.chart_version
  namespace   = var.namespace
  values = [yamlencode(local.values)]
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
