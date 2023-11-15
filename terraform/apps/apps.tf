resource "kubernetes_namespace" "apps" {
  metadata {
    name = "apps"
  }
}

module "jellyfin" {
  source = "./modules/jellyfin"
  namespace = kubernetes_namespace.apps.metadata[0].name
  ingress_host = "2001:cafe:42:1::23f1"
  issuer = module.cert_manager.issuer
  domains = [
    "media.dera.ovh",
    "jellyfin.dera.ovh"
  ]
  publish = true
  depends_on = [kubernetes_namespace.apps]
}

module "dashy" {
  source = "./modules/dashy"
  namespace = kubernetes_namespace.apps.metadata[0].name
  ingress_host = "2001:cafe:42:1::23f1"
  issuer = "letsencrypt-ovh"
  domains = [
    "dashy.dera.ovh"
  ]
  depends_on = [kubernetes_namespace.apps]
}

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

module "mailu" {
  source = "./modules/mailu"
  password = var.mailu_password
  namespace = kubernetes_namespace.apps.metadata[0].name
  issuer = module.cert_manager.issuer
  domains = [
    "mailu.dera.ovh"
  ]
  mail_domain = "dera.ovh"
//  publish = true
  storage_class = "local-path"
  //  db_root_password = "admin"
  //  db_password = "filerun"
  //  db_size = "1Gi"
  //  user_data_size = "30Gi"
  depends_on = [kubernetes_namespace.apps]
}

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
