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
    name = "installCRDs"
    value = true
  }
}

resource "kubernetes_cluster_role" "this" {
  metadata {
    name = "${var.name}-webhook-ovh:secret-reader"
  }
  rule {
    api_groups = [""]
    resources = ["secrets"]
    resource_names = [
      "${var.name}-ovh-credentials",
      "ovh-credentials"
    ]
    verbs = ["get", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "this" {
  metadata {
    name = "${var.name}-webhook-ovh:secret-reader"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = "${var.name}-webhook-ovh:secret-reader"
  }
  subject {
    api_group = ""
    kind = "ServiceAccount"
    name = "${var.name}-webhook-ovh"
    namespace = var.namespace
  }
}

resource "kubernetes_secret" "ovh" {
  metadata {
    name = "${var.name}-ovh-credentials"
    namespace = var.namespace
  }
  type = "Opaque"
  data = {
    applicationSecret = var.ovh_app_secret
  }
}

resource "helm_release" "ovh_hook" {
  depends_on = [helm_release.chart]
  name       = "${var.name}-webhook-ovh"
//  chart      = "modules/cert-manager/cert-manager-webhook-ovh/deploy/cert-manager-webhook-ovh"
  chart      = var.webhook_chart_name
  repository = var.webhook_chart_url
  version    = var.webhook_chart_version
  namespace   = var.namespace
  set {
    name = "image.repository"
    value = var.webhook_image
  }
  set {
    name = "image.tag"
    value = var.webhook_tag
  }
  set {
    name = "groupName"
    value = var.group_name
  }
  set {
    name = "certManager.namespace"
    value = var.namespace
  }
  set {
    name = "certManager.namespace"
    value = var.namespace
  }
  set {
    name = "issuers[0].name"
    value = "letsencrypt-ovh"
  }
  set {
    name = "issuers[0].create"
    value = true
  }
  set {
    name = "issuers[0].kind"
    value = "ClusterIssuer"
  }
  set {
    name = "issuers[0].namespace"
    value = var.namespace
  }
  set {
    name = "issuers[0].acmeServerUrl"
    value = "https://acme-v02.api.letsencrypt.org/directory"
  }
  set {
    name = "issuers[0].email"
    value = var.domain_email
  }
  set {
    name = "issuers[0].ovhEndpointName"
    value = "ovh-eu"
  }
  set {
    name = "issuers[0].ovhAuthentication.applicationKey"
    value = var.ovh_app_key
  }
  set {
    name = "issuers[0].ovhAuthentication.applicationSecret"
    value = var.ovh_app_secret
  }
  set {
    name = "issuers[0].ovhAuthentication.consumerKey"
    value = var.ovh_consumer_key
  }
}

//resource "kubernetes_manifest" "ovh" {
//  depends_on = [
//    kubernetes_secret.ovh,
//    helm_release.chart,
////    helm_release.ovh_hook
//  ]
//  manifest = {
//    "apiVersion" = "cert-manager.io/v1"
//    "kind" = "ClusterIssuer"
//    "metadata" = {
//      "name" = "letsencrypt"
//    }
//    "spec" = {
//      "acme" = {
//        "email" = var.domain_email
//        "privateKeySecretRef" = {
//          "name" = "letsencrypt-account-key"
//        }
//        "server" = "https://acme-v02.api.letsencrypt.org/directory"
//        "solvers" = [
//          {
//            "dns01" = {
//              "webhook" = {
//                "groupName" = var.group_name
//                "solverName" = "ovh"
//                "config" = {
//                  "endpoint" = "ovh-eu"
//                  "applicationKey" = var.ovh_app_key
//                  "applicationSecretRef" = {
//                    "key" = "applicationSecret"
//                    "name" = "ovh-credentials"
//                  }
//                  "consumerKey" = var.ovh_consumer_key
//                }
//              }
//            }
//          }
//        ]
//      }
//    }
//  }
//}
