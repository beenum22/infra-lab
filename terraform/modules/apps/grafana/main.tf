locals {
  ingress_annotations = {
    "cert-manager\\.io/cluster-issuer" = var.issuer
    "kubernetes\\.io/ingress\\.class" = var.ingress_class
    "external-dns\\.alpha\\.kubernetes\\.io/internal-hostname" = replace(join("\\,", var.domains), ".", "\\.")
    "external-dns\\.alpha\\.kubernetes\\.io/target" = var.ingress_hostname
  }
}

resource "helm_release" "this" {
  name       = var.name
  repository = var.chart_url
  chart      = var.chart_name
  version    = var.chart_version
  namespace   = var.namespace
  set {
    name = "rbac.create"
    value = true
  }
  set {
    name = "serviceAccount.create"
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
  dynamic "set" {
    for_each = { for idx, domain in var.domains: idx => domain}
    content {
      name = "ingress.hosts[${set.key}]"
      value = set.value
    }
  }
  dynamic "set" {
    for_each   = local.ingress_annotations
    content {
      name = "ingress.annotations.${set.key}"
      value = set.value
    }
  }
  set {
    name  = "ingress.tls[0].secretName"
    value = "${var.name}-tls"
  }
  dynamic "set" {
    for_each   = { for idx, domain in var.domains: idx => domain}
    content {
      name = "ingress.tls[0].hosts[${set.key}]"
      value = set.value
    }
  }
  dynamic "set" {
    for_each = var.extra_values
    content {
      name = set.key
      value = set.value
      type = "string"
    }
  }
  set {
    name  = "adminPassword"
    value = var.password
  }
  set {
    name  = "datasources.datasources\\.yaml.apiVersion"
    value = 1
  }
  dynamic "set" {
    for_each   = { for idx, source in var.data_sources: idx => source }
    content {
      name = "datasources.datasources.${set.key}.type"
      value = set.value.type
    }
  }
  dynamic "set" {
    for_each = { for idx, source in var.data_sources: idx => source }
    content {
      name = "datasources.datasources.${set.key}.name"
      value = set.value.name
    }
  }
  dynamic "set" {
    for_each = { for idx, source in var.data_sources: idx => source }
    content {
      name = "datasources.datasources.${set.key}.url"
      value = set.value.url
    }
  }
  dynamic "set" {
    for_each = { for idx, source in var.data_sources: idx => source }
    content {
      name = "plugins.${set.key}"
      value = set.value.plugin
    }
  }
}
