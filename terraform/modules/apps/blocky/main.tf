locals {
  ingress_annotations = {
    "cert-manager.io/cluster-issuer" = var.issuer
    "kubernetes.io/ingress.class" = var.ingress_class
    "external-dns.alpha.kubernetes.io/internal-hostname" = join(",", var.domains)
    "external-dns.alpha.kubernetes.io/target" = var.ingress_hostname
  }
  config = {
    connectIPVersion = "dual"
    upstreams = {
      init = {
        strategy = "fast"
      }
      strategy = "parallel_best"
      timeout = "2s"
      groups = {
        default = var.default_upstream_servers
      }
    }
    customDNS = {
      filterUnmappedTypes = true
      rewrite = var.custom_dns_rewrites
      mapping = var.custom_dns_mappings
    }
    conditional = {
      rewrite = var.conditional_rewrites
      mapping = var.conditional_mappings
    }
    blocking = {
      blackLists = {
        ads = [
          "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/pro.plus.txt",
        ]
        strict = [
          "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/ultimate.txt",
        ]
      }
      whiteLists = {}
      clientGroupsBlock = {
        default = [
          "ads",
        ]
#        "laptop*" = [
#          "strict"
#        ]
      }
      blockType = "zeroIp"
      blockTTL = "1m"
      loading = {
        refreshPeriod = "4h"
        strategy = "failOnError"
        downloads = {
          timeout = "4m"
          attempts = "5"
          cooldown = "10s"
        }
      }
    }
    caching = {
      minTime = "5m"
      maxTime = "-1m"
      maxItemsCount = "0"
      prefetching = true
      prefetchExpires = "2h"
      prefetchThreshold = "5"
      prefetchMaxItemsCount = "0"
    }
    clientLookup = {
#      upstream = "100.100.100.100"
#      singleNameOrder = [2, 1]
#      clients = {}
    }
    prometheus = {
      enable = false
      path = "/metrics"
    }
    queryLog = {}
    ports = {
      dns = 53
      http = 4000
    }
    # mandatory, if https port > 0: path to cert and key file for SSL encryption
    #certFile = "server.crt"
    #keyFile = "server.key"
    bootstrapDns = "tcp+udp:1.1.1.1"
    log = {
      level = "debug"
      format = "text"
      timestamp = true
      privacy = false
    }
    filtering = {}
#    redis = {
#      address = "blocky-redis-headless:6379"
#      password = "passwd"
#      database = 2
#      required = true
#      connectionAttempts = 10
#      connectionCooldown = "3s"
#    }
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
    "config.yml" = replace(yamlencode(local.config), "\"", "")
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
          name = var.name
          image = "${var.image}:${var.tag}"
          port {
            name = "http"
            container_port = 4000
            protocol = "TCP"
          }
          port {
            name = "dns-tcp"
            container_port = 53
            protocol = "TCP"
          }
          port {
            name = "dns-udp"
            container_port = 53
            protocol = "UDP"
          }
          env {
            name = "TZ"
            value = "UTC"
          }
          volume_mount {
            name = "config"
            mount_path = "/app/config.yml"
            sub_path = "config.yml"
          }
        }
        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.this.metadata.0.name
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
    annotations = {
      "tailscale.com/hostname" = var.expose_on_tailnet ? var.tailnet_hostname : null
    }
  }
  spec {
    type = var.expose_on_tailnet ? "LoadBalancer" : "ClusterIP"
    load_balancer_class = var.expose_on_tailnet ? "tailscale" : null
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
      port = 4000
      target_port = 4000
      protocol = "TCP"
    }
    port {
      name = "dns-tcp"
      port = 53
      target_port = 53
      protocol = "TCP"
    }
    port {
      name = "dns-udp"
      port = 53
      target_port = 53
      protocol = "UDP"
    }
  }
}
