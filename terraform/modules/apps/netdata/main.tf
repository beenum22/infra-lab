locals {
  ingress_annotations = merge({
    "cert-manager\\.io/cluster-issuer" = var.issuer
    "kubernetes\\.io/ingress\\.class" = var.ingress_class
    "external-dns\\.alpha\\.kubernetes\\.io/internal-hostname" = replace(join("\\,", var.domains), ".", "\\.")
    "external-dns\\.alpha\\.kubernetes\\.io/target" = var.ingress_hostname
    "hajimari\\.io/enable" = var.publish
    "hajimari\\.io/icon" = "https://github.com/NX211/homer-icons/blob/master/png/netdata.png?raw=true"
    "hajimari\\.io/appName" = "netdata"
    "hajimari\\.io/group" = "Cluster"
    "hajimari\\.io/url" = "https://${var.domains[0]}"
    "hajimari\\.io/info" = "Monitoring Dashboard"
  },
  var.ingress_protection ? {
    "nginx\\.ingress\\.kubernetes\\.io/auth-type" = "basic"
    "nginx\\.ingress\\.kubernetes\\.io/auth-secret" = "${var.name}-auth"
    "nginx\\.ingress\\.kubernetes\\.io/auth-realm" = "Authentication Required to access Netdata Dashboard - admin"
  } : {}
  )
}

resource "kubernetes_secret" "this" {
  count = var.ingress_protection ? 1 : 0
  metadata {
    name = "${var.name}-auth"
    namespace = var.namespace
  }
  type = "Opaque"
  data = {
    auth = "admin:${bcrypt(var.ingress_password)}"
  }
}

resource "helm_release" "this" {
  name       = var.name
  repository = var.chart_url
  chart      = var.chart_name
  version    = var.chart_version
  namespace   = var.namespace
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
  set {
    name  = "parent.database.storageclass"
    value = var.storage_class
  }
  set {
    name  = "parent.database.volumesize"
    value = var.parent_database_storage_size
  }
  set {
    name  = "parent.alarm.storageclass"
    value = var.storage_class
  }
  set {
    name  = "parent.alarm.volumesize"
    value = var.parent_alarm_storage_size
  }
  set {
    name  = "k8sState.persistence.storageclass"
    value = var.storage_class
  }
  set {
    name  = "k8sState.persistence.volumesize"
    value = var.k8s_state_storage_size
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
