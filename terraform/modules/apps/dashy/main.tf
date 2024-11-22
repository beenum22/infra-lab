locals {
  ingress_annotations = {
    "cert-manager.io/cluster-issuer" = var.issuer
    "kubernetes.io/ingress.class" = var.ingress_class
    "external-dns.alpha.kubernetes.io/internal-hostname" = join(",", var.domains)
    "external-dns.alpha.kubernetes.io/target" = var.ingress_hostname
  }
  apps = {
#     pihole = {
#       section     = "Cluster"
#       title       = "Pihole"
#       description = "DNS Server & Adblocker"
#       icon        = "hl-pihole"
#       url         = "https://pihole.moinmoin.fyi/admin"
#       status_check = true
#     }
#     netdata = {
#       section     = "Cluster"
#       title       = "Netdata"
#       description = "Monitoring Dashboard"
#       icon        = "hl-netdata"
#       url         = "https://netdata.moinmoin.fyi"
#       status_check = true
#     }
#     grafana = {
#       section     = "Cluster"
#       title       = "Grafana"
#       description = "Monitoring Dashboard"
#       icon        = "hl-grafana"
#       url         = "https://grafana.moinmoin.fyi"
#       status_check = true
#     }
#     prometheus = {
#       section     = "Cluster"
#       title       = "Prometheus"
#       description = "Time Series Database"
#       icon        = "hl-prometheus"
#       url         = "https://prometheus.moinmoin.fyi"
#       status_check = true
#     }
#     jellyfin = {
#       section = "Apps"
#       title = "Jellyfin"
#       description = "Media Server"
#       icon = "hl-jellyfin"
#       url = "https://jellyfin.moinmoin.fyi"
#       status_check: true
#     }
    filebrowser = {
      section = "Apps"
      title = "Filebrowser"
      description = "Shared File Storage"
      icon = "hl-filebrowser"
      url = "https://filebrowser.moinmoin.fyi"
      status_check: true
    }
#     jitsi = {
#       section = "Apps"
#       title = "Jitsi Meet"
#       description = "Video Calling Service"
#       icon = "hl-jitsi"
#       url = "https://jitsi.moinmoin.fyi"
#       status_check: true
#     }
    homebox = {
      section = "Apps"
      title = "Homebox"
      description = "Inventory Management"
      icon = "hl-homebox"
      url = "https://homebox.moinmoin.fyi"
      status_check: true
    }
#     radarr = {
#       section = "Apps"
#       title = "Radarr"
#       description = "Movie Collection Manager"
#       icon = "hl-radarr"
#       url = "https://radarr.moinmoin.fyi"
#       status_check: true
#     }
#     prowlarr = {
#       section = "Apps"
#       title = "Prowlarr"
#       description = "Media Sources Index Manager"
#       icon = "hl-prowlarr"
#       url = "https://prowlarr.moinmoin.fyi"
#       status_check: true
#     }
    dashdot-oci-fra-0 = {
      section     = "Cluster"
      title       = "Dash. oci-fra-0"
      description = "Simple Node Monitoring Dashboard"
      icon        = "hl-dashdot"
      url         = "https://oci-fra-0.dashdot.moinmoin.fyi"
      status_check = true
    }
    dashdot-oci-fra-1 = {
      section     = "Cluster"
      title       = "Dash. oci-fra-1"
      description = "Simple Node Monitoring Dashboard"
      icon        = "hl-dashdot"
      url         = "https://oci-fra-1.dashdot.moinmoin.fyi"
      status_check = true
    }
    dashdot-oci-fra-2 = {
      section     = "Cluster"
      title       = "Dash. oci-fra-2"
      description = "Simple Node Monitoring Dashboard"
      icon        = "hl-dashdot"
      url         = "https://oci-fra-2.dashdot.moinmoin.fyi"
      status_check = true
    }
    dashdot-hzn-hel-0 = {
      section     = "Cluster"
      title       = "Dash. hzn-hel-0"
      description = "Simple Node Monitoring Dashboard"
      icon        = "hl-dashdot"
      url         = "https://hzn-hel-0.dashdot.moinmoin.fyi"
      status_check = true
    }
    dashdot-netcup-neu-0 = {
      section     = "Cluster"
      title       = "Dash. netcup-neu-0"
      description = "Simple Node Monitoring Dashboard"
      icon        = "hl-dashdot"
      url         = "https://netcup-neu-0.dashdot.moinmoin.fyi"
      status_check = true
    }
  }
  sections = distinct([
    for app, info in local.apps : info.section
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
    items = [
      {
        title       = "Backblaze"
        description = "S3 Backup Provider"
        icon        = "hl-backblaze"
        url         = "https://secure.backblaze.com/b2_buckets.htm"
        target      = "newtab"
        id          = "0_2647_backblaze"
      },
      {
        title       = "Hetzner"
        description = "VM Provider"
        icon        = "hl-hetzner"
        target      = "newtab"
        id          = "1_2647_hetzner"
      },
      {
        title       = "Oracle"
        description = "VM Provider"
        icon        = "hl-oracle"
        target      = "newtab"
        url         = "https://cloud.oracle.com/?region=eu-frankfurt-1"
        id          = "2_2647_oracle"
      },
      {
        title       = "Bytehosting"
        description = "VM Provider"
        icon        = "https://bytehosting.cloud/white.png"
        target      = "newtab"
        url         = "https://panel.bytehosting.cloud/"
        id          = "3_2647_bytehosting"
      },
      {
        title       = "Netcup"
        description = "VM Provider"
        icon        = "https://www.svgrepo.com/show/331493/netcup.svg"
        target      = "newtab"
        url         = "https://www.customercontrolpanel.de/produkte.php"
        provider    = "Netcup"
        id          = "4_2647_netcup"
      },
      {
        title       = "Regxa"
        description = "VPS Provider"
        icon        = "https://regxa.com/__logo.svg"
        target      = "newtab"
        url         = "https://my.regxa.com/clientarea.php"
        provider    = "Regxa"
        id          = "5_2647_regxa"
      },
      {
        title       = "Tailscale"
        description = "Mesh VPN Provider"
        icon        = "hl-tailscale"
        url         = "https://login.tailscale.com/admin"
        target      = "newtab"
        provider    = "Tailscale"
        id          = "6_2647_tailscale"
      },
      {
        title       = "OVH Cloud"
        description = "Public Domain Provider"
        icon        = "hl-ovh"
        url         = "https://www.ovh.com/manager/#/web/domain/moinmoin.fyi/zone"
        target      = "newtab"
        provider    = "OVH"
        id          = "7_2647_ovh"
      },
      {
        title       = "Github Repo"
        description = "Github Repo hosting the IaC"
        icon        = "hl-github"
        url         = "https://github.com/beenum22/pi-pi"
        target      = "newtab"
        provider    = "Github"
        id          = "8_2647_git"
      }
    ]
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
#    {
#      name        = "Service Providers"
#      displayData = {
#        sortBy        = "default"
#        rows          = 1
#        cols          = 1
#        collapsed     = true
#        hideForGuests = false
#      }
#      widgets = [
#        {
#          type = "iframe"
#          options = {
#            url = "https://bytehosting.cloud"
#          }
#        },
#      ]
#    }
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
      items = [
        for app_key, app in local.apps : {
          title       = app.title
          description = app.description
          icon        = app.icon
          url         = app.url
          target      = "newtab"
          statusCheck = app.status_check
          id          = "${index(local.sections, section)}_${app_key}"
        } if app.section == section
      ]
    }
  ]
  dashy_config = {
    pageInfo = {
      title = var.page_config.title
      description = var.page_config.description
      navLinks = [
#        {
#          title = "Test"
#          path = "Test"
#          target = "newtab"
#        }
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
