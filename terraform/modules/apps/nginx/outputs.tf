output "endpoints" {
  value = var.expose_on_tailnet ? concat(kubernetes_service.ipv4[0].spec.0.cluster_ips, kubernetes_service.ipv6[0].spec.0.cluster_ips) : data.kubernetes_service.this[0].spec.0.cluster_ips
}

output "ipv4_endpoint" {
  value = var.expose_on_tailnet ? kubernetes_service.ipv4[0].status.0.load_balancer.0.ingress.1.ip : data.kubernetes_service.this[0].spec.0.cluster_ips[0]
}

output "ipv6_endpoint" {
  value = var.expose_on_tailnet ? kubernetes_service.ipv6[0].status.0.load_balancer.0.ingress.1.ip : data.kubernetes_service.this[0].spec.0.cluster_ips[1]
}
