//module "tailscale" {
//  source = "./modules/tailscale"
//  for_each = local.instances
//  tailscale_version = "1.42.0"
//  tailscale_mtu = "1280"
//  authkey = "tskey-auth-kVP8yN1CNTRL-taD4jBDpf2j85okFp3dR8jcZJzuCAL2y"  # Temporary key. Probably already expired.
//  hostname = each.value.hostname
//  tailnet = var.tailscale_tailnet
//  connection_info = {
//    user = each.value.user
//    host = each.value.host
//    private_key = sensitive(file("~/.ssh/id_rsa"))
//  }
//}
