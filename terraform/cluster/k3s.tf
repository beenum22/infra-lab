resource "random_string" "k3s_token" {
  length           = 16
  special          = true
  override_special = "/@£$"
}

module "lab_k3s_0" {
  source = "./modules/k3s"
  hostname = data.terraform_remote_state.infra.outputs.instances["lab-k3s-0"]["instance_name"]
  cluster_init = true
  cluster_role = "server"
  node_ips = {
    ipv4 = module.tailscale_lab_k3s_0.ipv4_address,
    ipv6 = module.tailscale_lab_k3s_0.ipv6_address
  }
  token = random_string.k3s_token.result
  connection_info = {
    user = data.terraform_remote_state.infra.outputs.instances["lab-k3s-0"]["instance_user"]
    host = var.use_ipv6 ? "[${local.machine_0_ip}]" : local.machine_0_ip
    private_key = sensitive(file("~/.ssh/id_rsa"))
  }
  use_ipv6 = true
  depends_on = [
    module.tailscale_lab_k3s_0
  ]
}

module "lab_k3s_1" {
  providers = {
    docker = docker.lab-k3s-1
  }
  source = "./modules/k3s"
  hostname = data.terraform_remote_state.infra.outputs.instances["lab-k3s-1"]["instance_name"]
  cluster_init = false
  cluster_role = "server"
  node_ips = {
    ipv4 = module.tailscale_lab_k3s_1.ipv4_address,
    ipv6 = module.tailscale_lab_k3s_1.ipv6_address
  }
  token = trim(file("~/.kube/node-token"), "\n")
  api_host = var.use_ipv6 ? module.tailscale_lab_k3s_0.ipv6_address : module.tailscale_lab_k3s_0.ipv4_address
  connection_info = {
    user = data.terraform_remote_state.infra.outputs.instances["lab-k3s-1"]["instance_user"]
    host = var.use_ipv6 ? "[${local.machine_1_ip}]" : local.machine_1_ip
    private_key = sensitive(file("~/.ssh/id_rsa"))
  }
  use_ipv6 = true
  depends_on = [
    module.lab_k3s_0,
    module.tailscale_lab_k3s_1
  ]
}

module "lab_k3s_2" {
  providers = {
    docker = docker.lab-k3s-2
  }
  source = "./modules/k3s"
  hostname = data.terraform_remote_state.infra.outputs.instances["lab-k3s-2"]["instance_name"]
  cluster_init = false
  cluster_role = "server"
  node_ips = {
    ipv4 = module.tailscale_lab_k3s_2.ipv4_address,
    ipv6 = module.tailscale_lab_k3s_2.ipv6_address
  }
  token = trim(file("~/.kube/node-token"), "\n")
  api_host = var.use_ipv6 ? module.tailscale_lab_k3s_0.ipv6_address : module.tailscale_lab_k3s_0.ipv4_address
  connection_info = {
    user = data.terraform_remote_state.infra.outputs.instances["lab-k3s-2"]["instance_user"]
    host = var.use_ipv6 ? "[${local.machine_2_ip}]" : local.machine_2_ip
    private_key = sensitive(file("~/.ssh/id_rsa"))
  }
  use_ipv6 = true
  depends_on = [
    module.lab_k3s_0,
    module.tailscale_lab_k3s_2
  ]
}
