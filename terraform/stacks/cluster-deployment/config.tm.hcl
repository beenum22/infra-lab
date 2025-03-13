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
      kubernetes {
        config_path = "~/.kube/talosconfig"
      }
    }

    provider "kubernetes" {
      alias = "talos"
      config_path = "~/.kube/talosconfig"
    }
  }
}

generate_hcl "_talos_cluster.tf" {
  condition = global.feature_toggles.enable_talos == true
  content {
    locals {
      talos_init = {
        machine = {
          certSANs = [
            global.infrastructure.talos.cluster_endpoint,
          ]
        }
      }
      # talos_tailscale_init = {
      #   apiVersion = "v1alpha1"
      #   kind = "ExtensionServiceConfig"
      #   name = "tailscale"
      #   environment = [
      #     "TS_AUTHKEY=${tailscale_tailnet_key.this[each.key].key}",
      #     # "TS_ROUTES=${join(",", local.node_cidrs[each.key].node_cidrs)}",
      #     # "TS_EXTRA_ARGS=--reset --accept-routes=true${each.value.tailscale_config.exit_node ? " --advertise-exit-node" : ""}",
      #     # "TS_ACCEPT_DNS=true",
      #     # "TS_USERSPACE=false",
      #     "TS_AUTH_ONCE=true"
      #   ]
      # }
      talos_zfs_patch = {
        machine = {
          kernel = {
            modules = [{
              name = "zfs"
            }]
          }
        }
      }
      talos_kubelet = {
        machine = {
          kubelet = {
            nodeIP = {
              validSubnets = global.infrastructure.tailscale.cidrs
            }
          }
        }
      }
      talos_cni = {
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
        }
      }
      talos_sysctl = {
        machine = {
          sysctls = {
            "net.ipv4.ip_forward" = 1
            "net.ipv6.conf.all.forwarding" = 1
          }
        }
      }
    }

    resource "talos_machine_secrets" "this" {
      talos_version = global.infrastructure.talos.version
    }

    # resource "talos_machine_configuration_apply" "this" {
    #   for_each = local.oci_talos_nodes
    #   client_configuration        = talos_machine_secrets.this.client_configuration
    #   machine_configuration_input = data.talos_machine_configuration.oci[each.key].machine_configuration
    #   node = global.infrastructure.talos_instances[each.key].hostname
    #   config_patches     = [
    #     yamlencode({
    #       machine = {
    #       certSANs = [
    #         global.infrastructure.talos.cluster_endpoint,
    #         global.infrastructure.talos_instances[each.key].hostname,
    #       ]
    #     }
    #     }),
    #     yamlencode({
    #       apiVersion = "v1alpha1"
    #       kind = "ExtensionServiceConfig"
    #       name = "tailscale"
    #       environment = [
    #         "TS_AUTHKEY=${tailscale_tailnet_key.this[each.key].key}"
    #       ]
    #     }),
    #     # yamlencode(local.talos_tailscale_patch),
    #     yamlencode(local.talos_kubelet),
    #     yamlencode(local.talos_cni),
    #     yamlencode(local.talos_zfs_patch),
    #     # yamlencode(global.talos_network),
    #   ]
    #   depends_on = [oci_core_instance.this]
    # }

    data "talos_machine_configuration" "machine_init" {
      for_each = local.oci_talos_nodes
      cluster_endpoint   = "https://${global.infrastructure.talos.cluster_endpoint}:6443"
      cluster_name       = global.infrastructure.talos.cluster_name
      talos_version      = global.infrastructure.talos.version
      kubernetes_version = global.infrastructure.talos.k8s_version
      machine_secrets    = talos_machine_secrets.this.machine_secrets
      machine_type       = each.value.talos_config.machine_type
      config_patches     = [
        yamlencode({
          machine = {
            certSANs = [
              global.infrastructure.talos.cluster_endpoint,
              global.infrastructure.talos_instances[each.key].hostname
            ]
            sysctls = {
              "net.ipv4.ip_forward" = 1
              "net.ipv6.conf.all.forwarding" = 1
            }
            kubelet = {
              nodeIP = {
                validSubnets = global.infrastructure.tailscale.cidrs
              }
            }
            kernel = {
              modules = [{
                name = "zfs"
              }]
            }
          }
        }),
        yamlencode({
          apiVersion = "v1alpha1"
          kind = "ExtensionServiceConfig"
          name = "tailscale"
          environment = [
            "TS_AUTHKEY=${tailscale_tailnet_key.this[each.key].key}",
            # "TS_AUTH_ONCE=true"
          ]
        }),
        yamlencode({
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
          }
        }),
      ]
    }

    # data "talos_machine_configuration" "cluster_init" {
    #   cluster_endpoint   = "https://${global.infrastructure.talos.cluster_endpoint}:6443"
    #   cluster_name       = global.infrastructure.talos.cluster_name
    #   talos_version      = global.infrastructure.talos.version
    #   kubernetes_version = global.infrastructure.talos.k8s_version
    #   machine_secrets    = talos_machine_secrets.this.machine_secrets
    #   machine_type       = "controlplane"
    #   config_patches     = [
    #     yamlencode({
    #       cluster = {
    #         etcd = {
    #           advertisedSubnets = global.infrastructure.tailscale.cidrs
    #         }
    #         network = {
    #           podSubnets = global.infrastructure.talos.cluster_cidrs
    #           serviceSubnets = global.infrastructure.talos.service_cidrs
    #           cni = {
    #             name = "none"
    #           }
    #         }
    #       }
    #     }),
    #   ]
    # }

    resource "talos_machine_configuration_apply" "machine_init" {
      for_each = local.oci_talos_nodes
      client_configuration = talos_machine_secrets.this.client_configuration
      machine_configuration_input = data.talos_machine_configuration.machine_init[each.key].machine_configuration
      node = global.infrastructure.talos_instances[each.key].hostname
    }

    data "tailscale_device" "this" {
      for_each = local.oci_talos_nodes
      name     = "${each.key}.${global.infrastructure.tailscale.tailnet}"
      wait_for = "60s"
      depends_on = [
        talos_machine_configuration_apply.machine_init,
      ]
    }

    # resource "talos_machine_configuration_apply" "cluster_init" {
    #   client_configuration = talos_machine_secrets.this.client_configuration
    #   machine_configuration_input = data.talos_machine_configuration.cluster_init.machine_configuration
    #   node = global.infrastructure.talos.cluster_endpoint
    # }

    resource "time_sleep" "wait_30_seconds" {
      # depends_on = [talos_machine_configuration_apply.this]
      create_duration = "30s"
    }

    resource "talos_machine_bootstrap" "this" {
      for_each = local.bootstrap_node
      client_configuration = talos_machine_secrets.this.client_configuration
      endpoint             = global.infrastructure.talos.cluster_endpoint
      node                 = global.infrastructure.talos_instances[each.key].hostname
      depends_on = [
        time_sleep.wait_30_seconds,
        talos_machine_configuration_apply.machine_init,
        # oci_core_instance.this,
        # talos_machine_configuration_apply.this,
      ]
    }

    data "talos_machine_configuration" "tailscale_config" {
      for_each = local.oci_talos_nodes
      cluster_endpoint   = "https://${global.infrastructure.talos.cluster_endpoint}:6443"
      cluster_name       = global.infrastructure.talos.cluster_name
      talos_version      = global.infrastructure.talos.version
      kubernetes_version = global.infrastructure.talos.k8s_version
      machine_secrets    = talos_machine_secrets.this.machine_secrets
      machine_type       = each.value.talos_config.machine_type
      config_patches     = concat(data.talos_machine_configuration.machine_init[each.key].config_patches, [
        # NOTE: This is a workaround to add routes for IPv4 Node CIDRs.
        # yamlencode({
        #   machine = {
        #     network = {
        #       interfaces = [{
        #         interface = "tailscale0"
        #         routes = [ for node, info in local.talos_nodes : {
        #           network = local.node_cidrs[node].node_cidrs[0]
        #           # gateway = data.tailscale_device.this[node].addresses[0]
        #         } if node != each.key ]
        #       }]
        #     }
        #   }
        # }),
        yamlencode({
          apiVersion = "v1alpha1"
          kind = "ExtensionServiceConfig"
          name = "tailscale"
          environment = [
            # "TS_AUTHKEY=${tailscale_tailnet_key.this[each.key].key}",
            "TS_ROUTES=${join(",", local.node_cidrs[each.key].node_cidrs)}",
            # "TS_EXTRA_ARGS=--reset --accept-routes=true${each.value.tailscale_config.exit_node ? " --advertise-exit-node" : ""}",
            # "TS_EXTRA_ARGS=--reset --accept-routes=true${each.value.tailscale_config.exit_node ? " --advertise-exit-node" : ""}",
            "TS_EXTRA_ARGS=--reset --accept-routes=true${each.value.tailscale_config.exit_node ? " --advertise-exit-node" : ""}",
            # "TS_EXTRA_ARGS=--accept-routes",
            # "TS_ACCEPT_DNS=true",
            "TS_USERSPACE=false",
            # "TS_AUTH_ONCE=true"
          ]
        }),
      ])
    }

    resource "talos_machine_configuration_apply" "tailscale_config" {
      for_each = local.oci_talos_nodes
      client_configuration        = talos_machine_secrets.this.client_configuration
      machine_configuration_input = data.talos_machine_configuration.tailscale_config[each.key].machine_configuration
      node = global.infrastructure.talos_instances[each.key].hostname
    }

    data "talos_client_configuration" "this" {
      cluster_name = global.infrastructure.talos.cluster_name
      client_configuration = talos_machine_secrets.this.client_configuration
      endpoints = [global.infrastructure.talos.cluster_endpoint]
    }

    resource "local_sensitive_file" "export_talosconfig" {
      content    = data.talos_client_configuration.this.talos_config
      filename   = "${pathexpand("~")}/.talos/talosconfig"
    }

    resource "talos_cluster_kubeconfig" "this" {
      depends_on = [
        talos_machine_bootstrap.this
      ]
      client_configuration = talos_machine_secrets.this.client_configuration
      node                 = global.infrastructure.talos.cluster_endpoint
    }

    resource "local_sensitive_file" "export_kubeconfig" {
      content    = talos_cluster_kubeconfig.this.kubeconfig_raw
      filename   = "${pathexpand("~")}/.kube/talosconfig"
    }

    # TODO: It runs before the bootstrap is in a good state. Might need to fix.
    resource "helm_release" "flannel" {
      provider = helm.talos
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
      depends_on = [
        # oci_core_instance.this,
        talos_machine_bootstrap.this,
        # local_sensitive_file.export_kubeconfig
        talos_cluster_kubeconfig.this,
      ]
    }

    # data "talos_cluster_health" "this" {
    #   for_each = local.talos_nodes
    #   client_configuration = talos_machine_secrets.this.client_configuration
    #   control_plane_nodes = flatten([
    #     for node, info in data.tailscale_device.this : info.addresses if local.talos_nodes[node].talos_config.machine_type == "controlplane"
    #   ])
    #   endpoints = [
    #     global.infrastructure.talos.cluster_endpoint
    #   ]
    #   timeouts = {
    #     read = "30s"
    #   }
    #   skip_kubernetes_checks = true
    #   depends_on = [
    #     talos_machine_bootstrap.this,
    #     # helm_release.this
    #   ]
    # }

    data "kubernetes_nodes" "this" {
      provider = kubernetes.talos
      depends_on = [
        talos_machine_bootstrap.this,
      ]
    }

    locals {
      node_cidrs = {
        for node in data.kubernetes_nodes.this.nodes : node.metadata[0].name => {node_cidrs = tolist(node.spec[0].pod_cidrs)}
      }
    }

    output "talos_node_cidrs" {
      value = local.node_cidrs
    }

    output "talos_node_tailscale_ips" {
      value = { for node, info in data.tailscale_device.this : node => info.addresses }
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
        # source_id   = oci_core_image.this["arm64-${each.value.talos_config.version}"].id
        source_id   = data.terraform_remote_state.infra_deployment_stack_state.outputs.oci_talos_image_ids["arm64-${each.value.talos_config.version}"]
        boot_volume_size_in_gbs = each.value.provider_config.boot_volume
      }
      shape_config {
        memory_in_gbs = each.value.provider_config.memory
        ocpus = each.value.provider_config.vcpus
      }
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

    # resource "cloudflare_record" "endpoint" {
    #   for_each = local.oci_talos_nodes
    #   zone_id = global.infrastructure.cloudflare.zone_id
    #   name    = global.infrastructure.talos.cluster_endpoint
    #   value   = oci_core_instance.this[each.key].public_ip
    #   type    = "A"
    #   proxied = false
    #   # ttl     = "60"
    # }

    # resource "cloudflare_record" "nodes" {
    #   for_each = local.oci_talos_nodes
    #   zone_id = global.infrastructure.cloudflare.zone_id
    #   name    = global.infrastructure.talos_instances[each.key].hostname
    #   value   = oci_core_instance.this[each.key].public_ip
    #   type    = "A"
    #   proxied = false
    #   # ttl     = "60"
    # }

    resource "tailscale_tailnet_key" "this" {
      for_each      = local.oci_talos_nodes
      reusable      = true  # TODO: Check if it can be disabled
      ephemeral     = true
      preauthorized = true
      expiry        = 3600
      description   = "Talos Cluster Node - ${each.key}"
      tags          = ["tag:talos"]
    }
  }
}
