generate_hcl "_cicd.tf" {
  content {
    resource "kubernetes_namespace" "cicd" {
      metadata {
        name = global.cluster.cicd.namespace
        labels = {
          # "pod-security.kubernetes.io/enforce" = "privileged"
        }
      }
    }

    module "fluxcd" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/fluxcd"
      namespace = kubernetes_namespace.cicd.metadata[0].name
      extra_values = {}
    }
  }
}

generate_hcl "_woodpecker.tf" {
  condition = global.feature_toggles.enable_woodpecker
  content {
    module "woodpecker" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/woodpecker"
      flux_managed = true
      chart_version = "3.*.*"  # Use latest upstream version
      namespace = kubernetes_namespace.cicd.metadata[0].name
      issuer = module.cert_manager.issuer
      domains = global.cluster.apps.woodpecker.hostnames
      ingress_class = global.project.ingress_class
      github_client_id = global.secrets.github.woodpecker.client_id
      github_client_secret = global.secrets.github.woodpecker.client_secret
    }

    resource "cloudflare_record" "woodpecker" {
      zone_id = global.infrastructure.cloudflare.zone_id
      name    = global.cluster.apps.woodpecker.hostnames[0]
      value   = module.nginx.endpoint
      type    = "CNAME"
      proxied = false
      ttl     = "60"
    }
  }
}

generate_hcl "_drone.tf" {
  condition = global.feature_toggles.enable_drone
  content {
    module "drone" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/droneci"
      flux_managed = true
      chart_version = "0.*.*"  # Use latest upstream version
      namespace = kubernetes_namespace.cicd.metadata[0].name
      issuer = module.cert_manager.issuer
      domains = global.cluster.apps.drone.hostnames
      ingress_class = global.project.ingress_class
    }

    resource "cloudflare_record" "drone" {
      zone_id = global.infrastructure.cloudflare.zone_id
      name    = global.cluster.apps.drone.hostnames[0]
      value   = module.nginx.endpoint
      type    = "CNAME"
      proxied = false
      ttl     = "60"
    }
  }
}

generate_hcl "_tekton.tf" {
  condition = global.feature_toggles.enable_tekton
  content {
    module "tekton_operator" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/tekton-operator"
      flux_managed = false
      # chart_version = "0.*.*"  # Use latest upstream version
      namespace = kubernetes_namespace.cicd.metadata[0].name
      issuer = global.project.cert_manager_issuer
      domains = [global.cluster.cicd.argo_workflows.domain]
      ingress_class = global.project.ingress_class
      depends_on = [
        kubernetes_namespace.cicd
      ]
    }
  }
}

generate_hcl "_argo_workflows.tf" {
  condition = global.feature_toggles.enable_argo_workflows
  content {
    module "argoworkflows" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/argo-workflows"
      flux_managed = true
      chart_version = "0.*.*"  # Use latest upstream version
      namespace = kubernetes_namespace.cicd.metadata[0].name
      issuer = global.project.cert_manager_issuer
      domains = [global.cluster.cicd.argo_workflows.domain]
      depends_on = [
        kubernetes_namespace.cicd
      ]
    }

    resource "cloudflare_record" "argoworkflows" {
      zone_id = global.infrastructure.cloudflare.zone_id
      name    = global.cluster.cicd.argo_workflows.domain
      value   = module.nginx.endpoint
      type    = "CNAME"
      proxied = false
      ttl     = "60"
    }
  }
}

generate_hcl "_argo_events.tf" {
  condition = global.feature_toggles.enable_argo_events
  content {
    module "argo_events" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/argo-events"
      flux_managed = true
      chart_version = "2.*.*"  # Use latest upstream version
      namespace = kubernetes_namespace.cicd.metadata[0].name
      depends_on = [
        kubernetes_namespace.cicd
      ]
    }
  }
}

generate_hcl "_argo.tf" {
  condition = global.feature_toggles.enable_argocd
  content {
    module "argocd" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/argocd"
      namespace = kubernetes_namespace.cicd.metadata[0].name
      ingress_hostname = global.project.ingress_hostname
      issuer = global.project.cert_manager_issuer
      domain = global.cluster.cicd.argocd.domain
      admin_password = global.secrets.argocd.password
      depends_on = [
        kubernetes_namespace.cicd
      ]
    }

    resource "cloudflare_record" "argocd" {
      zone_id = global.infrastructure.cloudflare.zone_id
      name    = global.cluster.cicd.argocd.domain
      value   = module.nginx.endpoint
      type    = "CNAME"
      proxied = false
      ttl     = "60"
    }
  }
}
