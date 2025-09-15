/*
Note: This weird encode and decode is added as a workaround when the Terraform parsing for the list fails
Error log:
│ Warning: Applied changes may be incomplete
│
│ The plan was created with the -target option in effect, so some changes requested in the configuration may have been ignored and the output values may not be fully updated.
│ Run the following command to verify that no other changes are pending:
│     terraform plan
│
│ Note that the -target option is not suitable for routine use, and is provided only for exceptional situations such as recovering from errors or mistakes, or when Terraform
│ specifically suggests to use it as part of an error message.
╵
╷
│ Error: Provider produced inconsistent result after apply
│
│ When applying changes to module.headlamp[0].kubernetes_manifest.helm_release[0], provider "provider[\"registry.terraform.io/hashicorp/kubernetes\"]" produced an unexpected new
│ value: .object: wrong final value type: incorrect object attributes.
│
│ This is a bug in the provider, which should be reported in the provider's own issue tracker.
╵
Error: one or more commands failed
Reference: https://github.com/hashicorp/terraform-provider-kubernetes/issues/1928
*/
locals {
  ingress_annotations = {
    "cert-manager\\.io/cluster-issuer" = var.issuer
    # "kubernetes\\.io/ingress\\.class" = var.ingress_class
  }

  available_plugins = {
    cert_manager = {
      name = "cert-manager"
      source = "https://artifacthub.io/packages/headlamp/headlamp-plugins/headlamp_cert-manager"
      version = var.plugins.cert_manager.version
    }
    flux = {
      name = "flux"
      source = "https://artifacthub.io/packages/headlamp/headlamp-plugins/headlamp_flux"
      version = var.plugins.flux.version
    }
  }

  enabled_plugins = [
    for key, plugin in local.available_plugins : plugin
    if var.plugins[key].enabled == true
  ]

  plugins_config = length(local.enabled_plugins) > 0 ? yamlencode({
    plugins = local.enabled_plugins
  }) : ""
  values = {
    config = {
      inCluster = true
      pluginsDir = "/headlamp/plugins"
      watchPlugins = true
      oidc = {
        secret = {
          create = false
        }
      }
    }
    pluginsManager = {
      enabled = length(local.enabled_plugins) > 0
      configContent = local.plugins_config
    }
    ingress = {
      enabled = true
      annotations = {
        "cert-manager.io/cluster-issuer" = var.issuer
        # "kubernetes.io/ingress.class" = var.ingress_class
      }
      ingressClassName = var.ingress_class
      hosts = [
        for domain in var.domains : {
          host = domain
          paths = [
            {
              path     = "/"
              type = "Prefix"
            }
          ]
        }
      ]
      tls = [{
        secretName = "${var.name}-tls"
        hosts = jsondecode(jsonencode(var.domains))
      }]
    }
  }
}

resource "helm_release" "this" {
  count = var.flux_managed ? 0 : 1
  name       = var.name
  repository = var.chart_url
  chart      = var.chart_name
  version    = var.chart_version
  namespace   = var.namespace
  values = [yamlencode(local.values)]
}

resource "kubernetes_manifest" "helm_repo" {
  count = var.flux_managed ? 1 : 0
  manifest = {
    apiVersion = "source.toolkit.fluxcd.io/v1"
    kind       = "HelmRepository"
    metadata = {
      name      = var.chart_name
      namespace = var.namespace
    }
    spec = {
      interval = "5m"
      url      = var.chart_url
    }
  }
}

resource "kubernetes_manifest" "helm_release" {
  count = var.flux_managed ? 1 : 0
  manifest = {
    apiVersion = "helm.toolkit.fluxcd.io/v2"
    kind       = "HelmRelease"
    metadata = {
      name      = var.name
      namespace = var.namespace
    }
    spec = {
      interval = "1m"
      releaseName = var.name
      chart = {
        spec = {
          chart   = var.chart_name
          version = var.chart_version
          sourceRef = {
            kind     = "HelmRepository"
            name     = var.chart_name
            namespace = var.namespace
          }
        }
      }
      targetNamespace = var.namespace
      values = local.values
    }
  }
}
