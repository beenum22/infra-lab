output "ips" {
  value = data.kubernetes_service.ingress.spec[0]["cluster_ips"]
}
