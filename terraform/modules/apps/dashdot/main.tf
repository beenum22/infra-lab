locals {
  ingress_annotations = {
    "cert-manager.io/cluster-issuer" = var.issuer
    "kubernetes.io/ingress.class" = var.ingress_class
    "external-dns.alpha.kubernetes.io/internal-hostname" = join(",", var.domains)
    "external-dns.alpha.kubernetes.io/target" = var.ingress_hostname
  }
}

resource "kubernetes_cluster_role" "this" {
  metadata {
    name = "${var.name}-node-viewer"
  }
  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role" "this" {
  metadata {
    name = "${var.name}-pod-labeler"
    namespace = var.namespace
  }
  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "update", "patch"]
  }
  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["list"]
  }
}

resource "kubernetes_service_account" "this" {
  metadata {
    name = var.name
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name" = var.name
      "app.kubernetes.io/instance" = var.name
      "app.kubernetes.io/version" = var.tag
    }
  }
}

resource "kubernetes_cluster_role_binding" "this" {
  metadata {
    name = "${var.name}-node-viewer"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.this.metadata.0.name
    namespace = var.namespace
  }

  role_ref {
    kind     = "ClusterRole"
    name     = kubernetes_cluster_role.this.metadata.0.name
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_role_binding" "this" {
  metadata {
    name = "${var.name}-pod-labeler"
    namespace = var.namespace
  }
  subject {
    kind = "ServiceAccount"
    name = kubernetes_service_account.this.metadata.0.name
    namespace = var.namespace
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.this.metadata.0.name
  }
}

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
        service_account_name = kubernetes_service_account.this.metadata.0.name
        init_container {
          name = "node-label"
          image = "bitnami/kubectl:1.28.8"
          command = [
            "sh",
            "-c",
            "kubectl -n $NAMESPACE label pods $POD_NAME app.kubernetes.io/node=$(kubectl get node -L app.kubernetes.io/node | grep $NODE_NAME | awk '{print $1}')"
          ]
          env {
            name = "NAMESPACE"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }
          env {
            name = "NODE_NAME"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }
          env {
            name = "POD_NAME"
            value_from {
              field_ref {
                field_path = "metadata.name"
              }
            }
          }
        }
        volume {
          name = "root-volume"
          host_path {
            path = "/"
          }
        }
        container {
          name = "dashdot"
          image = "${var.image}:${var.tag}"
          image_pull_policy = "IfNotPresent"
          security_context {
            privileged = true
          }
          volume_mount {
            name       = "root-volume"
            mount_path = "/mnt/host"
            read_only = true
          }
          port {
            name = "http"
            container_port = 3001
            protocol = "TCP"
          }
          liveness_probe {
            http_get {
              path = "/"
              port = "3001"
            }
          }
          readiness_probe {
            http_get {
              path = "/"
              port = "3001"
            }
          }
          env {
            name = "DASHDOT_PAGE_TITLE"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }
          env {
            name = "DASHDOT_PORT"
            value = "3001"
          }
          env {
            name = "DASHDOT_ALWAYS_SHOW_PERCENTAGES"
            value = "true"
          }
          env {
            name = "DASHDOT_CPU_LABEL_LIST"
            value = "brand,model,cores,threads,frequency"
          }
          env {
            name = "DASHDOT_CUSTOM_HOST"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }
          env {
            name = "DASHDOT_ENABLE_CPU_TEMPS"
            value = "true"
          }
          env {
            name = "DASHDOT_GPU_LABEL_LIST"
            value = "brand, model, memory"
          }
          env {
            name = "DASHDOT_NETWORK_LABEL_LIST"
            value = "type,speed_up,speed_down,interface_speed"
          }
          env {
            name = "DASHDOT_OS_LABEL_LIST"
            value = "os,arch,up_since"
          }
          env {
            name = "DASHDOT_RAM_LABEL_LIST"
            value = "brand,size,type,frequency"
          }
          env {
            name = "DASHDOT_SHOW_DASH_VERSION"
            value = ""
          }
          env {
            name = "DASHDOT_SHOW_HOST"
            value = "true"
          }
          env {
            name = "DASHDOT_STORAGE_LABEL_LIST"
            value = "brand,size,type"
          }
          env {
            name = "DASHDOT_USE_IMPERIAL"
            value = "false"
          }
          env {
            name = "DASHDOT_WIDGET_LIST"
            value = "os,cpu,storage,ram,network"
          }
          env {
            name = "DASHDOT_ACCEPT_OOKLA_EULA"
            value = "true"
          }
          env {
            name = "DASHDOT_FS_VIRTUAL_MOUNTS"
            value = "openebs-localpv"
          }
          env {
            name = "TZ"
            value = "Europe/Berlin"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "this" {
  for_each = toset(var.nodes)
  metadata {
    name = "${var.name}-${each.value}"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name" = var.name
      "app.kubernetes.io/instance" = var.name
      "app.kubernetes.io/version" = var.tag
      "app.kubernetes.io/node" = each.value
    }
  }
  spec {
    type = "ClusterIP"
    ip_families = [
      "IPv6",
      "IPv4",
    ]
    ip_family_policy = "PreferDualStack"
    selector = {
      "app.kubernetes.io/node" = each.value
    }
    port {
      name = "http"
      port = 80
      target_port = 3001
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
      "app.kubernetes.io/instance" = var.name
      "app.kubernetes.io/version" = var.tag
    }
    annotations = local.ingress_annotations
  }
  spec {
    ingress_class_name = var.ingress_class
    tls {
      secret_name = "${var.name}-tls"
      hosts = flatten([ for node in var.nodes : [for domain in var.domains : "${node}.${domain}"] ])
    }
    dynamic "rule" {
      for_each = toset(flatten([ for node in var.nodes : [for domain in var.domains : "${node}.${domain}"] ]))
      content {
        host = rule.value
        http {
          path {
            path = "/"
            path_type = "Prefix"
            backend {
              service {
                name = "${var.name}-${split(".", rule.value)[0]}"
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
