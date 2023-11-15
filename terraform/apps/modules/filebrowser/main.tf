locals {
  ingress_annotations = {
    "cert-manager\\.io/cluster-issuer" = var.issuer
    "kubernetes\\.io/ingress\\.class" = var.ingress_class
    "external-dns\\.alpha\\.kubernetes\\.io/internal-hostname" = replace(join("\\,", var.domains), ".", "\\.")
    "external-dns\\.alpha\\.kubernetes\\.io/target" = var.ingress_hostname
    "hajimari\\.io/enable" = var.publish
    "hajimari\\.io/icon" = "https://raw.githubusercontent.com/filebrowser/logo/master/icon.svg"
    "hajimari\\.io/appName" = "filebrowser"
#    "hajimari\\.io/group" = "Storage"
    "hajimari\\.io/url" = "https://${var.domains[0]}"
    "hajimari\\.io/info" = "Shared File Storage"
  }
}

resource "helm_release" "this" {
  name       = var.name
  repository = var.chart_url
  chart      = var.chart_name
  version    = var.chart_version
  namespace  = var.namespace
  set {
    name = "ingress.main.enabled"
    value = true
  }
  set {
    name  = "ingress.main.ingressClassName"
    value = var.ingress_class
  }
  set {
    name  = "ingress.main.tls[0].secretName"
    value = "${var.name}-tls"
  }
  dynamic "set" {
    for_each   = { for idx, domain in var.domains: idx => domain}
    content {
      name = "ingress.main.tls[0].hosts[${set.key}]"
      value = set.value
    }
  }
  dynamic "set" {
    for_each   = { for idx, domain in var.domains: idx => domain}
    content {
      name = "ingress.main.hosts[${set.key}].host"
      value = set.value
    }
  }
  dynamic "set" {
    for_each   = { for idx, domain in var.domains: idx => domain}
    content {
      name = "ingress.main.hosts[${set.key}].paths[0].path"
      value = "/"
    }
  }
  dynamic "set" {
    for_each   = { for idx, domain in var.domains: idx => domain}
    content {
      name = "ingress.main.hosts[${set.key}].paths[0].pathType"
      value = "Prefix"
    }
  }
  dynamic "set" {
    for_each   = local.ingress_annotations
    content {
      name = "ingress.main.annotations.${set.key}"
      value = set.value
      type = "string"
    }
  }
  set {
    name = "persistence.config.enabled"
    value = true
  }
  set {
    name = "persistence.config.storageClass"
    value = var.storage_class
  }
  set {
    name = "persistence.config.size"
    value = var.config_storage
  }
  set {
    name = "persistence.data.enabled"
    value = true
  }
  set {
    name = "persistence.data.storageClass"
    value = var.storage_class
  }
  set {
    name = "persistence.data.size"
    value = var.data_storage
  }
  set {
    name = "persistence.data.accessMode"
    value = "ReadWriteOnce"
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
