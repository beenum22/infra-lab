locals {
  prometheus_ingress_annotations = {
    "cert-manager.io/cluster-issuer" = var.issuer
    "kubernetes.io/ingress.class" = var.ingress_class
    "external-dns.alpha.kubernetes.io/internal-hostname" = join(",", var.prometheus_domains)
    "external-dns.alpha.kubernetes.io/target" = var.ingress_hostname
  }
  grafana_ingress_annotations = {
    "cert-manager.io/cluster-issuer" = var.issuer
    "kubernetes.io/ingress.class" = var.ingress_class
    "external-dns.alpha.kubernetes.io/internal-hostname" = join(",", var.grafana_domains)
    "external-dns.alpha.kubernetes.io/target" = var.ingress_hostname
  }
}

resource "helm_release" "this" {
  name       = var.name
  repository = var.chart_url
  chart      = var.chart_name
  version    = var.chart_version
  namespace   = var.namespace
  values = [
    templatefile("${path.module}/helm/values.yml.tpl", {
      ingress_class = var.ingress_class
      storage_class = var.storage_class
      grafana_password = var.grafana_password
      grafana_domains = var.grafana_domains
      grafana_tls_secret = "${var.name}-grafana-tls"
      grafana_annotations = local.grafana_ingress_annotations
      prometheus_domains = var.prometheus_domains
      prometheus_tls_secret = "${var.name}-prometheus-tls"
      prometheus_annotations = local.prometheus_ingress_annotations
      retention_period = var.retention_period
      prometheus_storage_size = var.storage_size
    }),
  ]
}
