# TODO: This looks confusing and might need refactoring
output "endpoints" {
  value = var.expose_on_tailnet ? kubernetes_service.this[0].spec.0.cluster_ips : data.kubernetes_service.this[0].spec.0.cluster_ips
}

output "endpoint" {
  value = var.expose_on_tailnet ? kubernetes_service.this[0].status.0.load_balancer.0.ingress.0.hostname : "${data.kubernetes_service.this[0].metadata.0.name}.${data.kubernetes_service.this[0].metadata.0.namespace}.svc.cluster.local"
}
