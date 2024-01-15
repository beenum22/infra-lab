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
  namespace  = var.namespace
  set {
    name = "ingress.enabled"
    value = true
  }
  set {
    name  = "ingress.ingressClassName"
    value = var.ingress_class
  }
  set {
    name  = "ingress.tls"
    value = true
  }
  set {
    name  = "ingress.hostname"
    value = var.domains.0
  }
  set {
    name  = "ingress.tls[0].secretName"
    value = "${var.name}-tls"
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
    name = "persistence.config.enabled"
    value = true
  }
  set {
    name = "persistence.config.storageClass"
    value = var.config_storage_class
  }
  set {
    name = "persistence.config.size"
    value = var.config_storage
  }
  set {
    name = "persistence.data.enabled"
    value = true
  }
#  set {
#    name = "persistence.data.storageClass"
#    value = var.data_storage_class
#  }
#  set {
#    name = "persistence.data.size"
#    value = var.data_storage
#  }
#  set {
#    name = "persistence.data.accessMode"
#    value = "ReadWriteMany"
#  }
  dynamic "set" {
    for_each = var.extra_values
    content {
      name = set.key
      value = set.value
      type = "string"
    }
  }
}
