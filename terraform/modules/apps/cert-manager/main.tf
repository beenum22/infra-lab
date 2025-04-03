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
  name       = var.name
  repository = var.chart_url
  chart      = var.chart_name
  version    = var.chart_version
  namespace   = var.namespace
  set {
    name = "crds.enabled"
    value = true
  }
}

# NOTE: Temporary workaround for kubernetes_manifest issue where the it fails because the CRD doesn't exist yet.
resource "helm_release" "cluster_issuer" {
  name       = "${var.name}-cluster-issuer"
  depends_on = [ helm_release.cert_manager ]
  chart = "${path.module}/cluster-issuer"
  namespace  = var.namespace
  set {
    name = "name"
    value = "${var.name}-cloudflare"
  }
  set {
    name = "email"
    value = var.domain_email
  }
  set {
    name = "cloudflare_secret_name"
    value = kubernetes_secret.cloudflare.metadata.0.name
  }
  set {
    name = "cloudflare_secret_key"
    value = "api-token"
  }
}
