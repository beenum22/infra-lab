globals "terraform" {
  providers = [
    "tailscale",
    "ssh",
    "ovh"
  ]

  remote_states = {
    stacks = [
      "infra-deployment",
      "infra-configuration"
    ]
  }
}

generate_hcl "_certificates.tf" {
  content {
    locals {
      certificates_names = ["client-ca", "server-ca", "request-header-key-ca"]
      generated_ca_keys = {
        for name in local.certificates_names :
        "${name}.key" => tls_private_key.kubernetes_ca[name].private_key_pem
      }
      generated_tls_config = merge(
        {
          for name in local.certificates_names :
          "${name}.key" => tls_private_key.kubernetes_ca[name].private_key_pem
        },
        {
          for name in local.certificates_names :
          "${name}.crt" => tls_self_signed_cert.kubernetes_ca_certs[name].cert_pem
        }
      )
    }

    resource "tls_private_key" "kubernetes_ca" {
      for_each = toset(local.certificates_names)
      algorithm   = "ECDSA"
      ecdsa_curve = "P384"
    }

    resource "tls_self_signed_cert" "kubernetes_ca_certs" {
      for_each = toset(local.certificates_names)
      validity_period_hours = 876600 # 100 years
      allowed_uses          = ["digital_signature", "key_encipherment", "cert_signing"]
      private_key_pem       = tls_private_key.kubernetes_ca[each.key].private_key_pem
      is_ca_certificate     = true
      subject {
        common_name = "k3s-${each.value}"
      }
    }

    resource "tls_private_key" "admin" {
      algorithm   = "ECDSA"
      ecdsa_curve = "P384"
    }

    resource "tls_cert_request" "admin" {
      private_key_pem = tls_private_key.admin.private_key_pem
      subject {
        common_name  = "system:admin"
        organization = "system:masters"
      }
    }

    resource "tls_locally_signed_cert" "admin" {
      cert_request_pem   = tls_cert_request.admin.cert_request_pem
      ca_private_key_pem = tls_private_key.kubernetes_ca["client-ca"].private_key_pem
      ca_cert_pem        = tls_self_signed_cert.kubernetes_ca_certs["client-ca"].cert_pem
      validity_period_hours = 876600
      allowed_uses = [
        "key_encipherment",
        "digital_signature",
        "client_auth"
      ]
    }
  }
}

generate_hcl "_k3s.tf" {
  lets {
    init_node = {
      for node, info in global.infrastructure.instances : node => info if info.k3s_config.init == true
    }

    other_nodes = {
      for node, info in global.infrastructure.instances : node => info if info.k3s_config.init == false
    }
  }

  content {
    locals {
      use_tailscale_ipv6 = global.infrastructure.config.use_tailscale_ipv6
    }

    resource "random_password" "k3s_secret" {
      length           = 16
      special          = true
    }

    module "k3s_init" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/infra/k3s"
      for_each = let.init_node
      k3s_version = each.value.k3s_config.version
      hostname = each.key
      cluster_init = each.value.k3s_config.init
      cluster_role = each.value.k3s_config.role
      api_host = each.key
      token = nonsensitive(random_password.k3s_secret.result)
      tls_config = local.generated_tls_config
      kubeconfig = null
      node_labels = each.value.k3s_config.node_labels
      tailnet = global.infrastructure.tailscale.tailnet
      graceful_destroy = false
      connection_info = {
        user = "k3s"
        host = each.key
        port = each.value.port
        private_key = data.terraform_remote_state.infra_deployment_stack_state.outputs.ssh_private_key
      }
    }

    module "k3s" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/infra/k3s"
      for_each = let.other_nodes
      k3s_version = each.value.k3s_config.version
      hostname = each.key
      cluster_init = each.value.k3s_config.init
      cluster_role = each.value.k3s_config.role
      api_host = global.infrastructure.k3s.api_host
      token = nonsensitive(random_password.k3s_secret.result)
      kubeconfig = local.kubeconfig
      node_labels = each.value.k3s_config.node_labels
      tailnet = global.infrastructure.tailscale.tailnet
      graceful_destroy = true
      connection_info = {
        user = "k3s"
        host = each.key
        port = each.value.port
        private_key = data.terraform_remote_state.infra_deployment_stack_state.outputs.ssh_private_key
      }
    }

    output "k3s" {
      value = merge(
        try(module.k3s_init, {}),
        try(module.k3s, {})
      )
    }

    locals {
      kubeconfig = yamlencode({
        apiVersion = "v1"
        clusters = [{
          cluster = {
            certificate-authority-data = base64encode(tls_self_signed_cert.kubernetes_ca_certs["server-ca"].cert_pem)
            server                     = "https://${global.infrastructure.k3s.api_host}:6443"
          }
          name = "default"
        }]
        contexts = [{
          context = {
            cluster = "default"
            user : "default"
          }
          name = "default"
        }]
        current-context = "default"
        kind            = "Config"
        preferences     = {}
        users = [{
          user = {
            client-certificate-data : base64encode(tls_locally_signed_cert.admin.cert_pem)
            client-key-data : base64encode(tls_private_key.admin.private_key_pem)
          }
          name : "default"
        }]
      })
    }

    resource "local_file" "copy_kubeconfig" {
      content  = local.kubeconfig
      filename = "${pathexpand("~")}/.kube/config"
      file_permission = "0700"
    }

    output "kubeconfig" {
      value = local.kubeconfig
      sensitive = true
    }

  }
}
