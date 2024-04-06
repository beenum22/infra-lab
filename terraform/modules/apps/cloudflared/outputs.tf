output "tunnel_hostname" {
  value = cloudflare_tunnel.this.cname
}