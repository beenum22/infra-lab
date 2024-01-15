output "api_host" {
  value = var.api_host
}

output "node_cidrs" {
  value = trimspace(ssh_resource.node_cidrs.result)
}
