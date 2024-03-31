output "name" {
  value = helm_release.this.name
}

output "issuer" {
  value = "${var.name}-cloudflare"
}