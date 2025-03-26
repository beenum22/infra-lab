generate_hcl "_dns.tf" {
  lets {
    public_hostnames = global.apps.public_hostnames
    private_hostnames = global.apps.private_hostnames
  }

  content {
    resource "kubernetes_namespace" "dns" {
      metadata {
        name = "dns"
      }
    }

#    module "pihole" {
#      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/pihole"
#      namespace = kubernetes_namespace.dns.metadata.0.name
#      expose = true
#      domains = [
#        "pihole.moinmoin.fyi"
#      ]
#      password = global.secrets.pihole_password
#      ingress_class = global.project.ingress_class
#      ingress_hostname = global.project.ingress_hostname
#      issuer = module.cert_manager.issuer
#      storage_class = global.project.storage_class
#      depends_on = [
#        kubernetes_namespace.dns
#      ]
#    }

#    module "external_dns" {
#      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/external-dns"
#      namespace = kubernetes_namespace.dns.metadata.0.name
#      pihole_server = "http://pihole-web.dns.svc.cluster.local"
#      pihole_password = global.secrets.pihole_password
#      depends_on = [
#        kubernetes_namespace.dns,
#        module.pihole
#      ]
#    }

    data "kubernetes_service" "cluster_dns" {
      metadata {
        name = "kube-dns"
        namespace = "kube-system"
      }
    }

    module "blocky" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/blocky"
      namespace = kubernetes_namespace.dns.metadata.0.name
      domains = [
        "blocky.cluster.moinmoin.fyi"
      ]
      ingress_class = global.project.ingress_class
      ingress_hostname = global.project.ingress_hostname
      issuer = module.cert_manager.issuer
      expose_on_tailnet = true
      tailnet_hostname = "talos-blocky"
      conditional_mappings = {
        "cluster.local" = data.kubernetes_service.cluster_dns.spec.0.cluster_ip
      }
      custom_dns_rewrites = {}
      custom_dns_mappings = {
#         "wormhole.tail03622.ts.net" = join(",", data.tailscale_device.nginx.0.addresses)
      }
      depends_on = [
        kubernetes_namespace.dns
      ]
    }

    resource "cloudflare_record" "private_a" {
      for_each = toset(flatten([
        for app, info in local.apps : info.hostnames if info.public == false && info.enable == true
      ]))
      zone_id = global.infrastructure.cloudflare.zone_id
      name    = each.key
      value   = module.nginx.ipv4_endpoint
      type    = "A"
      proxied = false
    }

    resource "cloudflare_record" "private_aaaa" {
      for_each = toset(flatten([
        for app, info in local.apps : info.hostnames if info.public == false && info.enable == true
      ]))
      zone_id = global.infrastructure.cloudflare.zone_id
      name    = each.key
      value   = module.nginx.ipv6_endpoint
      type    = "AAAA"
      proxied = false
    }

    resource "cloudflare_record" "public_cname_records" {
      for_each = toset(flatten([
        for app, info in local.apps : info.hostnames if info.public == true && info.enable == true
      ]))
      zone_id = global.infrastructure.cloudflare.zone_id
      name    = each.key
      value   = module.cloudflared.tunnel_hostname
      type    = "CNAME"
      proxied = true
    }

    resource "tailscale_dns_nameservers" "this" {
      nameservers = module.blocky.endpoints
    }

    output "dns_servers" {
      value = module.blocky.endpoints
    }
  }
}