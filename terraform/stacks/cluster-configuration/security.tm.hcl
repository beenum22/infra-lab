generate_hcl "_security.tf" {
  content {
    resource "kubernetes_namespace" "security" {
      metadata {
        name = "security"
      }
    }

    module "cert_manager" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/cert-manager"
      flux_managed = true
      chart_version = "1.*.*"  # Use latest upstream version
      namespace = kubernetes_namespace.security.metadata.0.name
      domain_email = global.project.domain_email
      cloudflare_api_token = global.secrets.cloudflare.dns.api_token
      ingress_class = global.project.ingress_class
      depends_on = [kubernetes_namespace.security]
    }

    module "authelia" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/authelia"
      flux_managed = true
      chart_version = "0.10.43"  # Use latest upstream version
      namespace = kubernetes_namespace.security.metadata[0].name
      issuer = module.cert_manager.issuer
      domains = global.cluster.apps.authelia.hostnames
      ingress_class = global.project.ingress_class
      storage_class = global.project.storage_class
      credentials = global.secrets.authelia.credentials
      oidc_clients = global.cluster.oidc_clients
      oidc_authorization_policies = global.cluster.oidc_authorization_policies
    }

    resource "cloudflare_record" "authelia" {
      zone_id = global.infrastructure.cloudflare.zone_id
      name    = global.cluster.apps.authelia.hostnames[0]
      value   = global.cluster.apps.authelia.public ? module.cloudflared.tunnel_hostname : module.nginx.endpoint
      type    = "CNAME"
      proxied = global.cluster.apps.authelia.public ? true : false
      ttl     = global.cluster.apps.authelia.public ? "1" : "60"
    }
  }
}
