/*
WORKAROUND: jsondecode(jsonencode()) on line 85 is used to fix Kubernetes provider inconsistent 
result errors when applying complex nested arrays to Helm values. This forces consistent object 
serialization. Only needed for arrays, not simple objects.
Reference: https://github.com/hashicorp/terraform-provider-kubernetes/issues/1928
*/
locals {
  values = {
    persistence = {
      enabled = true
      storageClass = var.storage_class
    }
    pod = {
      kind = "Deployment"  # Change to Daemonset when the storage is set to MySQL/Postgres
      strategy = {
        type = "Recreate"
      }
      annotations = {
        "authelia.io/oidc-clients-hash" = sha256(jsonencode(var.oidc_clients))
        "authelia.io/users-hash" = sha256(kubernetes_secret.this.data["users_database.yml"])
      }
      extraVolumes = [
        {
          name = "users"
          secret = {
            secretName = "${var.name}-users"
            items = [{
                key = "users_database.yml"
                path = "users_database.yml"
            }]
          }
        },
      ]
      extraVolumeMounts = [
        {
          name      = "users"
          mountPath = "/config/mounts/users_database.yml"
          subPath   = "users_database.yml"
        },
      ]
    }
    ingress = {
      enabled = true
      annotations = {
        "cert-manager.io/cluster-issuer" = var.issuer
      }
      className = var.ingress_class
      tls = {
        enabled = true
        secret = "${var.name}-tls"
      }
      rulesOverride = [
        for domain in var.domains : {
          host = domain
          path = "/"
        }
      ]
    }
    configMap = {
      storage = {
        local = {
          enabled = true
        }
      }
      notifier = {
        filesystem = {
          enabled = true
        }
      }

      authentication_backend = {
        file = {
          enabled = true
          path = "/config/mounts/users_database.yml"
          watch = true
        }
      }
      session = {
        cookies = [
          for domain in var.domains : {
            subdomain = ""
            domain    = domain
            path      = ""
          }
        ]
      }
      telemetry = {
        metrics = {
          enabled = false
        }
      }
      log = {
        level = "info"
      }
      access_control = {
        default_policy = "deny"
        rules = concat([
          for domain in var.domains : {
            domain = domain
            policy = "one_factor"
            subject = ["group:admins"]
          }
        ], [
          {
            domain = "*.moinmoin.fyi"
            policy = "one_factor"
            # subject = ["group:admins"]
          }
        ])
      }
      identity_providers = {
        oidc = {
          enabled = true
          jwks = [
            {
              key_id = "main"
              algorithm = "RS256"
              use = "sig"
              key = {
                value = tls_private_key.oidc_jwks.private_key_pem
              }
            }
          ]
          claims_policies = {
            kubectl-oidc-login = {
              id_token = ["groups", "email"]
            }
          }
          authorization_policies = var.oidc_authorization_policies
          cors = {
            endpoints = [
              "authorization",
              "token",
              "revocation",
              "introspection",
              "userinfo",
            ]
            allowed_origins_from_client_redirect_uris = true
          }
          clients = jsondecode(jsonencode(var.oidc_clients))
        }
      }
    }
  }
}

resource "tls_private_key" "oidc_jwks" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "kubernetes_secret" "this" {
  metadata {
    name      = "${var.name}-users"
    namespace = var.namespace
  }
  data = {
    "users_database.yml" = yamlencode(var.credentials)
  }
  type = "Opaque"
}

resource "kubernetes_secret" "oidc_config" {
  metadata {
    name      = "${var.name}-oidc-config"
    namespace = var.namespace
  }
  data = {
    "configuration.oidc.yaml" = yamlencode({
      identity_providers = {
        oidc = {
          enabled = true
          jwks = [
            {
              key_id = "main"
              algorithm = "RS256"
              use = "sig"
              key = {
                value = tls_private_key.oidc_jwks.private_key_pem
              }
            }
          ]
          # cors = {
          #   endpoints = [
          #     # "authorization",
          #     # "token",
          #     # "revocation",
          #     # "introspection",
          #   ]
          #   allowed_origins_from_client_redirect_uris = false
          # }
          clients = var.oidc_clients
        }
      }
    })
  }
  type = "Opaque"
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
      values = jsondecode(jsonencode(local.values))
    }
  }
}
