generate_hcl "_dns.tf" {
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
#        "pihole.dera.ovh"
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

    module "blocky" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/blocky"
      namespace = kubernetes_namespace.dns.metadata.0.name
      domains = [
        "blocky.dera.ovh"
      ]
      ingress_class = global.project.ingress_class
      ingress_hostname = global.project.ingress_hostname
      issuer = module.cert_manager.issuer
      conditional_mappings = {
        "cluster.local" = "10.43.0.10"
      }
      custom_dns_rewrites = {}
      custom_dns_mappings = {
        "dashy.dera.ovh" = join(",", module.nginx.ips)
        "filebrowser.dera.ovh" = join(",", module.nginx.ips)
        "homebox.dera.ovh" = join(",", module.nginx.ips)
        "prometheus.dera.ovh" = join(",", module.nginx.ips)
        "grafana.dera.ovh" = join(",", module.nginx.ips)
      }
      depends_on = [
        kubernetes_namespace.dns
      ]
    }

    output "dns_servers" {
      value = module.blocky.endpoints
    }
  }
}