output "endpoint" {
  value = var.expose_on_tailnet ? kubernetes_service.ts[0].status.0.load_balancer.0.ingress.1.hostname : "${kubernetes_service.cluster_ip[0].metadata.0.name}.${kubernetes_service.cluster_ip[0].metadata.0.namespace}.svc.cluster.local"
}

output "tailscale_hostname" {
  value = var.expose_on_tailnet ? var.tailnet_hostname : null
}
