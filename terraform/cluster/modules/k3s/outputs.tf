output "node_token" {
  value = try(trimspace(ssh_resource.node_token[0].result), null)
  sensitive = true
}

output "api_host" {
  value = var.api_host
}

output "node_cidrs" {
  value = trimspace(ssh_resource.node_cidrs.result)
}

output "kubeconfig" {
  value = try(replace(trimspace(ssh_resource.copy_kubeconfig[0].result), "127.0.0.1", var.api_host), null)
  sensitive = true
}