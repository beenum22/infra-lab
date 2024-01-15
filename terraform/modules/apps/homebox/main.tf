locals {
  ingress_annotations = {
    "cert-manager.io/cluster-issuer" = var.issuer
    "kubernetes.io/ingress.class" = var.ingress_class
    "external-dns.alpha.kubernetes.io/internal-hostname" = join(",", var.domains)
    "external-dns.alpha.kubernetes.io/target" = var.ingress_hostname
  }
}

resource "kubernetes_persistent_volume_claim" "this" {
  metadata {
    name = var.name
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name" = var.name
    }
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.storage_size
      }
    }
    storage_class_name = var.storage_class
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
          name = "homebox"
          image = "${var.image}:${var.tag}"
          port {
            container_port = 7745
            name = "http"
            protocol = "TCP"
          }
          env {
            name = "HBOX_LOG_FORMAT"
            value = "info"
          }
          env {
            name = "HBOX_MODE"
            value = "production"
          }
          env {
            name = "HBOX_WEB_PORT"
            value = "7745"
          }
          env {
            name = "HBOX_OPTIONS_ALLOW_REGISTRATION"
            value = "true"
          }
          env {
            name = "HBOX_OPTIONS_AUTO_INCREMENT_ASSET_ID"
            value = "true"
          }
          env {
            name = "HBOX_WEB_MAX_UPLOAD_SIZE"
            value = "10"
          }
          env {
            name = "HBOX_STORAGE_DATA"
            value = "/data/"
          }
          env {
            name = "HBOX_STORAGE_SQLITE_URL"
            value = "/data/homebox.db?_fk=1"
          }
          env {
            name = "HBOX_LOG_FORMAT"
            value = "text"
          }
          env {
            name = "HBOX_MAILER_PORT"
            value = "587"
          }
          env {
            name = "HBOX_SWAGGER_SCHEMA"
            value = "http"
          }
          volume_mount {
            mount_path = "/data"
            name = "data"
          }
        }
        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = var.name
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
    selector = {
      "app.kubernetes.io/name" = var.name
    }
    port {
      name = "http"
      port = 7745
      target_port = 7745
      protocol = "TCP"
    }
  }
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
                name = var.name
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
