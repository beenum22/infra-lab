resource "kubernetes_daemonset" "this" {
  metadata {
    name = var.name
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name" = var.name
      "app.kubernetes.io/instance" = var.name
      "app.kubernetes.io/version" = var.tag
    }
  }
  spec {
    selector {
      match_labels = {
        "app.kubernetes.io/name" = var.name
      }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = var.name
          "app.kubernetes.io/instance" = var.name
          "app.kubernetes.io/version" = var.tag
        }
      }
      spec {
        node_selector = var.node_selector
        container {
          name = "honeygain"
          image = "${var.image}:${var.tag}"
          image_pull_policy = "IfNotPresent"
          args = [
            "-tou-accept",
            "-email=${var.account_name}",
            "-pass=${var.account_password}",
            "-device=$(NODE_NAME)",
          ]
          env {
            name = "NODE_NAME"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }
        }
      }
    }
  }
}
