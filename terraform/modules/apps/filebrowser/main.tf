locals {
  ingress_annotations = {
    "cert-manager.io/cluster-issuer" = var.issuer
    "kubernetes.io/ingress.class" = var.ingress_class
    "external-dns.alpha.kubernetes.io/internal-hostname" = join(",", var.domains)
    "external-dns.alpha.kubernetes.io/target" = var.ingress_hostname
    "nginx.ingress.kubernetes.io/proxy-body-size" = "0"
  }
  db_path = "/config/database.db"
  data_path = "/srv/data"
  config = {
    port = 80
    baseURL = ""
    address = ""
    log = "stdout"
    database = "/config/database.db"
    root = "/srv/data"
  }
}

resource "kubernetes_persistent_volume_claim" "config" {
  metadata {
    name = "${var.name}-config"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name" = var.name
    }
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.config_storage
      }
    }
    storage_class_name = var.config_storage_class
  }
}

resource "kubernetes_persistent_volume_claim" "data" {
  metadata {
    name = "${var.name}-data"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name" = var.name
    }
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.data_storage
      }
    }
    storage_class_name = var.data_storage_class
  }
}

resource "kubernetes_config_map" "this" {
  metadata {
    name = "${var.name}-config-${sha1(jsonencode(local.config))}"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name" = var.name
    }
  }
  data = {
    ".filebrowser.json" = jsonencode(local.config)
  }
}

resource "kubernetes_secret" "this" {
  metadata {
    name = "${var.name}-admin-password"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name" = var.name
    }
  }
  data = {
    admin_password = bcrypt(var.admin_password)
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
    replicas = "1"
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
          name = "filebrowser"
          image = "${var.image}:${var.tag}"
          image_pull_policy = "IfNotPresent"
          startup_probe {
            failure_threshold = 30
            period_seconds = 5
            success_threshold = 1
            tcp_socket {
              port = 80
            }
            timeout_seconds = 1
          }
          liveness_probe {
            failure_threshold = 3
            period_seconds = 10
            success_threshold = 1
            tcp_socket {
              port = 80
            }
            timeout_seconds = 1
          }
          readiness_probe {
            failure_threshold = 3
            period_seconds = 10
            success_threshold = 1
            tcp_socket {
              port = 80
            }
            timeout_seconds = 1
          }
          port {
            container_port = 80
            name = "http"
            protocol = "TCP"
          }
          env {
            name = "FB_PASSWORD"
            value_from {
              secret_key_ref {
                key = "admin_password"
                name = kubernetes_secret.this.metadata.0.name
              }
            }
          }
          env {
            name = "TZ"
            value = "UTC"
          }
          volume_mount {
            mount_path = "/config"
            name = "config"
          }
          volume_mount {
            mount_path = "/srv/data/local"
            name       = "data"
          }
          volume_mount {
            mount_path = "/.filebrowser.json"
            name       = "filebrowser-config"
            sub_path = ".filebrowser.json"
          }
          dynamic "volume_mount" {
            for_each = toset(var.shared_pvcs)
            content {
              mount_path = "/srv/data/${volume_mount.value}"
              name = volume_mount.value
            }
          }
        }
        volume {
          name = "config"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.config.metadata.0.name
          }
        }
        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.data.metadata.0.name
          }
        }
        volume {
          name = "filebrowser-config"
          config_map {
            name = kubernetes_config_map.this.metadata.0.name
          }
        }
        dynamic "volume" {
          for_each = toset(var.shared_pvcs)
          content {
            name = volume.value
            persistent_volume_claim {
              claim_name = volume.value
            }
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
    selector = {
      "app.kubernetes.io/name" = var.name
    }
    ip_families = [
      "IPv6",
      "IPv4",
    ]
    ip_family_policy = "PreferDualStack"
    port {
      name = "http"
      port = 80
      target_port = "http"
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
