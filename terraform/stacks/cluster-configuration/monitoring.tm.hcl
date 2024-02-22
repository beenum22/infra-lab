generate_hcl "_monitoring.tf" {
  content {
    resource "kubernetes_namespace" "monitoring" {
      metadata {
        name = "monitoring"
      }
    }

#    module "netdata" {
#      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/netdata"
#      namespace = kubernetes_namespace.monitoring.metadata[0].name
#      issuer = module.cert_manager.issuer
#      domains = [
#        "netdata.dera.ovh"
#      ]
#      ingress_password = null
#      storage_class = global.project.storage_class
#      ingress_hostname = global.project.ingress_hostname
#      ingress_protection = false
#      depends_on = [
#        kubernetes_namespace.monitoring
#      ]
#    }

    module "prometheus_stack" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/prometheus-stack"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
      issuer = module.cert_manager.issuer
      grafana_domains = [
        "grafana.dera.ovh"
      ]
      prometheus_domains = [
        "prometheus.dera.ovh"
      ]
      grafana_password = global.secrets.grafana_password
#      ingress_password = null
      storage_class = global.project.storage_class
      ingress_hostname = global.project.ingress_hostname
#      ingress_protection = false
      depends_on = [
        kubernetes_namespace.monitoring
      ]
    }

    #    module "grafana" {
    #      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/grafana"
    #      namespace = kubernetes_namespace.monitoring.metadata[0].name
    #      issuer = module.cert_manager.issuer
    #      domains = [
    #        "grafana.dera.ovh"
    #      ]
    #      ingress_hostname = global.project.ingress_hostname
    #      password = global.secrets.grafana_password
    #      data_sources = [
    #        {
    #          name = "Netdata"
    #          type = "netadata"
    #          url = "netdata.dera.ovh"
    #          plugin = "netdatacloud-netdata-datasource"
    #        }
    #      ]
    #      depends_on = [
    #        kubernetes_namespace.monitoring
    #      ]
    #    }
  }
}