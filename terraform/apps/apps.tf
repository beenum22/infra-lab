resource "kubernetes_namespace" "apps" {
  metadata {
    name = "apps"
  }
}

//module "jellyfin" {
//  source = "./modules/jellyfin"
//  namespace = kubernetes_namespace.apps.metadata[0].name
//  ingress_host = "2001:cafe:42:1::23f1"
//  issuer = module.cert_manager.issuer
//  domains = [
//    "media.dera.ovh",
//    "jellyfin.dera.ovh"
//  ]
//  publish = true
//  depends_on = [kubernetes_namespace.apps]
//}

//module "dashy" {
//  source = "./modules/dashy"
//  namespace = kubernetes_namespace.apps.metadata[0].name
//  ingress_host = "2001:cafe:42:1::23f1"
//  issuer = "letsencrypt-ovh"
//  domains = [
//    "dashy.dera.ovh"
//  ]
//  depends_on = [kubernetes_namespace.apps]
//}

module "hajimari" {
  source = "./modules/hajimari"
  namespace = kubernetes_namespace.apps.metadata[0].name
  issuer = module.cert_manager.issuer
  target_namespaces = [
    "dns"
  ]
  domains = [
    "homepage.dera.ovh",
    "hajimari.dera.ovh"
  ]
  title = "Nur der Dera"
  enduser_name = "Zombies"
  ingress_hostname = "wormhole.dera.ovh"
  depends_on = [kubernetes_namespace.apps]
}

module "filebrowser" {
  source = "./modules/filebrowser"
  namespace = kubernetes_namespace.apps.metadata[0].name
  issuer = module.cert_manager.issuer
  domains = [
    "filebrowser.dera.ovh"
  ]
  publish = true
  storage_class = "local-path"
  ingress_hostname = "wormhole.dera.ovh"
//  db_root_password = "admin"
//  db_password = "filerun"
//  db_size = "1Gi"
//  user_data_size = "30Gi"
  depends_on = [kubernetes_namespace.apps]
}

//module "mailu" {
//  source = "./modules/mailu"
//  password = var.mailu_password
//  namespace = kubernetes_namespace.apps.metadata[0].name
//  issuer = module.cert_manager.issuer
//  domains = [
//    "mailu.dera.ovh"
//  ]
//  mail_domain = "dera.ovh"
////  publish = true
//  storage_class = "local-path"
//  //  db_root_password = "admin"
//  //  db_password = "filerun"
//  //  db_size = "1Gi"
//  //  user_data_size = "30Gi"
//  depends_on = [kubernetes_namespace.apps]
//}

module "jitsi" {
  source = "./modules/jitsi"
  namespace = kubernetes_namespace.apps.metadata[0].name
  issuer = module.cert_manager.issuer
  domains = [
    "jitsi.dera.ovh"
  ]
  publish = true
  ingress_hostname = "wormhole.dera.ovh"
  depends_on = [kubernetes_namespace.apps]
}

//module "kube-ops-view" {
//  source = "./modules/kube-ops-view"
//  namespace = kubernetes_namespace.apps.metadata[0].name
//  issuer = module.cert_manager.issuer
//  domains = [
//    "kube-ops-view.dera.ovh"
//  ]
//  publish = true
//  ingress_hostname = "wormhole.dera.ovh"
//  depends_on = [kubernetes_namespace.apps]
//}

module "homepage" {
  source = "./modules/homepage"
  namespace = kubernetes_namespace.apps.metadata[0].name
  issuer = module.cert_manager.issuer
  domains = [
    "homepage-v2.dera.ovh"
  ]
  ingress_class = "nginx"
  ingress_hostname = "wormhole.dera.ovh"
  service_groups = [
    {
      "Cluster" = [
        {
          "Pihole" = {
            description = "DNS Server with Adblocker"
            href        = "https://pihole.dera.ovh/admin"
            icon        = "pi-hole"
            ping        = "https://pihole.dera.ovh/admin"
            widget      = {
              key  = var.pihole_api_key
              url  = "https://pihole.dera.ovh"
              type = "pihole"
            }
          }
        },
      ]
    },
    {
      "Apps" = [
        {
          "Filebrowser" = {
            description = "Shared File Storage"
            href        = "https://filebrowser.dera.ovh"
            icon        = "filebrowser"
            ping        = "https://filebrowser.dera.ovh"
          }
        },
        {
          "Jitsi-meet" = {
            description = "Video calling service"
            href        = "https://jitsi.dera.ovh"
            icon        = "jitsi-meet"
            ping        = "https://jitsi.dera.ovh"
          }
        }
      ]
    }
  ]
  extra_values = {
    "image.tag": "v0.6.29"
  }
  depends_on = [kubernetes_namespace.apps]
}
