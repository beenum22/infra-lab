# Warning: CRDs are not removed on deletion.
# TODO: Add support for CRDs removal on deletion.
resource "helm_release" "this" {
  name       = var.name
  repository = var.chart_url
  chart      = var.chart_name
  version    = var.chart_version
  namespace   = var.namespace
  set = [
    for key, value in var.extra_values :{
      key = key,
      value = value,
      type = "string"
    }
  ]
}
