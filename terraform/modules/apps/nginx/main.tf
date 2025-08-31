locals {
  # ingress_annotations = {
  #   "external-dns\\.alpha\\.kubernetes\\.io/internal-hostname" = var.domain
  #   "tailscale\\.com/hostname" = var.tailnet_hostname
  # }
  values = {
    controller = {
      kind = "DaemonSet"
      service = {
        enabled = var.expose_on_tailnet ? false : true
        type = "ClusterIP"
        ipFamilyPolicy = "PreferDualStack"
        # Note: Primary IP because Tailscale Operator has some issues with exposing IPv6
        ipFamilies = ["IPv4", "IPv6"]
        annotations = {
          "external-dns.alpha.kubernetes.io/internal-hostname" = var.domain
          "tailscale.com/hostname" = var.tailnet_hostname
        }
      }
      ingressClassResource = {
        name = replace(var.name, "ingress-", "")
        controllerValue = "k8s.io/${var.name}"
      }
      ingressClass = replace(var.name, "ingress-", "")
    }
  }
}

resource "helm_release" "chart" {
  count      = var.flux_managed ? 0 : 1
  name       = var.name
  repository = var.chart_url
  chart      = var.chart_name
  version    = var.chart_version
  namespace  = var.namespace
  values     = [yamlencode(local.values)]
}

resource "kubernetes_manifest" "helm_repo" {
  count = var.flux_managed ? 1 : 0
  manifest = {
    apiVersion = "source.toolkit.fluxcd.io/v1"
    kind       = "HelmRepository"
    metadata = {
      name      = var.chart_name
      namespace = var.namespace
    }
    spec = {
      interval = "5m"
      url      = var.chart_url
    }
  }
}

resource "kubernetes_manifest" "helm_release" {
  count = var.flux_managed ? 1 : 0
  manifest = {
    apiVersion = "helm.toolkit.fluxcd.io/v2"
    kind       = "HelmRelease"
    metadata = {
      name      = var.name
      namespace = var.namespace
    }
    spec = {
      interval = "1m"
      releaseName = var.name
      chart = {
        spec = {
          chart   = var.chart_name
          version = var.chart_version
          sourceRef = {
            kind     = "HelmRepository"
            name     = var.chart_name
            namespace = var.namespace
          }
        }
      }
      targetNamespace = var.namespace
      values = local.values
    }
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
