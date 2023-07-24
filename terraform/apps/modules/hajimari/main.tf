locals {
  ingress_annotations = {
    "cert-manager\\.io/cluster-issuer" = var.issuer
    "kubernetes\\.io/ingress\\.class" = var.ingress_class
    "external-dns\\.alpha\\.kubernetes\\.io/internal-hostname" = replace(join("\\,", var.domains), ".", "\\.")
  }
}

resource "helm_release" "chart" {
  name       = var.name
  repository = var.chart_url
  chart      = var.chart_name
  version    = var.chart_version
  namespace   = var.namespace
  set {
    name = "image.repository"
    value = var.image
  }
  set {
    name = "image.tag"
    value = var.tag
  }
//  set {
//    name = "hajimari.defaultEnable"
//    value = true
//  }
  set {
    name = "hajimari.namespaceSelector.any"
    value = "true"
  }
//  dynamic "set" {
//    for_each   = { for idx, ns in var.target_namespaces: idx => ns}
//    content {
//      name = "hajimari.namespaceSelector.matchNames[${set.key}]"
//      value = set.value
//    }
//  }
  set {
    name = "hajimari.title"
    value = var.title
  }
  set {
    name = "hajimari.name"
    value = var.enduser_name
  }
  set {
    name = "hajimari.showAppGroups"
    value = true
  }
  set {
    name = "hajimari.lightTheme"
    value = "passion"
  }
  set {
    name = "hajimari.darkTheme"
    value = "lime"
  }
  set {
    name = "hajimari.showAppInfo"
    value = true
  }
  set {
    name = "hajimari.showAppUrls"
    value = false
  }
  set {
    name = "ingress.main.enabled"
    value = true
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
    }
  }
}
