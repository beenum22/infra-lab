module "tailscale_lab_k3s_0" {
  source = "./modules/tailscale"
  authkey = "tskey-auth-kyoQKo1CNTRL-UbTurGjqcXEJVzHD9pVmTEfXj1m3aEUAQ"  # Temporary key. Probably already expired.
  hostname = data.terraform_remote_state.infra.outputs.instances["lab-k3s-0"]["instance_name"]
  tailnet = var.tailscale_tailnet
  tag = "v1.40.0"
}

module "tailscale_lab_k3s_1" {
  providers = {
    docker = docker.lab-k3s-1
  }
  source = "./modules/tailscale"
  authkey = "tskey-auth-kyoQKo1CNTRL-UbTurGjqcXEJVzHD9pVmTEfXj1m3aEUAQ"  # Temporary key. Probably already expired.
  hostname = data.terraform_remote_state.infra.outputs.instances["lab-k3s-1"]["instance_name"]
  tailnet = var.tailscale_tailnet
  tag = "v1.40.0"
}

module "tailscale_lab_k3s_2" {
  providers = {
    docker = docker.lab-k3s-2
  }
  source = "./modules/tailscale"
  authkey = "tskey-auth-k3n9sg7CNTRL-HzhYjmeYYAVhRMwsRUBGGVpQxWhCtixk2"  # Temporary key valid for 1 day only
  hostname = data.terraform_remote_state.infra.outputs.instances["lab-k3s-2"]["instance_name"]
  tailnet = var.tailscale_tailnet
  tag = "v1.42.0"
}