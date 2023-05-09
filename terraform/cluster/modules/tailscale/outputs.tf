output "container_id" {
  value = docker_container.container.id
}
//
//output "container_ip" {
//  value = docker_container.container.ip_address
//}

output "container_hostname" {
  value = docker_container.container.hostname
}

output "ipv4_address" {
  value = data.tailscale_device.device.addresses[0]
}

output "ipv6_address" {
  value = data.tailscale_device.device.addresses[1]
}
