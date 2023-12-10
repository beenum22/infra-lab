resource "random_string" "k3s_token" {
  length           = 16
  special          = true
  override_special = "/@£$"
}

resource "random_password" "k3s_secret" {
  length           = 16
  special          = true
}

module "lab_k3s_init" {
  source = "./modules/k3s"
  for_each = { for instance, info in local.instances: instance => info if info.k3s_root_node == true }
  k3s_version = each.value.k3s_version
  hostname = each.value.hostname
  cluster_init = each.value.k3s_init
  cluster_role = each.value.k3s_role
  root_node = each.value.k3s_root_node
  api_host = each.value.host
  token = nonsensitive(random_password.k3s_secret.result)
  kubeconfig = null
  copy_kubeconfig = each.value.k3s_copy_kubeconfig
  node_labels = each.value.k3s_node_labels
  tailnet = var.tailscale_tailnet
  connection_info = {
    user = each.value.user
    host = each.value.host
    private_key = data.terraform_remote_state.infra.outputs.ssh_private_key
  }
}

module "lab_k3s" {
  source = "./modules/k3s"
  for_each = { for instance, info in local.instances: instance => info if info.k3s_init == false && info.k3s_root_node == false }
  k3s_version = each.value["k3s_version"]
  hostname = each.value["hostname"]
  cluster_init = each.value["k3s_init"]
  root_node = each.value["k3s_root_node"]
  copy_kubeconfig = each.value["k3s_copy_kubeconfig"]
  cluster_role = each.value["k3s_role"]
  node_labels = each.value["k3s_node_labels"]
  kubeconfig = module.lab_k3s_init["lab-k3s-0"].kubeconfig
  token = nonsensitive(random_password.k3s_secret.result)
  api_host = module.lab_k3s_init["lab-k3s-0"].api_host
  tailnet = var.tailscale_tailnet
  connection_info = {
    user = each.value["user"]
    host = each.value["host"]
    private_key = data.terraform_remote_state.infra.outputs.ssh_private_key
  }
}
