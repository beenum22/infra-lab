locals {
  ingress_annotations = {
    "cert-manager\\.io/cluster-issuer" = var.issuer
    "kubernetes\\.io/ingress\\.class" = var.ingress_class
    "external-dns\\.alpha\\.kubernetes\\.io/internal-hostname" = replace(join("\\,", var.domains), ".", "\\.")
    "external-dns\\.alpha\\.kubernetes\\.io/target" = var.ingress_hostname
    "hajimari\\.io/enable" = var.publish
    "hajimari\\.io/icon" = "icon-park:cloud-storage"
    "hajimari\\.io/appName" = "longhorn"
    "hajimari\\.io/group" = "Cluster"
    "hajimari\\.io/url" = "https://${var.domains[0]}"
    "hajimari\\.io/info" = "Shared Cluster Storage"
  }
}

resource "helm_release" "chart" {
  name       = var.name
  repository = var.chart_url
  chart      = var.chart_name
  version    = var.chart_version
  namespace   = var.namespace
  postrender {
    binary_path = "${path.module}/patch/kustomize"
  }
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
  dynamic "set" {
    for_each   = local.ingress_annotations
    content {
      name = "ingress.annotations.${set.key}"
      value = set.value
      type = "string"
    }
  }
  set {
    name  = "persistence.defaultClass"
    value = false
  }
  dynamic "set" {
    for_each = var.extra_values
    content {
      name = set.key
      value = set.value
      type = "string"
    }
  }
}

#resource "kubernetes_manifest" "cert" {
#  manifest = {
#    "apiVersion" = "cert-manager.io/v1"
#    "kind" = "Certificate"
#    "metadata" = {
#      "name" = "${var.name}-cert"
#      "namespace" = var.namespace
#    }
#    "spec" = {
#      "dnsNames" = var.domains
#      "issuerRef" = {
#        "name" = var.issuer
#        "kind" = "ClusterIssuer"
#      }
#      "secretName" = "${var.name}-tls"
#    }
#  }
#}
