resource "random_string" "k3s_token" {
  length           = 16
  special          = true
  override_special = "/@£$"
}

module "lab_k3s_init" {
  source = "./modules/k3s"
  k3s_version = local.instances.lab-k3s-0.k3s_version
  hostname = local.instances.lab-k3s-0.hostname
  cluster_init = local.instances.lab-k3s-0.k3s_init
  copy_kubeconfig = local.instances.lab-k3s-0.k3s_copy_kubeconfig
  cluster_role = local.instances.lab-k3s-0.k3s_role
  node_labels = local.instances.lab-k3s-0.k3s_node_labels
  token = random_string.k3s_token.result
  tailscale_authkey = "tskey-auth-k6rWmo6CNTRL-ViFCSCmvYR4KPyCvHXWfR4aBvLzdvj5FT"
  tailnet = var.tailscale_tailnet
  connection_info = {
    user = local.instances.lab-k3s-0.user
    host = local.instances.lab-k3s-0.host
    private_key = sensitive(file("~/.ssh/id_rsa"))
  }
  use_ipv6 = true
}

module "lab_k3s" {
  source = "./modules/k3s"
  for_each = { for instance, info in local.instances: instance => info if info.k3s_init == false }
  k3s_version = each.value["k3s_version"]
  hostname = each.value["hostname"]
  cluster_init = each.value["k3s_init"]
  copy_kubeconfig = each.value["k3s_copy_kubeconfig"]
  cluster_role = each.value["k3s_role"]
  node_labels = each.value["k3s_node_labels"]
  token = module.lab_k3s_init.node_token
  api_host = module.lab_k3s_init.tailscale_ips[1]
  tailscale_authkey = "tskey-auth-k6rWmo6CNTRL-ViFCSCmvYR4KPyCvHXWfR4aBvLzdvj5FT"
  tailnet = var.tailscale_tailnet
  connection_info = {
    user = each.value["user"]
    host = each.value["host"]
    private_key = sensitive(file("~/.ssh/id_rsa"))
  }
  use_ipv6 = true
}
