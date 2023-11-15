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
//  set {
//    name = "image.repository"
//    value = var.image
//  }
//  set {
//    name = "image.tag"
//    value = var.tag
//  }
  set {
    name = "pod.dockermailserver.override_hostname"
    value = var.mail_domain
  }


  set {
    name = "global.storageClass"
    value = var.storage_class
  }
  set {
    name = "global.storageClass"
    value = var.storage_class
  }
  dynamic "set" {
    for_each   = { for idx, domain in var.domains: idx => domain}
    content {
      name = "hostnames[${set.key}]"
      value = set.value
    }
  }
  set {
    name  = "domain"
    value = var.mail_domain
  }
  set {
    name  = "secretKey"
    value = var.password
  }
  set {
    name  = "subnet"
    value = var.subnets.ipv4
  }
  set {
    name  = "subnet6"
    value = var.subnets.ipv6
  }
  set {
    name  = "ingress.ingressClassName"
    value = var.ingress_class
  }
  dynamic "set" {
    for_each   = local.ingress_annotations
    content {
      name = "ingress.annotations.${set.key}"
      value = set.value
    }
  }
  set {
    name  = "front.hostPort.enabled"
    value = false
  }
  set {
    name  = "front.externalService.enabled"
    value = false
  }
//  set {
//    name  = "front.externalService.externalTrafficPolicy"
//    value = ""
//  }

//  set {
//    name  = "ingress.main.tls[0].secretName"
//    value = "${var.name}-tls"
//  }
//  dynamic "set" {
//    for_each   = { for idx, domain in var.domains: idx => domain}
//    content {
//      name = "ingress.main.tls[0].hosts[${set.key}]"
//      value = set.value
//    }
//  }
//  dynamic "set" {
//    for_each   = { for idx, domain in var.domains: idx => domain}
//    content {
//      name = "ingress.main.hosts[${set.key}].host"
//      value = set.value
//    }
//  }
//  dynamic "set" {
//    for_each   = { for idx, domain in var.domains: idx => domain}
//    content {
//      name = "ingress.main.hosts[${set.key}].paths[0].path"
//      value = "/"
//    }
//  }
//  dynamic "set" {
//    for_each = {for idx, domain in var.domains: idx => domain}
//    content {
//      name = "ingress.main.hosts[${set.key}].paths[0].pathType"
//      value = "Prefix"
//    }
//  }
}
