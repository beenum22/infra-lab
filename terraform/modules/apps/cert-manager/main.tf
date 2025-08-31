locals {
  values = {
    crds = {
      enabled = true
    }
  }
}
resource "kubernetes_secret" "cloudflare" {
  metadata {
    name = "${var.name}-cloudflare-api-token"
    namespace = var.namespace
  }
  type = "Opaque"
  data = {
    api-token = var.cloudflare_api_token
  }
}

resource "helm_release" "cert_manager" {
  count      = var.flux_managed ? 0 : 1
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

# NOTE: Temporary workaround for kubernetes_manifest issue where the it fails because the CRD doesn't exist yet.
resource "helm_release" "cluster_issuer" {
  name       = "${var.name}-cluster-issuer"
  depends_on = [ helm_release.cert_manager ]
  chart = "${path.module}/cluster-issuer"
  namespace  = var.namespace
  set = [
    {
      name = "name"
      value = "${var.name}-cloudflare"
    },
    {
      name = "email"
      value = var.domain_email
    },
    {
      name = "cloudflare_secret_name"
      value = kubernetes_secret.cloudflare.metadata.0.name
    },
    {
      name = "cloudflare_secret_key"
      value = "api-token"
    }
  ]
}
