resource "helm_release" "this" {
  name       = var.name
  chart      = "${path.module}/subnet-router"
  namespace  = var.namespace
  set {
    name = "name"
    value = var.name
  }
  set {
    name = "hostname"
    value = var.name
  }
  dynamic "set" {
    for_each   = { for idx, route in var.routes: idx => route}
    content {
      name = "advertised_routes[${set.key}]"
      value = set.value
    }
  }
}