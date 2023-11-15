locals {
  ingress_annotations = {
    "cert-manager\\.io/cluster-issuer" = var.issuer
    "kubernetes\\.io/ingress\\.class" = var.ingress_class
    "external-dns\\.alpha\\.kubernetes\\.io/internal-hostname" = replace(join("\\,", var.domains), ".", "\\.")
    "external-dns\\.alpha\\.kubernetes\\.io/target" = var.ingress_hostname
#    "external-dns\\.alpha\\.kubernetes\\.io/target" = "${split(",", var.ingress_endpoints)[0]},"
    "hajimari\\.io/enable" = var.publish
    "hajimari\\.io/icon" = "simple-icons:files"
    "hajimari\\.io/appName" = "filebrowser"
#    "hajimari\\.io/group" = "Storage"
    "hajimari\\.io/url" = "https://${var.domains[0]}"
    "hajimari\\.io/info" = "Shared File Storage"
  }
}

resource "helm_release" "this" {
  name       = var.name
  repository = var.chart_url
  chart      = var.chart_name
  version    = var.chart_version
  namespace  = var.namespace
  set {
    name = "ingress.main.enabled"
    value = true
  }
  set {
    name  = "ingress.main.ingressClassName"
    value = var.ingress_class
  }
  set {
    name  = "ingress.main.tls[0].secretName"
    value = "${var.name}-tls"
  }
  dynamic "set" {
    for_each   = { for idx, domain in var.domains: idx => domain}
    content {
      name = "ingress.main.tls[0].hosts[${set.key}]"
      value = set.value
    }
  }
  dynamic "set" {
    for_each   = { for idx, domain in var.domains: idx => domain}
    content {
      name = "ingress.main.hosts[${set.key}].host"
      value = set.value
    }
  }
  dynamic "set" {
    for_each   = { for idx, domain in var.domains: idx => domain}
    content {
      name = "ingress.main.hosts[${set.key}].paths[0].path"
      value = "/"
    }
  }
  dynamic "set" {
    for_each   = { for idx, domain in var.domains: idx => domain}
    content {
      name = "ingress.main.hosts[${set.key}].paths[0].pathType"
      value = "Prefix"
    }
  }
  dynamic "set" {
    for_each   = local.ingress_annotations
    content {
      name = "ingress.main.annotations.${set.key}"
      value = set.value
      type = "string"
    }
  }
  set {
    name = "persistence.config.enabled"
    value = true
  }
  set {
    name = "persistence.config.storageClass"
    value = var.storage_class
  }
  set {
    name = "persistence.config.size"
    value = var.config_storage
  }
  set {
    name = "persistence.data.enabled"
    value = true
  }
  set {
    name = "persistence.data.storageClass"
    value = var.storage_class
  }
  set {
    name = "persistence.data.size"
    value = var.data_storage
  }
  set {
    name = "persistence.data.accessMode"
    value = "ReadWriteOnce"
  }
  dynamic "set" {
    for_each = var.extra_values
    content {
      name = set.key
      value = set.value
      type = "string"
    }
  }
//
//
//  set {
//    name = "global.storageclass"
//    value = var.storage_class
//  }
//  set {
//    name = "image.repository"
//    value = var.db_image
//  }
//  set {
//    name = "image.tag"
//    value = var.db_tag
//  }
//  set {
//    name = "auth.rootPassword"
//    value = var.db_root_password
//  }
//  set {
//    name = "auth.database"
//    value = var.db_name
//  }
//  set {
//    name = "auth.username"
//    value = var.db_user
//  }
//  set {
//    name = "auth.password"
//    value = var.db_password
//  }
//  set {
//    name = "persistence.storageClass"
//    value = var.storage_class
//  }
//  set {
//    name = "persistence.size"
//    value = var.db_size
//  }
}

//resource "kubernetes_persistent_volume_claim" "web_html" {
//  metadata {
//    name = "${var.name}-web-html"
//    namespace = var.namespace
//  }
//  spec {
//    access_modes = ["ReadWriteOnce"]
//    resources {
//      requests = {
//        storage = "1Gi"
//      }
//    }
//    storage_class_name = var.storage_class
//  }
//}
//
//resource "kubernetes_persistent_volume_claim" "web_userfiles" {
//  metadata {
//    name = "${var.name}-web-userfiles"
//    namespace = var.namespace
//  }
//  spec {
//    access_modes = ["ReadWriteOnce"]
//    resources {
//      requests = {
//        storage = var.user_data_size
//      }
//    }
//    storage_class_name = var.storage_class
//  }
//}
//
//resource "kubernetes_deployment" web {
//  metadata {
//    name = "${var.name}-web"
//    namespace = var.namespace
//    labels = {
//      app = var.name
//      component = "web"
//      version = var.web_tag
//    }
//  }
//  spec {
//    strategy {
//      type = "Recreate"
//    }
//    selector {
//      match_labels = {
//        app = var.name
//        version = var.web_tag
//      }
//    }
//    template {
//      metadata {
//        name = var.name
//        labels = {
//          app = var.name
//          version = var.web_tag
//        }
//      }
//      spec {
//        container {
//          name = "filerun"
//          image = "${var.web_image}:${var.web_tag}"
//          port {
//            container_port = 80
//          }
//          security_context {
//            run_as_non_root = false
//            run_as_group = "0"
//            run_as_user = "0"
//            read_only_root_filesystem = false
//          }
//          env {
//            name = "FR_DB_HOST"
//            value = "${var.name}-mysql"
//          }
//          env {
//            name = "FR_DB_PORT"
//            value = "3306"
//          }
//          env {
//            name = "FR_DB_NAME"
//            value = var.db_name
//          }
//          env {
//            name = "FR_DB_USER"
//            value = var.db_user
//          }
//          env {
//            name = "FR_DB_PASS"
//            value_from {
//              secret_key_ref {
//                key = "mysql-password"
//                name = "${var.name}-mysql"
//              }
//            }
//          }
//          env {
//            name = "APACHE_RUN_USER"
//            value = "pi"
//          }
//          env {
//            name = "APACHE_RUN_USER_ID"
//            value = "1000"
//          }
//          env {
//            name = "APACHE_RUN_GROUP"
//            value = "pi"
//          }
//          env {
//            name = "APACHE_RUN_GROUP_ID"
//            value = "0"
//          }
//          volume_mount {
//            mount_path = "/var/www/html"
//            name = "filerun-web-html"
//          }
//          volume_mount {
//            mount_path = "/user-files"
//            name = "filerun-web-userfiles"
//          }
//        }
//        volume {
//          name = "filerun-web-html"
//          persistent_volume_claim {
//            claim_name = "${var.name}-web-html"
//          }
//        }
//        volume {
//          name = "filerun-web-userfiles"
//          persistent_volume_claim {
//            claim_name = "${var.name}-web-userfiles"
//          }
//        }
//      }
//    }
//  }
//}