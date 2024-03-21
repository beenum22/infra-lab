locals {
  ingress_annotations = {
    "external-dns\\.alpha\\.kubernetes\\.io/internal-hostname" = var.domain
    "tailscale\\.com/hostname" = var.tailnet_hostname
  }
}

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
    name = "controller.service.type"
    value = var.expose_on_tailnet ? "LoadBalancer" : "ClusterIP"
    type = "string"
  }
  set {
    name = "controller.service.loadBalancerClass"
    value = var.expose_on_tailnet ? "tailscale" : null
    type = "string"
  }
  set {
    name = "controller.service.ipFamilyPolicy"
    value = "PreferDualStack"
    type = "string"
  }
  set {
    name = "controller.service.ipFamilies[1]"
    value = "IPv6"
    type = "string"
  }
  set {
    name = "controller.service.ipFamilies[0]"  # Primary IP because Tailscale Operator has some issues with exposing IPv6
    value = "IPv4"
    type = "string"
  }
  dynamic "set" {
    for_each   = local.ingress_annotations
    content {
      name = "controller.service.annotations.${set.key}"
      value = set.value
    }
  }
}

data "kubernetes_service" "ingress" {
  metadata {
    name = "${var.name}-controller"
    namespace = var.namespace
  }
  depends_on = [helm_release.chart]
}
