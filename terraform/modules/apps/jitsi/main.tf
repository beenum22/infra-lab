locals {
  ingress_annotations = {
    "cert-manager\\.io/cluster-issuer" = var.issuer
    "kubernetes\\.io/ingress\\.class" = var.ingress_class
    "external-dns\\.alpha\\.kubernetes\\.io/internal-hostname" = replace(join("\\,", var.domains), ".", "\\.")
    "external-dns\\.alpha\\.kubernetes\\.io/target" = var.ingress_hostname
    "hajimari\\.io/enable" = "true"
//    "hajimari\\.io/icon" = "simple-icons:jitsi"
    "hajimari\\.io/icon" = "https://upload.wikimedia.org/wikipedia/commons/5/5d/Logo_Jitsi.svg"
    "hajimari\\.io/appName" = "jitsi-meet"
#    "hajimari\\.io/group" = "Services"
    "hajimari\\.io/url" = "https://${var.domains[0]}"
    "hajimari\\.io/info" = "Video calling service"
  }
}

resource "helm_release" "chart" {
  name       = var.name
  repository = var.chart_url
  chart      = var.chart_name
  version    = var.chart_version
  namespace   = var.namespace
  set {
    name  = "enableAuth"
    value = false
  }
  set {
    name  = "enableGuests"
    value = true
  }
  set {
    name  = "tz"
    value = "Europe/Berlin"
  }
  set {
    name  = "publicURL"
    value = var.domains[0]
  }

  set {
    name = "web.ingress.enabled"
    value = "true"
  }
  dynamic "set" {
    for_each   = local.ingress_annotations
    content {
      name = "web.ingress.annotations.${set.key}"
      value = set.value
      type = "string"
    }
  }
  dynamic "set" {
    for_each   = { for idx, domain in var.domains: idx => domain}
    content {
      name = "web.ingress.hosts[${set.key}].host"
      value = set.value
    }
  }
  set {
    name  = "web.ingress.tls[0].secretName"
    value = "${var.name}-tls"
  }
  dynamic "set" {
    for_each   = { for idx, domain in var.domains: idx => domain}
    content {
      name = "web.ingress.tls[0].hosts[${set.key}]"
      value = set.value
    }
  }
  dynamic "set" {
    for_each   = { for idx, domain in var.domains: idx => domain}
    content {
      name = "web.ingress.hosts[${set.key}].paths[0]"
      value = "/"
    }
  }
  set {
    name  = "jvb.service.externalTrafficPolicy"
    value = "null"
  }

#  dynamic "set" {
#    for_each   = { for idx, domain in var.domains: idx => domain}
#    content {
#      name = "ingress.main.hosts[${set.key}].paths[0].pathType"
#      value = "Prefix"
#    }
#  }
}
