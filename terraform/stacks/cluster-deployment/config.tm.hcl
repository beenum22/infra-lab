globals "terraform" {
  providers = [
    "tailscale",
    "ssh",
    "ovh",
    "cloudflare",
    #
    "oci",
    "talos",
    "helm",
    "external",
    "null",
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

    # resource "cloudflare_record" "k3s_api_ipv4" {
    #   zone_id = global.infrastructure.cloudflare.zone_id
    #   name    = global.infrastructure.k3s.api_host.domain
    #   value   = data.terraform_remote_state.infra_configuration_stack_state.outputs.tailscale_ips[global.infrastructure.k3s.api_host.target].ipv4
    #   type    = "A"
    #   proxied = false
    # }

    # resource "cloudflare_record" "k3s_api_ipv6" {
    #   zone_id = global.infrastructure.cloudflare.zone_id
    #   name    = global.infrastructure.k3s.api_host.domain
    #   value   = data.terraform_remote_state.infra_configuration_stack_state.outputs.tailscale_ips[global.infrastructure.k3s.api_host.target].ipv6
    #   type    = "AAAA"
    #   proxied = false
    # }

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
      api_host = global.infrastructure.k3s.api_host.domain
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
            server                     = "https://${global.infrastructure.k3s.api_host.domain}:6443"
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

generate_hcl "_talos_providers.tf" {
  # TODO: Remove after migrating away from k3s or fixing the provider configuration
  content {
    provider "helm" {
      alias = "talos"
    }
  }
}

generate_hcl "_talos_cluster.tf" {
  condition = global.feature_toggles.enable_talos == true
  content {
    resource "talos_machine_secrets" "this" {
      talos_version = global.infrastructure.talos.version
    }

    data "helm_template" "flannel" {
      name  = "flannel"
      chart = "https://github.com/flannel-io/flannel/releases/latest/download/flannel.tgz"
      namespace = "kube-system"
      set {
        name = "podCidr"
        value = global.infrastructure.talos.cluster_cidrs[0]
      }
      set {
        name = "podCidrv6"
        value = global.infrastructure.talos.cluster_cidrs[1]
      }
      set {
        name = "flannel.backend"
        value = "host-gw"
      }
      set {
        name  = "flannel.args[0]"
        value = "--iface=tailscale0"
      }
      set {
        name  = "flannel.args[1]"
        value = "--ip-masq"
      }
      set {
        name  = "flannel.args[2]"
        value = "--kube-subnet-mgr"
      }
    }

    module "talos_node" {
      for_each = local.talos_nodes
      source = "${terramate.root.path.fs.absolute}/terraform/modules/infra/talos-node"
      talos_version = global.infrastructure.talos.version
      k8s_version = global.infrastructure.talos.k8s_version
      machine_secret = talos_machine_secrets.this
      machine_name = each.key
      machine_type = each.value.talos_config.machine_type
      machine_domain = cloudflare_dns_record.nodes[each.key].name
      machine_bootstrap = each.value.talos_config.bootstrap
      machine_network_overlay = {
        tailscale = {
          advertise_exit_node = each.value.tailscale_config.exit_node
          accept_routes = true
          accept_dns = false
          tailnet = global.infrastructure.tailscale.tailnet
        }
      }
      machine_cert_sans = []
      cluster_config = {
        cluster = {
          etcd = {
            advertisedSubnets = global.infrastructure.tailscale.cidrs
          }
          network = {
            podSubnets = global.infrastructure.talos.cluster_cidrs
            serviceSubnets = global.infrastructure.talos.service_cidrs
            cni = {
              name = "none"
            }
          }
          inlineManifests = [
            {
              name = "flannel"
              contents = data.helm_template.flannel.manifest
            },
          ]
        }
      }
      cluster_endpoint   = global.infrastructure.talos.cluster_endpoint
      cluster_name       = global.infrastructure.talos.cluster_name
      cluster_advertised_subnets = global.infrastructure.tailscale.cidrs
      depends_on = [
        oci_core_instance.this,
      ]
    }

    data "talos_client_configuration" "this" {
      cluster_name = global.infrastructure.talos.cluster_name
      client_configuration = talos_machine_secrets.this.client_configuration
      endpoints = [global.infrastructure.talos.cluster_endpoint]
    }

    resource "local_sensitive_file" "export_talosconfig" {
      content    = data.talos_client_configuration.this.talos_config
      filename   = pathexpand("~/.talos/talosconfig")
    }

    resource "talos_cluster_kubeconfig" "this" {
      client_configuration = talos_machine_secrets.this.client_configuration
      node                 = global.infrastructure.talos.cluster_endpoint
    }

    resource "local_sensitive_file" "export_kubeconfig" {
      content    = talos_cluster_kubeconfig.this.kubeconfig_raw
      filename   = pathexpand("~/.kube/talosconfig")
    }
  }
}

generate_hcl "_oci_talos_vms.tf" {
  condition = global.feature_toggles.enable_talos == true
  content {
    locals {
      talos_nodes = global.infrastructure.talos_instances
      bootstrap_node = {
        for node, info in local.talos_nodes : node => info if info.talos_config.bootstrap == true
      }
      oci_talos_nodes = {
        for node, info in local.talos_nodes : node => info if info.provider == "oracle"
      }
    }

    data "oci_identity_availability_domains" "this" {
      compartment_id = global.infrastructure.oci.compartment_id
    }

    data "talos_machine_configuration" "oci" {
      for_each = local.oci_talos_nodes
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
      talos_version      = global.infrastructure.talos.version
      kubernetes_version = global.infrastructure.talos.k8s_version
      machine_secrets    = talos_machine_secrets.this.machine_secrets
      machine_type       = each.value.talos_config.machine_type
    }

    resource "oci_core_instance" "this" {
      for_each = local.oci_talos_nodes
      display_name = each.key
      availability_domain = data.oci_identity_availability_domains.this.availability_domains.0.name
      compartment_id      = global.infrastructure.oci.compartment_id
      shape               = each.value.provider_config.shape_name

      create_vnic_details {
        subnet_id = data.terraform_remote_state.infra_deployment_stack_state.outputs.oci_public_subnet_id
        assign_public_ip = true
        assign_ipv6ip = true
        # use_ipv6 = true
      }
      metadata = {
        ssh_authorized_keys = null
        user_data           = base64encode(data.talos_machine_configuration.oci[each.key].machine_configuration)
      }
      source_details {
        source_type = "image"
        source_id   = data.terraform_remote_state.infra_deployment_stack_state.outputs.oci_talos_image_ids["arm64-${each.value.talos_config.version}"]
        boot_volume_size_in_gbs = each.value.provider_config.boot_volume
      }
      shape_config {
        memory_in_gbs = each.value.provider_config.memory
        ocpus = each.value.provider_config.vcpus
      }
    }

    resource "oci_core_volume" "this" {
      for_each = { for item in flatten([
        for node, info in local.oci_talos_nodes : [
          for index, vol in info.provider_config.block_volumes : {
            node   = node
            name   = "${node}-volume-${index}"
            volume = vol
          }
        ]
      ]) : "${item.name}" => item }
      availability_domain = data.oci_identity_availability_domains.this.availability_domains.0.name
      compartment_id      = global.infrastructure.oci.compartment_id
      display_name        = each.value.name
      size_in_gbs         = each.value.volume
    }

    resource "oci_core_volume_attachment" "this" {
      for_each = { for item in flatten([
        for node, info in local.oci_talos_nodes : [
          for index, vol in info.provider_config.block_volumes : {
            node   = node
            name   = "${node}-volume-${index}"
            volume = vol
          }
        ]
      ]) : "${item.name}" => item }
      attachment_type = "paravirtualized"
      instance_id     = oci_core_instance.this[each.value.node].id
      volume_id       = oci_core_volume.this[each.key].id
      use_chap        = false
    }

    resource "cloudflare_dns_record" "endpoint" {
      for_each = local.oci_talos_nodes
      zone_id = global.infrastructure.cloudflare.zone_id
      name    = global.infrastructure.talos.cluster_endpoint
      content = oci_core_instance.this[each.key].public_ip
      comment = "Talos Cluster Endpoint"
      type    = "A"
      proxied = false
      ttl     = "60"
    }

    resource "cloudflare_dns_record" "nodes" {
      for_each = local.oci_talos_nodes
      zone_id = global.infrastructure.cloudflare.zone_id
      name    = global.infrastructure.talos_instances[each.key].hostname
      content = oci_core_instance.this[each.key].public_ip
      comment = "Talos Cluster Node"
      type    = "A"
      proxied = false
      ttl     = "60"
    }
  }
}
