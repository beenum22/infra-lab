output "endpoints" {
  value = var.expose_on_tailnet ? [kubernetes_service.ts_ipv4[0].status.0.load_balancer.0.ingress.1.ip, kubernetes_service.ts_ipv6[0].status.0.load_balancer.0.ingress.1.ip] : kubernetes_service.cluster_ip[0].spec.0.cluster_ips
}
