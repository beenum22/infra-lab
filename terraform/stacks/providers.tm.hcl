generate_hcl "_providers.tf" {
  lets {
    required_providers = { for k in tm_try(global.terraform.providers, []) :
      k => {
        source  = global.terraform.default_providers[k].source
        version = global.terraform.default_providers[k].version
      }
    }

    providers = { for k in tm_try(global.terraform.providers, []) :
      k => global.terraform.default_providers[k].config if k != "helm"  # TODO: Remove this temporary fix for Helm provider config/
    }

    helm_provider = { for k in tm_try(global.terraform.providers, []) :
      k => global.terraform.default_providers[k].config if k == "helm"  # TODO: Remove this temporary fix for Helm provider config/
    }
  }

  content {
    terraform {
      required_version = global.terraform.version
      tm_dynamic "required_providers" {
        attributes = let.required_providers
      }
    }

    tm_dynamic "provider" {
      for_each   = let.providers
      labels     = [provider.key]
      attributes = provider.value
    }

    tm_dynamic "provider" {
      for_each   = let.helm_provider
      labels     = [provider.key]
      content {
        kubernetes = {
          config_path = provider.value.config_path
        }
      }
    }
  }
}