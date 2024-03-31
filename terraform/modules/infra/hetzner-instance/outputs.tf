output "instance_name" {
  value = var.name
}

output "instance_id" {
  value = hcloud_server.this.id
}

output "volumes" {
  value = [
    for volume in hcloud_volume.this : volume.name
  ]
}

output "ipv4_address" {
  value = try(hcloud_server.this.ipv4_address, null)
}

output "ipv6_address" {
  value = try(hcloud_server.this.ipv6_address, null)
}
