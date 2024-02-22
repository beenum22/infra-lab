output "endpoints" {
  value = kubernetes_service.this.spec.0.cluster_ips
}