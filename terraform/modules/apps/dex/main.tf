locals {
  ingress_annotations = {
    # "cert-manager\\.io/cluster-issuer" = var.issuer
    # "kubernetes\\.io/ingress\\.class" = var.ingress_class
    # "external-dns\\.alpha\\.kubernetes\\.io/internal-hostname" = replace(join("\\,", var.domains), ".", "\\.")
    # "external-dns\\.alpha\\.kubernetes\\.io/target" = var.ingress_hostname
  }
}

resource "helm_release" "this" {
  name       = var.name
  repository = var.chart_url
  chart      = var.chart_name
  version    = var.chart_version
  namespace   = var.namespace
  set {
    name = "image.tag"
    value = var.tag
  }
  set {
    name = "config.issuer"
    value = var.domains[0]
  }
  set {
    name = "config.storage.type"
    value = "memory"
  }
  set {
    name = "config.web.http"
    value = "0.0.0.0:5556"
  }


  # set {
  #   name = "ingress.main.enabled"
  #   value = true
  # }
  # set {
  #   name  = "ingress.main.tls[0].secretName"
  #   value = "${var.name}-tls"
  # }
  # dynamic "set" {
  #   for_each   = { for idx, domain in var.domains: idx => domain}
  #   content {
  #     name = "ingress.main.tls[0].hosts[${set.key}]"
  #     value = set.value
  #   }
  # }
  # dynamic "set" {
  #   for_each   = { for idx, domain in var.domains: idx => domain}
  #   content {
  #     name = "ingress.main.hosts[${set.key}].host"
  #     value = set.value
  #   }
  # }
  # dynamic "set" {
  #   for_each   = { for idx, domain in var.domains: idx => domain}
  #   content {
  #     name = "ingress.main.hosts[${set.key}].paths[0].path"
  #     value = "/"
  #   }
  # }
  # dynamic "set" {
  #   for_each   = { for idx, domain in var.domains: idx => domain}
  #   content {
  #     name = "ingress.main.hosts[${set.key}].paths[0].pathType"
  #     value = "Prefix"
  #   }
  # }
  # dynamic "set" {
  #   for_each   = local.ingress_annotations
  #   content {
  #     name = "ingress.main.annotations.${set.key}"
  #     value = set.value
  #   }
  # }
}
