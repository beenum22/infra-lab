resource "kubernetes_deployment" "this" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name" = var.name
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        "app.kubernetes.io/name" = var.name
      }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = var.name
        }
      }
      spec {
        container {
          name  = var.name
          image = "${var.image}:${var.tag}"
        }
      }
    }
  }

}

locals {
  ingress_annotations = {
    "cert-manager.io/cluster-issuer" = var.issuer
    "kubernetes.io/ingress.class" = var.ingress_class
  }
}

resource "kubernetes_service" "this" {
  metadata {
    name = var.name
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name" = var.name
    }
  }
  spec {
    type = "ClusterIP"
    selector = {
      "app.kubernetes.io/name" = var.name
    }
    ip_families = [
      "IPv6",
      "IPv4",
    ]
    ip_family_policy = "PreferDualStack"
    port {
      name = "http"
      port = 8080
      target_port = 8080
      protocol = "TCP"
    }
  }
}

resource "kubernetes_ingress_v1" "this" {
  metadata {
    name = var.name
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name" = var.name
    }
    annotations = local.ingress_annotations
  }
  spec {
    ingress_class_name = var.ingress_class
    tls {
      secret_name = "${var.name}-tls"
      hosts = var.domains
    }
    dynamic "rule" {
      for_each = toset(var.domains)
      content {
        host = rule.value
        http {
          path {
            path = "/"
            backend {
              service {
                name = var.name
                port {
                  name = "http"
                }
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_manifest" "image_repo" {
  count = var.flux_managed ? 1 : 0
  manifest = {
    apiVersion = "image.toolkit.fluxcd.io/v1beta2"
    kind       = "ImageRepository"
    metadata = {
      name      = var.name
      namespace = var.namespace
    }
    spec = {
      image = "ghcr.io/aniskhan25/stockseer"
      interval = "1m"
    }
  }
}

resource "kubernetes_manifest" "image_update_policy" {
  count = var.flux_managed ? 1 : 0
  manifest = {
    apiVersion = "image.toolkit.fluxcd.io/v1beta2"
    kind       = "ImagePolicy"
    metadata = {
      name      = var.name
      namespace = var.namespace
    }
    spec = {
      imageRepositoryRef = {
        name      = var.name
      }
      policy = {
        semver = {
          range = "0.1.x"
        }
      }
    }
  }
}

# resource "kubernetes_manifest" "image_deployment_update" {
#   count = var.flux_managed ? 1 : 0
#   manifest = {
#     apiVersion = "image.toolkit.fluxcd.io/v1beta2"
#     kind       = "ImageUpdateAutomation"
#     metadata = {
#       name      = var.name
#       namespace = var.namespace
#     }
#     spec = {
#       interval = "1m"
#       imageRepositoryRef = {
#         name      = var.name
#       }
#       policy = {
#         semver = {
#           range = "0.1.x"
#         }
#       }
#     }
#   }
# }

# resource "kubernetes_manifest" "image_deployment_update" {
#   count = var.flux_managed ? 1 : 0
#   manifest = {
#     apiVersion = "kustomize.toolkit.fluxcd.io/v1"
#     kind       = "Kustomization"
#     metadata = {
#       name      = var.name
#       namespace = var.namespace
#     }
#     spec = {
#       interval = "5m"
#       path = "./" # doesn’t matter, since Flux is patching live objects
#       prune = false
#       targetNamespace = var.namespace
#       patches = 
#     - target:
#         kind: Deployment
#         name: my-app
#       patch: |-
#         - op: replace
#           path: /spec/template/spec/containers/0/image
#           value: myregistry/my-app:latest
#       imageRepositoryRef = {
#         name      = var.name
#       }
#       policy = {
#         semver = {
#           range = "0.1.x"
#         }
#       }
#     }
#   }
# }
