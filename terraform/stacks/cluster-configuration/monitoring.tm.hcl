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
#        "netdata.moinmoin.fyi"
#      ]
#      ingress_password = null
#      storage_class = global.project.storage_class
#      ingress_hostname = global.project.ingress_hostname
#      ingress_protection = false
#      depends_on = [
#        kubernetes_namespace.monitoring
#      ]
#    }

    module "dashdot" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/dashdot"
      ingress_hostname = global.project.ingress_hostname
      issuer = global.project.cert_manager_issuer
      domains = [
        "dashdot.moinmoin.fyi"
      ]
      depends_on = [
        kubernetes_namespace.monitoring
      ]
    }

#     module "prometheus_stack" {
#       source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/prometheus-stack"
#       namespace = kubernetes_namespace.monitoring.metadata[0].name
#       issuer = module.cert_manager.issuer
#       grafana_domains = [
#         "grafana.moinmoin.fyi"
#       ]
#       prometheus_domains = [
#         "prometheus.moinmoin.fyi"
#       ]
#       grafana_password = global.secrets.grafana_password
#       storage_class = global.project.storage_class
#       ingress_hostname = global.project.ingress_hostname
#       depends_on = [
#         kubernetes_namespace.monitoring
#       ]
#     }
  }
}