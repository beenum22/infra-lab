locals {
  ingress_annotations = {
    "cert-manager.io/cluster-issuer" = var.issuer
    "kubernetes.io/ingress.class" = var.ingress_class
    "external-dns.alpha.kubernetes.io/internal-hostname" = join(",", var.domains)
    "external-dns.alpha.kubernetes.io/target" = var.ingress_hostname
  }
}

resource "kubernetes_persistent_volume_claim" "config" {
  metadata {
    name = "${var.name}-config"
    namespace = var.namespace
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.config_storage
      }
    }
    storage_class_name = var.storage_class
  }
}

resource "kubernetes_persistent_volume_claim" "media" {
 metadata {
   name = "${var.name}-media"
   namespace = var.namespace
 }
 spec {
   access_modes = ["ReadWriteOnce"]
   resources {
     requests = {
       storage = var.data_storage
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
        node_selector = var.node_selectors
        container {
          name = "jellyfin"
          image = "${var.image}:${var.tag}"
          security_context {
            privileged = true
          }
          port {
            container_port = 8096
            name = "http-tcp"
            protocol = "TCP"
          }
          port {
            container_port = 8920
            name = "https-tcp"
            protocol = "TCP"
          }
          port {
            container_port = 1900
            name = "dlna-udp"
            protocol = "UDP"
          }
          port {
            container_port = 7359
            name = "discovery-udp"
            protocol = "UDP"
          }
          env {
            name = "JELLYFIN_PublishedServerUrl"
            value = var.ingress_hostname
          }
          env {
            name = "PGID"
            value = "65541"
          }
          env {
            name = "PUID"
            value = "1044"
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
            mount_path = "/media"
            name = "media"
          }
        }
        volume {
          name = "config"
          persistent_volume_claim {
            claim_name = "${var.name}-config"
          }
        }
        volume {
          name = "media"
          persistent_volume_claim {
            claim_name = "${var.name}-media"
          }
        }
        dynamic "volume" {
          for_each = toset(var.shared_pvcs)
          content {
            name = volume.value.name
            persistent_volume_claim {
              claim_name = volume.value.name
            }
          }
        }
      }
    }
  }
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
      name = "http-tcp"
      port = 8096
      target_port = 8096
      protocol = "TCP"
    }
    port {
      name = "https-tcp"
      port = 8920
      target_port = 8920
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
    session_affinity = "ClientIP"
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
      port = 7359
      target_port = 7359
      protocol = "UDP"
    }
  }
}

resource "kubernetes_ingress_v1" "this" {
  metadata {
    name = var.name
    namespace = var.namespace
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
                name = "${var.name}-tcp"
                port {
                  number = 8096
                }
              }
            }
          }
        }
      }
    }
  }
}
