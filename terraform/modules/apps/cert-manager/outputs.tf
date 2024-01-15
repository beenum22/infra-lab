output "name" {
  value = helm_release.chart.name
}

output "issuer" {
  value = "letsencrypt-ovh"
}