output "k3s_node_cidrs" {
  value = {for node, outputs in merge(module.lab_k3s_init, module.lab_k3s) : node => outputs["node_cidrs"]}
}

output "k3s_kubeconfig" {
  value = module.lab_k3s_init["lab-k3s-0"].kubeconfig
  sensitive = true
}
