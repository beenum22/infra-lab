output "ips" {
  value = data.kubernetes_service.ingress.spec[0]["cluster_ips"]
}

output "lb_hostname" {
  value = var.expose_on_tailnet ? data.kubernetes_service.ingress.status.0.load_balancer.0.ingress.0.hostname : null
}

output "lb_ip" {
  value = var.expose_on_tailnet ? data.kubernetes_service.ingress.status.0.load_balancer.0.ingress.1.ip : null
}
