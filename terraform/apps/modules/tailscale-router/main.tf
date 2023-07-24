resource "kubernetes_secret" "authkey" {
  metadata {
    name = "tailscale-authkey"
    namespace = var.namespace
  }
  data = {
    AUTH_KEY = var.authkey
  }
}

moved {
  from = kubernetes_secret.this
  to = kubernetes_secret.state
}

resource "kubernetes_secret" "state" {
  count = var.replicas
  metadata {
    name = "${var.name}-${count.index}"
    namespace = var.namespace
  }
  type = "Opaque"
}

resource "kubernetes_service_account" "this" {
  metadata {
    name = var.name
    namespace = var.namespace
    labels = merge({
      "app.kubernetes.io/name": var.name
    }, var.labels)
    annotations = var.annotations
  }
}

resource "kubernetes_role" "this" {
  metadata {
    name = var.name
    namespace = var.namespace
  }
  rule {
    api_groups     = [""]
    resources      = ["secrets"]
    verbs          = ["create"]
  }
  rule {
    api_groups = [""]
    resources  = ["secrets"]
    resource_names = flatten(kubernetes_secret.state[*].metadata[*].name)
    verbs      = ["get", "update", "patch"]
  }
}

resource "kubernetes_role_binding" "this" {
  metadata {
    name = var.name
    namespace = var.namespace
    labels = merge({
      "app.kubernetes.io/name": var.name
    }, var.labels)
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "Role"
    name = var.name
  }
  subject {
    kind = "ServiceAccount"
    name = var.name
    namespace = var.namespace
  }
}

resource "kubernetes_stateful_set" "this" {
  metadata {
    name = var.name
    namespace = var.namespace
    annotations = var.annotations
    labels = merge({
      "app.kubernetes.io/name": var.name
    }, var.labels)
  }
  spec {
    pod_management_policy  = "Parallel"
    replicas               = var.replicas
    update_strategy {
      type = "RollingUpdate"
    }
    selector {
      match_labels = merge({
        "app.kubernetes.io/name": var.name
      }, var.labels)
    }
    service_name = var.name
    template {
      metadata {
        labels = merge({
          "app.kubernetes.io/name": var.name
        }, var.labels)
        annotations = var.annotations
      }
      spec {
        service_account_name = var.name
        affinity {
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 100
              pod_affinity_term {
                label_selector {
                  match_labels = {
                    "app.kubernetes.io/name": var.name
                  }
                }
                topology_key = "node.kubernetes.io/instance-type"
              }
            }
          }
        }
        container {
          name = "router"
          image = var.image
          image_pull_policy = "IfNotPresent"
          security_context {
            capabilities {
              add = [
                "NET_ADMIN"
              ]
            }
          }
          env {
            name = "TS_KUBE_SECRET"
            value_from {
              field_ref {
                field_path = "metadata.name"
              }
            }
          }
          env {
            name = "TS_USERSPACE"
            value = "true"
          }
          env {
            name = "TS_AUTH_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.authkey.metadata[0].name
                key = "AUTH_KEY"
              }
            }
          }
          env {
            name = "TS_ROUTES"
            value = join(",", var.routes)
          }
          env {
            name = "TS_EXTRA_ARGS"
            value = join(",", var.extra_args)
          }
          env {
            name = "TS_DEBUG_MTU"
            value = var.mtu
          }
          resources {}
        }
      }
    }
  }
}
