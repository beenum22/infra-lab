resource "helm_release" "this" {
  name       = var.name
  chart      = "${path.module}/subnet-router"
  namespace  = var.namespace
  set = concat([{
    name = "name"
    value = var.name
  }, {
    name = "hostname"
    value = var.name
  }], [
    for idx, route in var.routes: {
      name  = "advertised_routes[${idx}]"
      value = route
    }
  ])
}