#output "k3s" {
#  value = merge(module.lab_k3s_init, module.lab_k3s)
#  sensitive = true
#}

#output "test" {
#  value = module.lab_k3s_init.kubeconfig
#}