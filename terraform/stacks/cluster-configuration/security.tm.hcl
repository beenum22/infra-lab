generate_hcl "_security.tf" {
  content {
    resource "kubernetes_namespace" "security" {
      metadata {
        name = "security"
      }
    }

    module "cert_manager" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/cert-manager"
      namespace = kubernetes_namespace.security.metadata.0.name
      domain_email = global.project.domain_email
      cloudflare_api_token = global.secrets.cloudflare.dns.api_token
      ingress_class = global.project.ingress_class
      depends_on = [kubernetes_namespace.security]
    }
  }
}