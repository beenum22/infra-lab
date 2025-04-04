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
    name = "controller.service.enabled"
    value = var.expose_on_tailnet ? false : true
  }
  set {
    name = "controller.service.type"
    value = "ClusterIP"
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
  set {
    name  = "controller.ingressClassResource.name"
    value = replace(var.name, "ingress-", "")
  }
  set {
    name  = "controller.ingressClass"
    value = replace(var.name, "ingress-", "")
  }
  set {
    name  = "controller.ingressClassResource.controllerValue"
    value = "k8s.io/${var.name}"
  }
}

resource "kubernetes_service" "this" {
  count = var.expose_on_tailnet ? 1 : 0
  metadata {
    name = "${var.name}-controller"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name" = var.name
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/part-of" = var.name
      "app.kubernetes.io/instance" = var.name
    }
    annotations = {
      "external-dns.alpha.kubernetes.io/internal-hostname" = var.domain
      "tailscale.com/hostname" = var.tailnet_hostname
    }
  }
  spec {
    type = "LoadBalancer"
    load_balancer_class = "tailscale"
    ip_families = ["IPv4", "IPv6"]
    ip_family_policy = "PreferDualStack"
    selector = {
      "app.kubernetes.io/name" = var.name
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/instance" = var.name
    }
    port {
      name = "http"
      port = 80
      target_port = "http"
      protocol = "TCP"
    }
    port {
      name = "https"
      port = 443
      target_port = "https"
      protocol = "TCP"
    }
  }
}

data "kubernetes_service" "this" {
  count = var.expose_on_tailnet ? 0 : 1
  metadata {
    name = "${var.name}-controller"
    namespace = var.namespace
  }
  depends_on = [helm_release.chart]
}
