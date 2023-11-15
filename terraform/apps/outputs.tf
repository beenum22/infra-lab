//output "pihole" {
//  value = helm_release.pihole.chart
//}

//output "traefik" {
//  value = module.traefik
//}

//output "tailscale-operator" {
//  value = module.tailscale-operator
//}

output "tailscale" {
  value = module.tailscale_router
}

output "pihole" {
  value = module.pihole
}

output "nginx" {
  value = module.nginx
}
