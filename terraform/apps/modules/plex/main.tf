resource "kubernetes_persistent_volume_claim" "config" {
  metadata {
    name = "${var.name}-config"
    namespace = var.namespace
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
    storage_class_name = var.storage_class
  }
}

resource "kubernetes_persistent_volume_claim" "data" {
  metadata {
    name = "${var.name}-data"
    namespace = var.namespace
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "40Gi"
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
      app = var.name
      version = var.tag
    }
  }
  spec {
    replicas = var.replicas
    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge = "0"
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
          name = "plexserver"
          image = "${var.image}:${var.tag}"
          port {
            container_port = 32400
            name = "pms-web"
            protocol = "TCP"
          }
          port {
            container_port = 32469
            name = "dlna-tcp"
            protocol = "TCP"
          }
          port {
            container_port = 1900
            name = "dlna-udp"
            protocol = "UDP"
          }
          port {
            container_port = 3005
            name = "plex-companion"
            protocol = "TCP"
          }
          port {
            container_port = 5353
            name = "discovery-udp"
            protocol = "UDP"
          }
          port {
            container_port = 8324
            name = "plex-roku"
            protocol = "TCP"
          }
          port {
            container_port = 32410
            name = "gdm-32410"
            protocol = "UDP"
          }
          port {
            container_port = 32412
            name = "gdm-32412"
            protocol = "UDP"
          }
          port {
            container_port = 32413
            name = "gdm-32413"
            protocol = "UDP"
          }
          port {
            container_port = 32414
            name = "gdm-32414"
            protocol = "UDP"
          }
          env {
            name = "PLEX_CLAIM"
            value = var.plex_token
          }
          env {
            name = "PGID"
            value = "100"
          }
          env {
            name = "PUID"
            value = "1035"
          }
          env {
            name = "TZ"
            value = "Europe/Berlin"
          }
          volume_mount {
            mount_path = "/config"
            name = "config"
          }
          volume_mount {
            mount_path = "/data"
            name = "data"
          }
        }
        volume {
          name = "config"
          persistent_volume_claim {
            claim_name = "${var.name}-config"
          }
        }
        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = "${var.name}-data"
          }
        }
      }
    }
  }
//  depends_on = [
//    kubernetes_persistent_volume_claim.config,
//    kubernetes_persistent_volume_claim.data
//  ]
}

resource "kubernetes_service" "tcp" {
  metadata {
    name = "${var.name}-tcp"
    namespace = var.namespace
  }
  spec {
    selector = {
      app = var.name
      version = var.tag
    }
    port {
      name = "pms-web"
      port = 32400
      target_port = 32400
      protocol = "TCP"
    }
    port {
      name = "plex-companion"
      port = 3005
      target_port = 3005
      protocol = "TCP"
    }
    port {
      name = "plex-roku"
      port = 8324
      target_port = 8324
      protocol = "TCP"
    }
    port {
      name = "dlna-tcp"
      port = 32469
      target_port = 32469
      protocol = "TCP"
    }
  }
}

resource "kubernetes_service" "udp" {
  metadata {
    name = "${var.name}-udp"
    namespace = var.namespace
  }
  spec {
    selector = {
      app = var.name
      version = var.tag
    }
    port {
      name = "dlna-udp"
      port = 1900
      target_port = 1900
      protocol = "UDP"
    }
    port {
      name = "discovery-udp"
      port = 5353
      target_port = 5353
      protocol = "UDP"
    }
    port {
      name = "gdm-32410"
      port = 32410
      target_port = 32410
      protocol = "UDP"
    }
    port {
      name = "gdm-32412"
      port = 32412
      target_port = 32412
      protocol = "UDP"
    }
    port {
      name = "gdm-32413"
      port = 32413
      target_port = 32413
      protocol = "UDP"
    }
    port {
      name = "gdm-32414"
      port = 32414
      target_port = 32414
      protocol = "UDP"
    }
  }
}

resource "kubernetes_ingress_v1" "this" {
  metadata {
    name = var.name
    namespace = var.namespace
    annotations = {
      "kubernetes.io/ingress.class" = var.ingress_class
//      "nginx.ingress.kubernetes.io/backend-protocol" = "HTTPS"
      "nginx.ingress.kubernetes.io/app-root" = "/web"
      "external-dns.alpha.kubernetes.io/internal-hostname" = "plex.k3s.home"
    }
  }
  spec {
    ingress_class_name = var.ingress_class
    rule {
      host = "plex.k3s.home"
      http {
        path {
          path = "/"
          backend {
            service {
              name = "${var.name}-tcp"
              port {
                number = 32400
              }
            }
          }
        }
      }
    }
  }
}
