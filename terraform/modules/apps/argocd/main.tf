# Warning: CRDs are not removed on deletion.
# TODO: Add support for CRDs removal on deletion.
locals {
  ingress_annotations = {
    "cert-manager\\.io/cluster-issuer" = var.issuer
    "kubernetes\\.io/ingress\\.class" = var.ingress_class
  }
}

resource "helm_release" "this" {
  name       = var.name
  repository = var.chart_url
  chart      = var.chart_name
  version    = var.chart_version
  namespace   = var.namespace
  set {
    name  = "server.ingress.enabled"
    value = true
  }
  set {
    name  = "server.ingressClassName"
    value = var.ingress_class
  }
  set {
    name  = "global.domain"
    value = var.domain
  }
  set {
    name  = "global.dualStack.ipFamilyPolicy"
    value = "PreferDualStack"
  }
  set {
    name  = "global.dualStack.ipFamilies[0]"
    value = "IPv6"
  }
  set {
    name  = "global.dualStack.ipFamilies[1]"
    value = "IPv4"
  }
  set {
    name  = "configs.params.server\\.insecure"
    value = true
  }
  dynamic "set" {
    for_each   = local.ingress_annotations
    content {
      name = "server.ingress.annotations.${set.key}"
      value = set.value
    }
  }
  set {
    name  = "server.ingress.tls"
    value = true
  }
  set {
    name  = "configs.secret.argocdServerAdminPassword"
    value = bcrypt(var.admin_password)
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
