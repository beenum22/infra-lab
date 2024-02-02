locals {
  ingress_annotations = {
    "cert-manager.io/cluster-issuer" = var.issuer
    "kubernetes.io/ingress.class" = var.ingress_class
    "external-dns.alpha.kubernetes.io/internal-hostname" = join(",", var.domains)
    "external-dns.alpha.kubernetes.io/target" = var.ingress_hostname
  }
  config = <<EOT
    <Config>
      <BindAddress>*</BindAddress>
      <Port>7878</Port>
      <SslPort>9898</SslPort>
      <EnableSsl>False</EnableSsl>
      <LaunchBrowser>True</LaunchBrowser>
      <ApiKey>3e30dd424cdf41e391aeaba6f0b72bfe</ApiKey>
      <AuthenticationMethod>Forms</AuthenticationMethod>
      <AuthenticationRequired>Enabled</AuthenticationRequired>
      <Branch>nightly</Branch>
      <LogLevel>info</LogLevel>
      <SslCertPath></SslCertPath>
      <SslCertPassword></SslCertPassword>
      <UrlBase></UrlBase>
      <InstanceName>Radarr</InstanceName>
      <UpdateMechanism>Docker</UpdateMechanism>
      <AnalyticsEnabled>False</AnalyticsEnabled>
    </Config>
  EOT
}

resource "kubernetes_persistent_volume_claim" "this" {
  metadata {
    name = "${var.name}-config"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name" = var.name
      "app.kubernetes.io/component" = "database"
    }
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

#resource "kubernetes_config_map" "this" {
#  metadata {
#    name = "${var.name}-config-${sha1(jsonencode(local.dashy_config))}"
#    namespace = var.namespace
#  }
#
#  data = {
#    "conf.yml" = yamlencode(local.dashy_config)
#  }
#}

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
          name = "radarr"
          image = "${var.image}:${var.tag}"
          port {
            container_port = 7878
            name = "http"
            protocol = "TCP"
          }
          env {
            name  = "PUID"
            value = 0
          }
          env {
            name  = "PGID"
            value = 0
          }
          env {
            name = "TZ"
            value = "UTC"
          }
          volume_mount {
            name = "config"
            mount_path = "/config"
          }
          dynamic "volume_mount" {
            for_each = toset(var.shared_pvcs)
            content {
              name = volume_mount.value
              mount_path = "/data/media/${volume_mount.value}"
            }
          }
        }
        affinity {
          dynamic "node_affinity" {
            for_each = var.node_affinity
            content {
              required_during_scheduling_ignored_during_execution {
                node_selector_term {
                  match_expressions {
                    key = node_affinity.key
                    operator = "In"
                    values = node_affinity.value
                  }
                }
              }
            }
          }
        }
        volume {
          name = "config"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.this.metadata.0.name
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
      port = 7878
      target_port = 7878
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
