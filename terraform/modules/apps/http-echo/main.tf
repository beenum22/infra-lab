locals {
  ingress_annotations = {
    "cert-manager.io/cluster-issuer" = var.issuer
    "kubernetes.io/ingress.class" = var.ingress_class
    "external-dns.alpha.kubernetes.io/internal-hostname" = join(",", var.domains)
    "external-dns.alpha.kubernetes.io/target" = var.ingress_hostname
  }
}

resource "kubernetes_deployment" "this" {
  metadata {
    name = var.name
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name" = var.name
      "app.kubernetes.io/instance" = var.name
      "app.kubernetes.io/version" = var.tag
    }
  }
  spec {
    replicas = var.replicas
    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge = "1"
        max_unavailable = "1"
      }
    }
    selector {
      match_labels = {
        "app.kubernetes.io/name" = var.name
        "app.kubernetes.io/instance" = var.name
        "app.kubernetes.io/version" = var.tag
      }
    }
    template {
      metadata {
        name = var.name
        labels = {
          "app.kubernetes.io/name" = var.name
          "app.kubernetes.io/instance" = var.name
          "app.kubernetes.io/version" = var.tag
        }
      }
      spec {
        container {
          name = "http-echo"
          image = "${var.image}:${var.tag}"
          args = [
            "-text='${var.echo_message}'"
          ]
          port {
            container_port = 5678
            name = "http"
            protocol = "TCP"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "this" {
  metadata {
    name = var.name
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name" = var.name
    }
  }
  spec {
    type = "ClusterIP"
    ip_families = [
      "IPv6",
      "IPv4",
    ]
    ip_family_policy = "PreferDualStack"
    selector = {
      "app.kubernetes.io/name" = var.name
    }
    port {
      name = "http"
      port = 80
      target_port = 5678
      protocol = "TCP"
    }
  }
}

moved {
  to = kubernetes_ingress_v1.this
  from   = kubernetes_ingress_v1.private
}

resource "kubernetes_ingress_v1" "this" {
  metadata {
    name = var.name
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name" = var.name
    }
    annotations = local.ingress_annotations
  }
  spec {
    ingress_class_name = var.ingress_class
    tls {
      secret_name = "${var.name}-tls"
      hosts = var.domains
    }
    dynamic "rule" {
      for_each = toset(var.domains)
      content {
        host = rule.value
        http {
          path {
            path = "/"
            backend {
              service {
                name = kubernetes_service.this.metadata.0.name
                port {
                  name = "http"
                }
              }
            }
          }
        }
      }
    }
  }
}
