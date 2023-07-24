resource "helm_release" "chart" {
  name       = var.name
  repository = var.chart_url
  chart      = var.chart_name
  version    = var.chart_version
  namespace   = var.namespace
  set {
    name = "image.repository"
    value = var.image
  }
  set {
    name = "image.tag"
    value = var.tag
  }
  set {
    name = "provider"
    value = "pihole"
  }
  set {
    name = "extraArgs[0]"
    value = "--pihole-password=${var.pihole_password}"
  }
  set {
    name = "extraArgs[1]"
    value = "--pihole-server=${var.pihole_server}"
  }
  set {
    name = "extraArgs[2]"
    value = "--publish-internal-services"
  }
}
