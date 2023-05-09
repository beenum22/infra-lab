module "tailscale_lab_k3s_0" {
  source = "./modules/tailscale"
  authkey = "tskey-auth-kyoQKo1CNTRL-UbTurGjqcXEJVzHD9pVmTEfXj1m3aEUAQ"
  hostname = data.terraform_remote_state.infra.outputs.instances[0]["instance_name"]
  tailnet = var.tailscale_tailnet
  routes = [
    "10.43.0.0/16",
    "2001:cafe:42:1::/112"
  ]
}

module "tailscale_lab_k3s_1" {
  providers = {
    docker = docker.lab-k3s-1
  }
  source = "./modules/tailscale"
  authkey = var.tailscale_authkey
  hostname = data.terraform_remote_state.infra.outputs.instances[1]["instance_name"]
  tailnet = var.tailscale_tailnet
}