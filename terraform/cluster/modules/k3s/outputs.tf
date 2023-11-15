output "node_token" {
  value = var.cluster_init ? trim(file("~/.kube/node-token"), "\n") : ""
  sensitive = true
}

output "api_host" {
  value = var.api_host
}

output "tailscale_ips" {
  value = data.tailscale_device.device.addresses
}
