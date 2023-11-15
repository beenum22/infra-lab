locals {
  ingress_annotations = {
    "cert-manager\\.io/cluster-issuer" = var.issuer
    "kubernetes\\.io/ingress\\.class" = var.ingress_class
    "external-dns\\.alpha\\.kubernetes\\.io/internal-hostname" = replace(join("\\,", var.domains), ".", "\\.")
    "external-dns\\.alpha\\.kubernetes\\.io/target" = var.ingress_hostname
    "hajimari\\.io/enable" = var.publish
    "hajimari\\.io/icon" = "https://upload.wikimedia.org/wikipedia/commons/0/00/Pi-hole_Logo.png"
    "hajimari\\.io/appName" = "pihole"
    "hajimari\\.io/group" = "Cluster"
    "hajimari\\.io/url" = "https://${var.domains[0]}/admin"
    "hajimari\\.io/info" = "DNS Server with Adblocker"
  }
}

resource "helm_release" "pihole" {
  name       = var.name
  repository = var.chart_url
  chart      = var.chart_name
  version    = var.chart_version
  namespace   = var.namespace
  dynamic "set" {
    for_each = var.image != null ? [1] : []
    content {
      name = "image.repository"
      value = var.image
    }
  }
  dynamic "set" {
    for_each = var.image != null ? [1] : []
    content {
      name = "image.tag"
      value = var.tag
    }
  }
  set {
    name = "dualStack.enabled"
    value = var.dualstack
  }
  set {
    name  = "serviceDns.type"
    value = "ClusterIP"
    type  = "string"
  }
  set {
    name  = "serviceDhcp.type"
    value = "ClusterIP"
    type  = "string"
  }
  set {
    name  = "serviceWeb.type"
    value = "ClusterIP"
    type  = "string"
  }
  set {
    name  = "ingress.enabled"
    value = var.expose
    type  = "string"
  }
  dynamic "set" {
    for_each   = local.ingress_annotations
    content {
      name = "ingress.annotations.${set.key}"
      value = set.value
      type = "string"
    }
  }
//  set {
//    name  = "ingress.annotations.cert-manager\\.io/cluster-issuer"
//    value = var.issuer
//    type = "string"
//  }
//  set {
//    name  = "ingress.annotations.kubernetes\\.io/ingress\\.class"
//    value = var.ingress_class
//    type = "string"
//  }
//  set {
//    name  = "ingress.annotations.external-dns\\.alpha\\.kubernetes\\.io/internal-hostname"
//    value = replace(join("\\,", var.domains), ".", "\\.")
//    type = "string"
//  }
//  set {
//    name  = "ingress.annotations.hajimari\\.io/enable"
//    value = var.publish
//    type = "string"
//  }
//  set {
//    name  = "ingress.annotations.hajimari\\.io/icon"
//    value = "simple-icons:pihole"
//  }
//  set {
//    name  = "ingress.annotations.hajimari\\.io/appName"
//    value = "pihole"
//  }
//  set {
//    name  = "ingress.annotations.hajimari\\.io/group"
//    value = "Cluster"
//  }
//  set {
//    name  = "ingress.annotations.hajimari\\.io/url"
//    value = "https://${var.domains[0]}/admin"
//  }
//  set {
//    name  = "ingress.annotations.hajimari\\.io/info"
//    value = "DNS Server with Adblocker"
//  }
  set {
    name  = "adminPassword"
    value = var.password
    type = "string"
  }
  dynamic "set" {
    for_each   = { for idx, domain in var.domains: idx => domain}
    content {
      name = "ingress.hosts[${set.key}]"
      value = set.value
    }
  }
  dynamic "set" {
    for_each   = { for idx, domain in var.domains: idx => domain}
    content {
      name = "ingress.tls[0].hosts[${set.key}]"
      value = set.value
    }
  }
  set {
    name  = "ingress.tls[0].secretName"
    value = "${var.name}-tls"
  }
}

//resource "kubernetes_manifest" "cert" {
//  manifest = {
//    "apiVersion" = "cert-manager.io/v1"
//    "kind" = "Certificate"
//    "metadata" = {
//      "name" = "${var.name}-cert"
//      "namespace" = var.namespace
//    }
//    "spec" = {
//      "dnsNames" = var.domains
//      "issuerRef" = {
//        "name" = var.issuer
//        "kind" = "ClusterIssuer"
//      }
//      "secretName" = "${var.name}-tls"
//    }
//  }
//}

data "kubernetes_service" "udp" {
  depends_on = [helm_release.pihole]
  metadata {
    name = "${var.name}-${var.namespace}-udp"
    namespace = var.namespace
  }
}

data "kubernetes_service" "tcp" {
  depends_on = [helm_release.pihole]
  metadata {
    name = "${var.name}-${var.namespace}-tcp"
    namespace = var.namespace
  }
}

data "kubernetes_service" "dhcp" {
  depends_on = [helm_release.pihole]
  metadata {
    name = "${var.name}-dhcp"
    namespace = var.namespace
  }
}

data "kubernetes_service" "web" {
  depends_on = [helm_release.pihole]
  metadata {
    name = "${var.name}-web"
    namespace = var.namespace
  }
}
