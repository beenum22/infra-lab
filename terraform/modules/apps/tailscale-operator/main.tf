resource "helm_release" "this" {
  name       = var.name
  repository = var.chart_url
  chart      = var.chart_name
  version    = var.chart_version
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
