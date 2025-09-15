generate_hcl "_monitoring.tf" {
  content {
    resource "kubernetes_namespace" "monitoring" {
      metadata {
        name = "monitoring"
        labels = {
          "pod-security.kubernetes.io/enforce" = "privileged"
        }
      }
    }

    module "dashdot" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/dashdot"
      count = global.cluster.apps.dashdot.enable ? 1 : 0
      namespace = kubernetes_namespace.monitoring.metadata.0.name
      ingress_hostname = global.project.ingress_hostname
      issuer = global.project.cert_manager_issuer
      domains = global.cluster.apps.dashdot.hostnames
      nodes = [for node in data.kubernetes_nodes.this.nodes : node.metadata.0.name]
      depends_on = [
        kubernetes_namespace.monitoring
      ]
    }

    resource "cloudflare_record" "dashdot_cname" {
      for_each = toset(flatten([
        for node in [for node in data.kubernetes_nodes.this.nodes : node.metadata.0.name] : node if global.cluster.apps.dashdot.enable == true && global.cluster.apps.dashdot.public == false
      ]))
      zone_id = global.infrastructure.cloudflare.zone_id
      name    = "${each.key}.${global.cluster.apps.dashdot.hostnames[0]}"
      value   = module.nginx.endpoint
      type    = "CNAME"
      proxied = false
      ttl     = "60"
    }

    module "headlamp" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/headlamp"
      count = global.cluster.apps.headlamp.enable ? 1 : 0
      flux_managed = true
      chart_version = "0.*.*"  # Use latest upstream version
      namespace = kubernetes_namespace.monitoring.metadata[0].name
      issuer = module.cert_manager.issuer
      domains = global.cluster.apps.headlamp.hostnames
      ingress_class = global.project.ingress_class
      depends_on = [
        kubernetes_namespace.monitoring
      ]
    }

    resource "cloudflare_record" "headlamp" {
      count = global.cluster.apps.headlamp.enable ? 1 : 0
      zone_id = global.infrastructure.cloudflare.zone_id
      name    = global.cluster.apps.headlamp.hostnames[0]
      value   = module.nginx.endpoint
      type    = "CNAME"
      proxied = false
      ttl     = "60"
    }
  }
}