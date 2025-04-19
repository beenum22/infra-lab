# NOTE: If needed, find the Hetnzer VM setup code in c6bb21d1daef7f005d3e15b9b695b5a6172a8278
globals "terraform" {
  providers = [
    "tailscale",
    "cloudflare",
    "oci",
    "talos",
    "helm",
    "external",
  ]

  remote_states = {
    stacks = [
      "infra-deployment",
    ]
  }
}

generate_hcl "_talos_cluster.tf" {
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
          allowSchedulingOnControlPlanes = true
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
        cloudflare_dns_record.nodes,
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
      filename   = pathexpand("~/.kube/config")
    }
  }
}

generate_hcl "_oci_talos_vms.tf" {
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

    output "talos" {
      value = {
        for node, info in local.talos_nodes : node => {
          node_cidrs = split(",", module.talos_node[node].node_cidrs)
          tailscale_ips = module.talos_node[node].node_tailscale_ips
          hostname = cloudflare_dns_record.nodes[node].name
        }
      }
    }
    
    output "talos_kubeconfig" {
      value = talos_cluster_kubeconfig.this.kubeconfig_raw
      sensitive = true
    }
  }
}
