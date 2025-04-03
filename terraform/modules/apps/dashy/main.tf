locals {
  ingress_annotations = {
    "cert-manager.io/cluster-issuer" = var.issuer
    "kubernetes.io/ingress.class" = var.ingress_class
    "external-dns.alpha.kubernetes.io/internal-hostname" = join(",", var.domains)
    "external-dns.alpha.kubernetes.io/target" = var.ingress_hostname
  }
  sections = distinct([
    for app in var.apps : app.section
  ])
  providers_section = [{
    name        = "Service Provider Dashboards"
    displayData = {
      sortBy        = "default"
      rows          = 1
      cols          = 1
      collapsed     = false
      hideForGuests = true
    }
    items = [for i, provider in var.service_providers : merge(provider, {
      id = "providers_${i}"
      target = "newtab"
    })]
  }]
  widgets_section = [
    {
      name        = "Public IP"
      displayData = {
        sortBy        = "default"
        rows          = 1
        cols          = 2
        collapsed     = true
        hideForGuests = false
      }
      widgets = [
        {
          type = "public-ip"
        },
      ]
    },
    {
      name        = "Public IP Blacklist Check"
      displayData = {
        sortBy        = "default"
        rows          = 1
        cols          = 1
        collapsed     = true
        hideForGuests = false
      }
      widgets = [
        {
          type = "blacklist-check"
          options = {
            apiKey = "<expunged>"
          }
        },
      ]
    },
    {
      name        = "Cert-manager Releases"
      displayData = {
        sortBy        = "default"
        rows          = 1
        cols          = 2
        collapsed     = true
        hideForGuests = false
      }
      widgets = [
        {
          type = "rss-feed"
          options = {
            rssURL = "https://github.com/cert-manager/cert-manager/releases.atom"
            apiKey = "<expunged>"
          }
        },
      ]
    },
  ]
  dashy_sections = [
    for section in local.sections : {
      name = section
      displayData = {
        sortBy        = "default"
        rows          = 1
        cols          = 1
        collapsed     = false
        hideForGuests = false
      }
      items = [for i, app in var.apps : merge(app, {
        id = "apps_${i}"
        target = "newtab"
      }) if app.section == section ]
    }
  ]
  dashy_config = {
    pageInfo = {
      title = var.page_config.title
      description = var.page_config.description
      navLinks = [
      ]
    }
    appConfig = {
      theme = var.page_config.theme
      layout =  "auto"
      iconSize = "large"
      language = "en"
    }
    sections = concat(local.dashy_sections, local.providers_section, local.widgets_section)
  }
}

resource "kubernetes_config_map" "this" {
  metadata {
    name = "${var.name}-config-${sha1(jsonencode(local.dashy_config))}"
    namespace = var.namespace
  }

  data = {
    "conf.yml" = yamlencode(local.dashy_config)
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
          volume_mount {
            mount_path = "/app/public/conf.yml"
            sub_path = "conf.yml"
            name       = "config"
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
  }
  spec {
    ip_families = [
      "IPv6",
      "IPv4"
    ]
    ip_family_policy = "PreferDualStack"
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
