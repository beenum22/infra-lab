output "dns_services" {
  value = {
    udp = join(",", data.kubernetes_service.udp.spec.0.cluster_ips)
    tcp = join(",", data.kubernetes_service.tcp.spec.0.cluster_ips)
    dhcp = join(",", data.kubernetes_service.dhcp.spec.0.cluster_ips)
    web = join(",", data.kubernetes_service.web.spec.0.cluster_ips)
  }
}
