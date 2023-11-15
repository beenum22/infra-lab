resource "helm_release" "postgres" {
  name       = "${var.name}-postgresql"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  version    = "12.5.6"
  namespace   = var.namespace
  set {
    name = "global.storageClass"
    value = "local-path"
  }
}

//resource "helm_release" "chart" {
//  name       = var.name
//  repository = var.chart_url
//  chart      = var.chart_name
//  version    = var.chart_version
//  namespace   = var.namespace
//  set {
//    name = "image.repository"
//    value = var.image
//  }
//  set {
//    name = "image.tag"
//    value = var.tag
//  }
////  set {
////    name = "serviceAccount.create"
////    value = true
////  }
////  set {
////    name = "ingress.main.enabled"
////    value = true
////  }
////  set {
////    name = "ingress.main.ingressClassName"
////    value = var.ingress_class
////  }
////  dynamic "set" {
////    for_each   = { for idx, domain in var.domains: idx => domain}
////    content {
////      name = "ingress.main.hosts[${set.key}].host"
////      value = set.value
////    }
////  }
////  dynamic "set" {
////    for_each   = { for idx, domain in var.domains: idx => domain}
////    content {
////      name = "ingress.main.hosts[${set.key}].paths[0].path"
////      value = "/"
////    }
////  }
//}
