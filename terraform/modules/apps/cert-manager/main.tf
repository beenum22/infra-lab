resource "helm_release" "this" {
  name       = var.name
  repository = var.chart_url
  chart      = var.chart_name
  version    = var.chart_version
  namespace   = var.namespace
  set {
    name = "installCRDs"
    value = true
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

resource "kubernetes_manifest" "cloudflare_issuer" {
  depends_on = [helm_release.this]
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "ClusterIssuer"
    "metadata" = {
      "name"      = "${var.name}-cloudflare"
    }
    "spec" = {
      "acme" = {
        "email" = var.domain_email
        "server" = "https://acme-v02.api.letsencrypt.org/directory"
        "privateKeySecretRef" = {
          "name" = "${var.name}-account-key"
        }
        "solvers" = [
          {
            "dns01" = {
              "cloudflare" = {
                "email" = var.domain_email
                "apiTokenSecretRef" = {
                  "name" = kubernetes_secret.cloudflare.metadata.0.name
                  "key" = "api-token"
                }
              }
            }
          }
        ]
      }
    }
  }
}
