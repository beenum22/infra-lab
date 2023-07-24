resource "helm_release" "chart" {
  name       = var.name
  repository = var.chart_url
  chart      = var.chart_name
  version    = var.chart_version
  namespace   = var.namespace
  set {
    name = "controller.kind"
    value = "DaemonSet"
  }
  set {
    name = "controller.image.image"
    value = var.image
  }
  set {
    name = "controller.image.tag"
    value = var.tag
  }
  set {
    name = "controller.service.type"
    value = "ClusterIP"
  }
  set {
    name = "controller.service.ipFamilyPolicy"
    value = "PreferDualStack"
    type = "string"
  }
  set {
    name = "controller.service.ipFamilies[0]"
    value = "IPv6"
    type = "string"
  }
  set {
    name = "controller.service.ipFamilies[1]"
    value = "IPv4"
    type = "string"
  }
}

//resource "kubernetes_service" "second_service" {
//  metadata {
//    name = "${var.name}-controller-ipv4"
//    namespace = var.namespace
//  }
//  spec {
//    selector = {
//      "app.kubernetes.io/component" = "controller"
//      "app.kubernetes.io/instance" = var.name
//      "app.kubernetes.io/name" = var.name
//    }
//    port {
//      name = "http"
//      port        = 80
//      target_port = 80
//      protocol = "TCP"
//    }
//
//    port {
//      name = "https"
//      port        = 443
//      target_port = 443
//      protocol = "TCP"
//    }
//    type = "ClusterIP"
//  }
//}
