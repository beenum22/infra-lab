output "k3s" {
  value = merge(module.lab_k3s_init, module.lab_k3s)
  sensitive = true
}
