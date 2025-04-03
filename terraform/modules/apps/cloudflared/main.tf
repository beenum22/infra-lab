# Warnings:
# - Description: Cloudflare free plan doesn't allow multilevel domains for tunnel public hostnames.
#   Reference: https://developers.cloudflare.com/ssl/troubleshooting/version-cipher-mismatch/#multi-level-subdomains
# - Description: Latest cloudflare provider fails to delete the tunnel. Keep track of it. 
#   Reference: https://github.com/cloudflare/terraform-provider-cloudflare/issues/5255
# TODOs:
# - Latest cloudflare provider fails to delete the tunnel. Keep track of it.
terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "4.29.0"
    }
  }
}

locals {
  config = {
    tunnel = cloudflare_tunnel.this.id
    credentials-file = "/etc/cloudflared/creds/credentials.json"
    metrics = "0.0.0.0:2000"
    no-autoupdate = true
    ingress = []
  }
}

resource "random_password" "this" {
  length = 16
  special = true
}

resource "cloudflare_tunnel" "this" {
  account_id = var.account_id
  name       = var.name
  secret     = base64encode(random_password.this.result)
}

resource "cloudflare_tunnel_config" "this" {
  tunnel_id = cloudflare_tunnel.this.id
  account_id = var.account_id
  config {
    dynamic "ingress_rule" {
      for_each = toset(var.served_hostnames)
      content {
        hostname = ingress_rule.value
        service = "https://${var.ingress_hostname}"
        origin_request {
          origin_server_name = ingress_rule.value
        }
      }
    }
    ingress_rule {
      service  = "http_status:404"
    }
  }
}

resource "kubernetes_secret" "this" {
  metadata {
    name = "${var.name}-cred"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name" = var.name
      "app.kubernetes.io/instance" = var.name
      "app.kubernetes.io/version" = var.tag
    }
  }
  data = {
    "credentials.json" = jsonencode({
      "AccountTag"   = var.account_id,
      "TunnelID"     = cloudflare_tunnel.this.id,
      "TunnelName"   = cloudflare_tunnel.this.name,
      "TunnelSecret" = base64encode(random_password.this.result)
    })
  }
}

resource "kubernetes_config_map" "this" {
  metadata {
    name = "${var.name}-config-${sha1(jsonencode(local.config))}"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name" = var.name
      "app.kubernetes.io/instance" = var.name
      "app.kubernetes.io/version" = var.tag
    }
  }
  data = {
    "config.yaml" = replace(
      yamlencode(local.config), "\"", ""
    )
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
          name = "cloudflared"
          image = "${var.image}:${var.tag}"
          args = [
            "tunnel",
            "--protocol=http2",
            "--config",
            "/etc/cloudflared/config/config.yaml",
            "--loglevel=info",
            "run"
          ]
          liveness_probe {
            http_get {
              path = "/ready"
              port = "2000"
            }
            failure_threshold = 1
            initial_delay_seconds = 10
            period_seconds = 10
          }
          volume_mount {
            name       = "config"
            mount_path = "/etc/cloudflared/config"
            read_only = true
          }
          volume_mount {
            name       = "creds"
            mount_path = "/etc/cloudflared/creds"
            read_only = true
          }
          port {
            container_port = 2000
            name = "http"
            protocol = "TCP"
          }
        }
        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.this.metadata.0.name
            items {
              key = "config.yaml"
              path = "config.yaml"
            }
          }
        }
        volume {
          name = "creds"
          secret {
            secret_name = kubernetes_secret.this.metadata.0.name
          }
        }
      }
    }
  }
}
