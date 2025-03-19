output "node_cidrs" {
  value = data.external.node_cidrs.result.node_cidrs
}

output "node_tailscale_ips" {
  value = data.tailscale_device.this.addresses
}