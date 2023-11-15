resource "helm_release" "chart" {
  name       = var.name
  repository = var.chart_url
  chart      = var.chart_name
  version    = var.chart_version
  namespace   = var.namespace
  set {
    name = "defaultSettings.deletingConfirmationFlag"
    value = true
  }
  set {
    name = "ingress.enabled"
    value = true
  }
  set {
    name = "ingress.ingressClassName"
    value = var.ingress_class
  }
  set {
    name = "ingress.host"
    value = var.domains[0]
  }
  set {
    name = "ingress.tls"
    value = true
  }
  set {
    name = "ingress.secureBackends"
    value = true
  }
  set {
    name = "ingress.tlsSecret"
    value = "longhorn-tls"
  }
  set {
    name  = "ingress.annotations.kubernetes\\.io/ingress\\.class"
    value = var.ingress_class
    type = "string"
  }
  set {
    name  = "ingress.annotations.external-dns\\.alpha\\.kubernetes\\.io/internal-hostname"
    value = replace(join("\\,", var.domains), ".", "\\.")
    type = "string"
  }
  set {
    name  = "ingress.annotations.hajimari\\.io/enable"
    value = var.publish
    type = "string"
  }
  set {
    name  = "ingress.annotations.hajimari\\.io/icon"
    value = "simple-icons:pihole"
  }
  set {
    name  = "ingress.annotations.hajimari\\.io/appName"
    value = "pihole"
  }
  set {
    name  = "ingress.annotations.hajimari\\.io/group"
    value = "Cluster"
  }
  set {
    name  = "ingress.annotations.hajimari\\.io/url"
    value = "https://${var.domains[0]}/admin"
  }
  set {
    name  = "ingress.annotations.hajimari\\.io/info"
    value = "DNS Server with Adblocker"
  }
  set {
    name  = "persistence.defaultClass"
    value = false
  }
}

resource "kubernetes_manifest" "cert" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind" = "Certificate"
    "metadata" = {
      "name" = "${var.name}-cert"
      "namespace" = var.namespace
    }
    "spec" = {
      "dnsNames" = var.domains
      "issuerRef" = {
        "name" = var.issuer
        "kind" = "ClusterIssuer"
      }
      "secretName" = "${var.name}-tls"
    }
  }
}
