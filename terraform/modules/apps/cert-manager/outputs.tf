output "name" {
  value = helm_release.cert_manager.name
}

output "issuer" {
  value = "${var.name}-cloudflare"
}