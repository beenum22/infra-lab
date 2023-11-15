resource "kubernetes_deployment" "this" {
  metadata {
    name = var.name
    namespace = var.namespace
    labels = {
      app = var.name
      version = var.tag
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
        app = var.name
        version = var.tag
      }
    }
    template {
      metadata {
        name = var.name
        labels = {
          app = var.name
          version = var.tag
        }
      }
      spec {
        container {
          name = "dashy"
          image = "${var.image}:${var.tag}"
          port {
            container_port = 80
            name = "web"
            protocol = "TCP"
          }
          env {
            name = "NODE_ENV"
            value = "production"
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
  }
  spec {
    selector = {
      app = var.name
      version = var.tag
    }
    port {
      name = "web"
      port = 4000
      target_port = 80
      protocol = "TCP"
    }
  }
}

resource "kubernetes_ingress_v1" "this" {
  metadata {
    name = var.name
    namespace = var.namespace
    annotations = {
      "certmanager.k8s.io/cluster-issuer": var.issuer
      "kubernetes.io/ingress.class" = var.ingress_class
//      "nginx.ingress.kubernetes.io/backend-protocol" = "HTTPS"
//      "nginx.ingress.kubernetes.io/app-root" = "/web"
      "external-dns.alpha.kubernetes.io/internal-hostname" = "dashy.dera.ovh"
    }
  }
  spec {
    ingress_class_name = var.ingress_class
    tls {
      secret_name = "${var.name}-tls"
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
                name = var.name
                port {
                  number = 4000
                }
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_manifest" "cert" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind" = "Certificate"
    "metadata" = {
      "name" = "${var.name}-cert"
      "namespace" = var.namespace
    }
    "spec" = {
      "dnsNames" = var.domains
      "issuerRef" = {
        "name" = var.issuer
        "kind" = "ClusterIssuer"
      }
      "secretName" = "${var.name}-tls"
    }
  }
}
