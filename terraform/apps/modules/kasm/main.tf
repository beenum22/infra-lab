//resource "kubernetes_persistent_volume_claim" "this" {
//  metadata {
//    name = "${var.name}-data"
//    namespace = var.namespace
//  }
//  spec {
//    access_modes = ["ReadWriteOnce"]
//    resources {
//      requests = {
//        storage = "40Gi"
//      }
//    }
//    storage_class_name = var.storage_class
//  }
//}
//
//resource "kubernetes_deployment" "this" {
//  metadata {
//    name = var.name
//    namespace = var.namespace
//    labels = {
//      app = var.name
//      version = var.tag
//    }
//  }
//  spec {
//    replicas = var.replicas
//    strategy {
//      type = "Recreate"
//    }
//    selector {
//      match_labels = {
//        app = var.name
//        version = var.tag
//      }
//    }
//    template {
//      metadata {
//        name = var.name
//        labels = {
//          app = var.name
//          version = var.tag
//        }
//      }
//      spec {
//        container {
//          name = "kasm"
//          image = "${var.image}:${var.tag}"
//          security_context {
//            allow_privilege_escalation = true
//            privileged = true
//            read_only_root_filesystem = false
//            run_as_non_root = false
//          }
//          port {
//            container_port = 443
//            name = "web"
//          }
//          port {
//            container_port = 3000
//            name = "admin"
//          }
//          env {
//            name = "KASM_PORT"
//            value = "443"
//          }
//          volume_mount {
//            mount_path = "/opt"
//            name = "data"
//          }
//          volume_mount {
//            mount_path = "/run/udev/data"
//            name = "kasm-udev"
//          }
//          volume_mount {
//            mount_path = "/dev/input"
//            name = "kasm-input"
//          }
//        }
//        volume {
//          name = "data"
//          persistent_volume_claim {
//            claim_name = "${var.name}-data"
//          }
//        }
//        volume {
//          name = "kasm-udev"
//          host_path {
//            path = "/run/udev/data"
//          }
//        }
//        volume {
//          name = "kasm-input"
//          host_path {
//            path = "/dev/input"
//          }
//        }
//      }
//    }
//  }
////  depends_on = [kubernetes_persistent_volume_claim.this]
//}
//
//resource "kubernetes_service" "this" {
//  metadata {
//    name = var.name
//    namespace = var.namespace
//  }
//  spec {
//    selector = {
//      app = var.name
//      version = var.tag
//    }
//    port {
//      name = "admin"
//      port = 3000
//      target_port = 3000
//    }
//    port {
//      name = "web"
//      port = 443
//      target_port = 443
//    }
//  }
//}
//
////resource "helm_release" "chart" {
////  name       = var.name
////  repository = var.chart_url
////  chart      = var.chart_name
////  version    = var.chart_version
////  namespace   = var.namespace
////  set {
////    name = "image.repository"
////    value = var.image
////  }
////  set {
////    name = "image.tag"
////    value = var.tag
////  }
//////  set {
//////    name = "serviceAccount.create"
//////    value = true
//////  }
//////  set {
//////    name = "ingress.main.enabled"
//////    value = true
//////  }
//////  set {
//////    name = "ingress.main.ingressClassName"
//////    value = var.ingress_class
//////  }
//////  dynamic "set" {
//////    for_each   = { for idx, domain in var.domains: idx => domain}
//////    content {
//////      name = "ingress.main.hosts[${set.key}].host"
//////      value = set.value
//////    }
//////  }
//////  dynamic "set" {
//////    for_each   = { for idx, domain in var.domains: idx => domain}
//////    content {
//////      name = "ingress.main.hosts[${set.key}].paths[0].path"
//////      value = "/"
//////    }
//////  }
////}
