resource "kubernetes_secret" "authkey" {
  metadata {
    name = "${var.name}-authkey"
    namespace = var.namespace
  }
  data = {
    AUTH_KEY = var.authkey
  }
}

locals {
  test = flatten([ for id, country in var.vpn_countries : [for i in range(var.replicas): "${country}-${i}"] ])
//  test = merge([
//    for k1, v1 in local.x:
//    {
//    for  v2 in v1:
//    "${k1}-${v2.p0}" => v2
//    }
//  ]...)
}

output "test" {
  value = local.test
}

resource "kubernetes_secret" "state" {
  for_each = toset(flatten([ for id, country in var.vpn_countries : [for i in range(var.replicas): "${country}-${i}"] ]))
  metadata {
    name = "${var.name}-${each.value}"
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
    resource_names = flatten([ for id, country in var.vpn_countries : [for i in range(var.replicas): "${var.name}-${country}-${i}"] ])
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
  for_each = toset(var.vpn_countries)
  metadata {
    name = "${var.name}-${each.value}"
    namespace = var.namespace
    annotations = var.annotations
    labels = merge({
      "app.kubernetes.io/name": "${var.name}-${each.value}"
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
        "app.kubernetes.io/name": "${var.name}-${each.value}"
      }, var.labels)
    }
    service_name = "${var.name}-${each.value}"
    template {
      metadata {
        labels = merge({
          "app.kubernetes.io/name": "${var.name}-${each.value}"
        }, var.labels)
        annotations = var.annotations
      }
      spec {
        service_account_name = var.name
        affinity {
          node_affinity {
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key = var.vpn_label
                  operator = "In"
                  values = [each.value]
                }
              }
            }
          }
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 100
              pod_affinity_term {
                label_selector {
                  match_labels = {
                    "app.kubernetes.io/name": "${var.name}-${each.value}"
                  }
                }
                topology_key = "node.kubernetes.io/instance-type"
              }
            }
          }
        }
        image_pull_secrets {
          name = "regcred"
        }
        volume {
          name = "tun"
          host_path {
            path = "/dev/net/tun"
          }
        }
        init_container {
          name = "nat64-helper"
          image = "alpine:latest"
          security_context {
            capabilities {
              add = [
                "SYS_MODULE",
                "NET_ADMIN",
                "NET_RAW",
              ]
            }
          }
          command = ["sh", "-c"]
          args = [
            "apk add ip6tables && ip6tables -nvL -t nat"]
        }
        container {
          name = "vpn"
          image = "${var.image}:${var.tag}"
          image_pull_policy = "Always"
          volume_mount {
            mount_path = "/dev/net/tun"
            name = "tun"
            read_only = false
          }
          security_context {
//            run_as_group = "1000"
//            run_as_user = "1000"
            privileged = true
            capabilities {
              add = [
                "NET_ADMIN",
                "NET_RAW",
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
            value = "false"
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
            name = "TS_EXTRA_ARGS"
            value = join(",", var.extra_args)
          }
          env {
            name = "TS_TAILSCALED_EXTRA_ARGS"
            value = "-tun kube-tailscale0"
          }
//          env {
//            name = "TS_DEBUG_MTU"
//            value = var.mtu
//          }
          resources {}
        }
      }
    }
  }
}
