#locals {
#  ingress_annotations = {
#    "cert-manager\\.io/cluster-issuer" = var.issuer
#    "kubernetes\\.io/ingress\\.class" = var.ingress_class
#    "external-dns\\.alpha\\.kubernetes\\.io/internal-hostname" = replace(join("\\,", var.domains), ".", "\\.")
#    "external-dns\\.alpha\\.kubernetes\\.io/target" = var.ingress_hostname
#    "hajimari\\.io/enable" = var.publish
#    "hajimari\\.io/icon" = "https://upload.wikimedia.org/wikipedia/commons/0/00/Pi-hole_Logo.png"
#    "hajimari\\.io/appName" = "pihole"
#    "hajimari\\.io/group" = "Cluster"
#    "hajimari\\.io/url" = "https://${var.domains[0]}/admin"
#    "hajimari\\.io/info" = "DNS Server with Adblocker"
#  }
#}

resource "helm_release" "pihole" {
  name       = var.name
  chart      = "${path.module}/chart"
  namespace   = var.namespace
  set {
    name  = "oauth.clientId"
    value = var.client_id
  }
  set {
    name  = "oauth.clientSecret"
    value = var.client_secret
  }
  dynamic "set" {
    for_each = var.extra_values
    content {
      name = set.key
      value = set.value
      type = "string"
    }
  }
}
