generate_hcl "_talos_init.tf" {
  content {
    resource "talos_machine_secrets" "this" {}

    data "talos_machine_configuration" "this" {
      for_each = local.talos_nodes
      cluster_endpoint   = "https://${global.infrastructure.talos.cluster_endpoint}:6443"
      cluster_name       = global.infrastructure.talos.cluster_name
      config_patches     = [yamlencode({
        machine = {
          certSANs = [
            global.infrastructure.talos.cluster_endpoint,
            global.infrastructure.talos_instances[each.key].hostname
          ]
        }
      })]
      talos_version      = each.value.talos_config.version
      # kubernetes_version = each.value.talos_config.k8s_version
      machine_secrets    = talos_machine_secrets.this.machine_secrets
      machine_type       = each.value.talos_config.machine_type
    }

    output "talos_machine_secrets" {
      value = talos_machine_secrets.this
      sensitive = true
    }

    output "talos_machine_configurations" {
      value = data.talos_machine_configuration.this
      sensitive = true
    }
  }
}