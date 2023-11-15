locals {
  ingress_annotations = {
    "cert-manager\\.io/cluster-issuer" = var.issuer
    "kubernetes\\.io/ingress\\.class" = var.ingress_class
    "external-dns\\.alpha\\.kubernetes\\.io/internal-hostname" = replace(join("\\,", var.domains), ".", "\\.")
    "external-dns\\.alpha\\.kubernetes\\.io/target" = var.ingress_hostname
    "hajimari\\.io/enable" = var.publish
    "hajimari\\.io/icon" = "simple-icons:files"
    "hajimari\\.io/appName" = "filebrowser"
#    "hajimari\\.io/group" = "Storage"
    "hajimari\\.io/url" = "https://${var.domains[0]}"
    "hajimari\\.io/info" = "Readonly Cluster View"
  }
}

resource "helm_release" "this" {
  name       = var.name
  repository = var.chart_url
  chart      = var.chart_name
  version    = var.chart_version
  namespace  = var.namespace
  set {
    name  = "ingress.enabled"
    value = true
  }
  set {
    name  = "ingress.className"
    value = var.ingress_class
  }
  set {
    name  = "ingress.tls[0].secretName"
    value = "${var.name}-tls"
  }
  dynamic "set" {
    for_each = {for idx, domain in var.domains : idx => domain}
    content {
      name  = "ingress.tls[0].hosts[${set.key}]"
      value = set.value
    }
  }
  dynamic "set" {
    for_each = {for idx, domain in var.domains : idx => domain}
    content {
      name  = "ingress.hosts[${set.key}].host"
      value = set.value
    }
  }
  dynamic "set" {
    for_each = {for idx, domain in var.domains : idx => domain}
    content {
      name  = "ingress.hosts[${set.key}].paths[0].path"
      value = "/"
    }
  }
  dynamic "set" {
    for_each = {for idx, domain in var.domains : idx => domain}
    content {
      name  = "ingress.hosts[${set.key}].paths[0].pathType"
      value = "Prefix"
    }
  }
  dynamic "set" {
    for_each = local.ingress_annotations
    content {
      name  = "ingress.annotations.${set.key}"
      value = set.value
      type  = "string"
    }
  }
  dynamic "set" {
    for_each = var.extra_values
    content {
      name  = set.key
      value = set.value
      type  = "string"
    }
  }
}