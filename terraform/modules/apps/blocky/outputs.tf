output "endpoints" {
  value = kubernetes_service.this.spec.0.cluster_ips
}

output "tailscale_hostname" {
  value = try(kubernetes_service.this.status.0.load_balancer.0.ingress.0.hostname, null)
}
