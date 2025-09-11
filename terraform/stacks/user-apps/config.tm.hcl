globals "terraform" {
  providers = [
    "helm",
    "kubernetes",
    "cloudflare",
  ]

  remote_states = {
    stacks = [
      "cluster-configuration"
    ]
  }
}

generate_hcl "_apps.tf" {
  content {
    locals {
      apps = global.cluster.apps
    }
    resource "kubernetes_namespace" "apps" {
      metadata {
        name = "apps"
        labels = {
          "pod-security.kubernetes.io/enforce" = "privileged"
        }
      }
    }

    # resource "kubernetes_persistent_volume_claim" "nfs_misc" {
    #   metadata {
    #     name = "nfs-misc"
    #     namespace = kubernetes_namespace.apps.metadata[0].name
    #     labels = {
    #       "app.kubernetes.io/name" = "nfs-misc"
    #     }
    #   }
    #   spec {
    #     access_modes = ["ReadWriteMany"]
    #     resources {
    #       requests = {
    #         storage = "10Gi"
    #       }
    #     }
    #     storage_class_name = "openebs-kernel-nfs"
    #   }
    # }

    # resource "kubernetes_persistent_volume_claim" "nfs_media" {
    #   metadata {
    #     name = "nfs-media"
    #     namespace = kubernetes_namespace.apps.metadata[0].name
    #     labels = {
    #       "app.kubernetes.io/name" = "nfs-media"
    #     }
    #   }
    #   spec {
    #     access_modes = ["ReadWriteMany"]
    #     resources {
    #       requests = {
    #         storage = "30Gi"
    #       }
    #     }
    #     storage_class_name = "openebs-kernel-nfs"
    #   }
    # }

    module "jellyfin" {
      count = global.cluster.apps.jellyfin.enable ? 1 : 0
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/jellyfin"
      flux_managed = true
      chart_version = "2.*.*"
      namespace = kubernetes_namespace.apps.metadata[0].name
      ingress_hostname = global.project.ingress_hostname
      issuer = global.project.cert_manager_issuer
      node_selectors = {
        "${global.project.domain}/country" = "germany"
      }
      config_storage = "5Gi"
      data_storage = "10Gi"
      storage_class = global.project.storage_class
      shared_pvcs = []
      domains = global.cluster.apps.jellyfin.hostnames
      oidc_client = {
        id = "jellyfin"
        secret = global.secrets.oidc.jellyfin.secret
        provider_name = "authelia"
        provider_endpoint  = global.project.oidc_hostname
        admin_roles        = ["jellyfin-admins"]
        user_roles         = ["jellyfin-admins", "jellyfin-users"]
      }
      live_tv = {
        enabled = true
        m3u_url = "https://iptv-org.github.io/iptv/index.m3u"
        user_agent = "Jellyfin"
      }
      depends_on = [kubernetes_namespace.apps]
    }

    resource "cloudflare_dns_record" "jellyfin" {
      for_each = toset(local.apps.jellyfin.enable ? local.apps.jellyfin.hostnames : [])
      zone_id = global.infrastructure.cloudflare.zone_id
      name    = each.value
      content   = local.apps.jellyfin.public ? data.terraform_remote_state.cluster_configuration_stack_state.outputs.ingress_endpoints.public : data.terraform_remote_state.cluster_configuration_stack_state.outputs.ingress_endpoints.private
      type    = "CNAME"
      proxied = local.apps.jellyfin.public ? true : false
      ttl     = local.apps.jellyfin.public ? "1" : "60"
    }

    module "dashy" {
      count = global.cluster.apps.dashy.enable ? 1 : 0
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/dashy"
      namespace = kubernetes_namespace.apps.metadata[0].name
      ingress_hostname = global.project.ingress_hostname
      issuer = global.project.cert_manager_issuer
      domains = global.cluster.apps.dashy.hostnames
      service_providers = [
        {
          title       = "Backblaze"
          description = "S3 Backup Provider"
          icon        = "hl-backblaze"
          url         = "https://secure.backblaze.com/b2_buckets.htm"
          # target      = "newtab"
          # id          = "0_2647_backblaze"
        },
        {
          title       = "Hetzner"
          description = "VM Provider"
          icon        = "hl-hetzner"
          url         = "https://console.hetzner.cloud/projects"
          # target      = "newtab"
          # id          = "1_2647_hetzner"
        },
        {
          title       = "Oracle"
          description = "VM Provider"
          icon        = "hl-oracle"
          # target      = "newtab"
          url         = "https://cloud.oracle.com/?region=eu-frankfurt-1"
          # id          = "2_2647_oracle"
        },
        # {
        #   title       = "Bytehosting"
        #   description = "VM Provider"
        #   icon        = "https://bytehosting.cloud/white.png"
        #   target      = "newtab"
        #   url         = "https://panel.bytehosting.cloud/"
        #   id          = "3_2647_bytehosting"
        # },
        {
          title       = "Netcup"
          description = "VM Provider"
          icon        = "https://www.svgrepo.com/show/331493/netcup.svg"
          # target      = "newtab"
          url         = "https://www.customercontrolpanel.de/produkte.php"
          provider    = "Netcup"
          # id          = "4_2647_netcup"
        },
        # {
        #   title       = "Regxa"
        #   description = "VPS Provider"
        #   icon        = "https://regxa.com/__logo.svg"
        #   target      = "newtab"
        #   url         = "https://my.regxa.com/clientarea.php"
        #   provider    = "Regxa"
        #   id          = "5_2647_regxa"
        # },
        {
          title       = "Tailscale"
          description = "Mesh VPN Provider"
          icon        = "hl-tailscale"
          url         = "https://login.tailscale.com/admin"
          # target      = "newtab"
          provider    = "Tailscale"
          # id          = "6_2647_tailscale"
        },
        {
          title       = "OVH Cloud"
          description = "Public Domain Provider"
          icon        = "hl-ovh"
          url         = "https://www.ovh.com/manager/#/web/domain/${global.project.domain}/zone"
          # target      = "newtab"
          provider    = "OVH"
          # id          = "7_2647_ovh"
        },
        {
          title       = "Github Repo"
          description = "Github Repo hosting the IaC"
          icon        = "hl-github"
          url         = "https://github.com/beenum22/pi-pi"
          provider    = "Github"
        },
        {
          title       = "Cloudflare"
          description = "DNS Provider and Public Gateway"
          icon        = "hl-cloudflare"
          url         = "https://dash.cloudflare.com/"
          provider    = "Cloudflare"
        },
        {
          title       = "Porkbun"
          description = "Domain Name Registrar"
          icon        = "hl-porkbun"
          url         = "https://porkbun.com/account/domainsSpeedy"
          provider    = "Porkbun"
        }
      ]
      apps = [
        {
          title = "Filebrowser"
          description = "Shared File Storage"
          icon = "hl-filebrowser"
          url = "https://filebrowser.cluster.${global.project.domain}"
          statusCheck = true
          section = "Apps"
        },
        {
          section = "Apps"
          title = "Homebox"
          description = "Inventory Management"
          icon = "hl-homebox"
          url = "https://homebox.cluster.${global.project.domain}"
          statusCheck = true
        },
        {
          section = "Apps"
          title = "HTTP Echo"
          description = "Test Public HTTP Echo Server"
          icon = "hl-ghostfolio"
          url = "https://echo.${global.project.domain}"
          statusCheck = true
        },
        {
          section = "Apps"
          title = "Jellyfin"
          description = "Media Streaming Server"
          icon = "hl-jellyfin"
          url = "https://jellyfin.${global.project.domain}"
          statusCheck = true
        },
        {
          section     = "Cluster"
          title       = "Headlamp"
          description = "Kubernetes Dashboard"
          icon        = "hl-headlamp"
          url         = "https://headlamp.cluster.${global.project.domain}"
          statusCheck = true
        },
        {
          section     = "Cluster"
          title       = "Dash. oci-fra-0"
          description = "Simple Node Monitoring Dashboard"
          icon        = "hl-dashdot"
          url         = "https://oci-fra-0.dashdot.cluster.${global.project.domain}"
          statusCheck = true
        },
        {
          section     = "Cluster"
          title       = "Dash. oci-fra-1"
          description = "Simple Node Monitoring Dashboard"
          icon        = "hl-dashdot"
          url         = "https://oci-fra-1.dashdot.cluster.${global.project.domain}"
          statusCheck = true
        },
        {
          section     = "Cluster"
          title       = "Dash. oci-fra-2"
          description = "Simple Node Monitoring Dashboard"
          icon        = "hl-dashdot"
          url         = "https://oci-fra-2.dashdot.cluster.${global.project.domain}"
          statusCheck = true
        },
        {
          section     = "Cluster"
          title       = "Dash. hzn-hel-0"
          description = "Simple Node Monitoring Dashboard"
          icon        = "hl-dashdot"
          url         = "https://hzn-hel-0.dashdot.cluster.${global.project.domain}"
          statusCheck = true
        },
        {
          section     = "Cluster"
          title       = "Dash. netcup-neu-0"
          description = "Simple Node Monitoring Dashboard"
          icon        = "hl-dashdot"
          url         = "https://netcup-neu-0.dashdot.cluster.${global.project.domain}"
          statusCheck = true
        },
      ]
      depends_on = [kubernetes_namespace.apps]
    }

    resource "cloudflare_dns_record" "dashy" {
      for_each = toset(local.apps.dashy.enable ? local.apps.dashy.hostnames : [])
      zone_id = global.infrastructure.cloudflare.zone_id
      name    = each.value
      content   = local.apps.dashy.public ? data.terraform_remote_state.cluster_configuration_stack_state.outputs.ingress_endpoints.public : data.terraform_remote_state.cluster_configuration_stack_state.outputs.ingress_endpoints.private
      type    = "CNAME"
      proxied = local.apps.dashy.public ? true : false
      ttl     = local.apps.dashy.public ? "1" : "60"
    }

    module "filebrowser" {
      count = global.cluster.apps.filebrowser.enable ? 1 : 0
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/filebrowser"
      namespace = kubernetes_namespace.apps.metadata[0].name
      admin_password = global.secrets.filebrowser_password
      issuer = global.project.cert_manager_issuer
      domains = global.cluster.apps.filebrowser.hostnames
      ingress_hostname = global.project.ingress_hostname
      data_storage = "16Gi"
      data_storage_class = "openebs-zfs"
      config_storage = "1Gi"
      config_storage_class = global.project.storage_class
      shared_pvcs = [
      #  kubernetes_persistent_volume_claim.nfs_media.metadata.0.name,
      #  kubernetes_persistent_volume_claim.nfs_misc.metadata.0.name
      ]
      depends_on = [kubernetes_namespace.apps]
    }

    resource "cloudflare_dns_record" "filebrowser" {
      for_each = toset(local.apps.filebrowser.enable ? local.apps.filebrowser.hostnames : [])
      zone_id = global.infrastructure.cloudflare.zone_id
      name    = each.value
      content   = local.apps.filebrowser.public ? data.terraform_remote_state.cluster_configuration_stack_state.outputs.ingress_endpoints.public : data.terraform_remote_state.cluster_configuration_stack_state.outputs.ingress_endpoints.private
      type    = "CNAME"
      proxied = local.apps.filebrowser.public ? true : false
      ttl     = local.apps.filebrowser.public ? "1" : "60"
    }

    module "homebox" {
      count = global.cluster.apps.homebox.enable ? 1 : 0
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/homebox"
      namespace = kubernetes_namespace.apps.metadata[0].name
      ingress_hostname = global.project.ingress_hostname
      issuer = global.project.cert_manager_issuer
      storage_size = "10Gi"
      storage_class = global.project.storage_class
      domains = global.cluster.apps.homebox.hostnames
      depends_on = [kubernetes_namespace.apps]
    }

    resource "cloudflare_dns_record" "homebox" {
      for_each = toset(local.apps.homebox.enable ? local.apps.homebox.hostnames : [])
      zone_id = global.infrastructure.cloudflare.zone_id
      name    = each.value
      content   = local.apps.homebox.public ? data.terraform_remote_state.cluster_configuration_stack_state.outputs.ingress_endpoints.public : data.terraform_remote_state.cluster_configuration_stack_state.outputs.ingress_endpoints.private
      type    = "CNAME"
      proxied = local.apps.homebox.public ? true : false
      ttl     = local.apps.homebox.public ? "1" : "60"
    }

    module "http_echo" {
      count = global.cluster.apps.http_echo.enable ? 1 : 0
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/http-echo"
      namespace = kubernetes_namespace.apps.metadata[0].name
      issuer = global.project.cert_manager_issuer
      domains = global.cluster.apps.http_echo.hostnames
      ingress_class = "nginx"
      ingress_hostname = global.project.ingress_hostname
      depends_on = [kubernetes_namespace.apps]
    }

    resource "cloudflare_dns_record" "http_echo" {
      for_each = toset(local.apps.http_echo.enable ? local.apps.http_echo.hostnames : [])
      zone_id = global.infrastructure.cloudflare.zone_id
      name    = each.value
      content   = local.apps.http_echo.public ? data.terraform_remote_state.cluster_configuration_stack_state.outputs.ingress_endpoints.public : data.terraform_remote_state.cluster_configuration_stack_state.outputs.ingress_endpoints.private
      type    = "CNAME"
      proxied = local.apps.http_echo.public ? true : false
      ttl     = local.apps.http_echo.public ? "1" : "60"
    }

    module "honeygain" {
      count = global.cluster.apps.honeygain.enable ? 1 : 0
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/honeygain"
      namespace = kubernetes_namespace.apps.metadata[0].name
      account_name = global.secrets.honeygain.account_name
      account_password = global.secrets.honeygain.account_password
      node_selector = {
        "${global.project.domain}/residential-ip" = true
      }
      depends_on = [kubernetes_namespace.apps]
    }

    module "stockseer" {
      count = global.cluster.apps.stockseer.enable ? 1 : 0
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/stockseer"
      flux_managed = true
      namespace = kubernetes_namespace.apps.metadata[0].name
      issuer = global.project.cert_manager_issuer
      domains = global.cluster.apps.stockseer.hostnames
      tag = "v0.1.16"
      depends_on = [kubernetes_namespace.apps]
    }

    resource "cloudflare_dns_record" "stockseer" {
      for_each = toset(local.apps.stockseer.enable ? local.apps.stockseer.hostnames : [])
      zone_id = global.infrastructure.cloudflare.zone_id
      name    = each.value
      content   = local.apps.stockseer.public ? data.terraform_remote_state.cluster_configuration_stack_state.outputs.ingress_endpoints.public : data.terraform_remote_state.cluster_configuration_stack_state.outputs.ingress_endpoints.private
      type    = "CNAME"
      proxied = local.apps.stockseer.public ? true : false
      ttl     = local.apps.stockseer.public ? "1" : "60"
    }

    # TODO: Uncomment and review whenever you have time.
    # resource "kubernetes_manifest" "backups" {
    #   for_each = toset(global.apps.backups)
    #   manifest = {
    #     "apiVersion" = "velero.io/v1"
    #     "kind" = "Schedule"
    #     "metadata" = {
    #       "name" = each.value
    #       "namespace" = "backup"
    #     }
    #     "spec" = {
    #       "schedule" = "5 0 * * *"
    #       "template" = {
    #         "includedNamespaces" = [
    #           kubernetes_namespace.apps.metadata.0.name
    #         ]
    #         "labelSelector" = {
    #           "matchLabels" = {
    #             "app.kubernetes.io/name" = each.value
    #           }
    #         }
    #         "snapshotVolumes" = true
    #         "storageLocation" = "default"
    #         "volumeSnapshotLocations" = ["default"]
    #         "ttl" = "168h"
    #       }
    #     }
    #   }
    # }
  }
}
