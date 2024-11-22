globals "terraform" {
  providers = [
    "talos",
    "oci",
    "cloudflare",
    # "helm",
    "tailscale"
  ]

  remote_states = {
    stacks = [
      "infra-deployment"
    ]
  }
}

globals {
  oci_image_metadata = {
    version = 2
    externalLaunchOptions = {
      firmware = "UEFI_64"
      networkType = "PARAVIRTUALIZED"
      bootVolumeType = "PARAVIRTUALIZED"
      remoteDataVolumeType = "PARAVIRTUALIZED"
      localDataVolumeType = "PARAVIRTUALIZED"
      launchOptionsSource = "PARAVIRTUALIZED"
      pvAttachmentVersion = 2
      pvEncryptionInTransitEnabled = true
      consistentVolumeNamingEnabled = true
    }
    imageCapabilityData = null
    imageCapsFormatVersion = null
    operatingSystem = "Talos"
    operatingSystemVersion = "v1.8.2"
    additionalMetadata = {
      shapeCompatibilities = [
        {
          internalShapeName = "VM.Standard.A1.Flex"
          ocpuConstraints = null
          memoryConstraints = null
        }
      ]
    }
  }
  talos_prep = {
    machine = {
      certSANs = [
        "talos.moinmoin.fyi",
      ]
    }
  }
  talos_network = {
    machine = {
      sysctls = {
        "net.ipv6.conf.all.forwarding" = 1
      }
      network = {
        interfaces = [
        {
          interface = "eth0"
          dhcpOptions = {
            ipv4 = true
            ipv6 = true
          }
        }
        ]
      }
    }
  }
  talos_tailscale_node = {
    machine = {
      kubelet = {
        nodeIP = {
          validSubnets = [
#             "10.0.0.0/8",
            "100.64.0.0/10",
            "fd7a:115c:a1e0::/48"
          ]
        }
      }
    }
  }

  talos_cni = {
    cluster = {
      network = {
        podSubnets = [
          "10.42.0.0/16",
          "2001:cafe:42:0::/56"
        ]
        serviceSubnets = [
          "10.43.0.0/16",
          "2001:cafe:42:1::/112"
        ]
        cni = {
          name = "none"
        }
      }
    }
  }
}

generate_hcl "_talos.tf" {
  content {
    provider "helm" {
      kubernetes {
        config_path = "./kubeconfig"
      }
    }

    locals {
      talos_tailscale_patch = {
        apiVersion = "v1alpha1"
        kind = "ExtensionServiceConfig"
        name = "tailscale"
        environment = [
          "TS_AUTHKEY=${tailscale_tailnet_key.this.key}"
        ]
      }
      talos_zfs_patch = {
        machine = {
          kernel = {
            modules = [{
              name = "zfs"
            }]
          }
        }
      }
    }

    resource "local_file" "image_metadata" {
      filename = "${terramate.root.path.fs.absolute}/image_metadata.json"
      content  = jsonencode(global.oci_image_metadata)
    }

    # resource "local_file" "init_oci" {
    #   filename = "${terramate.root.path.fs.absolute}/talos-oracle-arm64-v1.8.2-${talos_image_factory_schematic.this.id}.oci"
    #   content  = ""
    # }

    data "oci_objectstorage_namespace" "this" {
      compartment_id = global.infrastructure.oci.compartment_id
    }

    resource "random_id" "bucket" {
      byte_length = 8
    }

    resource "oci_objectstorage_bucket" "images" {
      compartment_id = global.infrastructure.oci.compartment_id
      namespace      = data.oci_objectstorage_namespace.this.namespace
      name           = "images-${random_id.bucket.hex}"
      access_type    = "NoPublicAccess"
      auto_tiering   = "Disabled"
      versioning     = "Disabled"
    }

    resource "null_resource" "prepare_talos_image" {
      provisioner "local-exec" {
        command = <<EOT
          curl -L -o ${terramate.root.path.fs.absolute}/talos-oracle-arm64-v1.8.2-${talos_image_factory_schematic.this.id}.raw.xz https://factory.talos.dev/image/${talos_image_factory_schematic.this.id}/v1.8.2/oracle-arm64.raw.xz
          xz -d ${terramate.root.path.fs.absolute}/talos-oracle-arm64-v1.8.2-${talos_image_factory_schematic.this.id}.raw.xz
          qemu-img convert -f raw -O qcow2 ${terramate.root.path.fs.absolute}/talos-oracle-arm64-v1.8.2-${talos_image_factory_schematic.this.id}.raw ${terramate.root.path.fs.absolute}/talos-oracle-arm64-v1.8.2-${talos_image_factory_schematic.this.id}.qcow2
          tar zcf ${terramate.root.path.fs.absolute}/talos-oracle-arm64-v1.8.2-${talos_image_factory_schematic.this.id}.oci -C ${terramate.root.path.fs.absolute} talos-oracle-arm64-v1.8.2-${talos_image_factory_schematic.this.id}.qcow2 image_metadata.json
        EOT
      }
    }

    resource "oci_objectstorage_object" "this" {
      bucket         = oci_objectstorage_bucket.images.name
      namespace      = data.oci_objectstorage_namespace.this.namespace
      object         = "talos-oracle-arm64-v1.8.2-${talos_image_factory_schematic.this.id}.oci"
      source         = "${terramate.root.path.fs.absolute}/talos-oracle-arm64-v1.8.2-${talos_image_factory_schematic.this.id}.oci"
      content_md5    = filemd5("${terramate.root.path.fs.absolute}/talos-oracle-arm64-v1.8.2-${talos_image_factory_schematic.this.id}.oci")
#       content_md5    = md5("${talos_image_factory_schematic.this.id}-${jsonencode(global.oci_image_metadata)}")
#       depends_on     = [null_resource.prepare_talos_image]  # Ensure the file is downloaded before this runs
      depends_on     = [
        null_resource.prepare_talos_image
      ]
    }

    resource "oci_objectstorage_object" "manual" {
      bucket         = oci_objectstorage_bucket.images.name
      namespace      = data.oci_objectstorage_namespace.this.namespace
      object         = "talos-oracle-arm64-v1.8.2.oci"
      source         = "${terramate.root.path.fs.absolute}/oracle-arm64.oci"
      content_md5    = filemd5("${terramate.root.path.fs.absolute}/oracle-arm64.oci")
#       content_md5    = md5("${talos_image_factory_schematic.this.id}-${jsonencode(global.oci_image_metadata)}")
#       depends_on     = [null_resource.prepare_talos_image]  # Ensure the file is downloaded before this runs
    }

    resource "oci_core_image" "manual" {
      compartment_id = global.infrastructure.oci.compartment_id
      display_name   = "Talos-v1.8.2-arm64-manual"
      launch_mode    = "PARAVIRTUALIZED"

      image_source_details {
        bucket_name              = oci_objectstorage_bucket.images.name
        namespace_name           = data.oci_objectstorage_namespace.this.namespace
        object_name              = "talos-oracle-arm64-v1.8.2.oci"
        operating_system         = "Talos Linux"
        operating_system_version = "v1.8.2"
        source_image_type        = "QCOW2"
        source_type              = "objectStorageTuple"
      }
      lifecycle {
        replace_triggered_by = [oci_objectstorage_object.manual.content_md5]
      }
      timeouts {
        create = "30m"
      }
    }

    resource "oci_core_image" "talos_arm64" {
      compartment_id = global.infrastructure.oci.compartment_id
      display_name   = "Talos-v1.8.2-arm64"
      launch_mode    = "PARAVIRTUALIZED"

      image_source_details {
        bucket_name              = oci_objectstorage_bucket.images.name
        namespace_name           = data.oci_objectstorage_namespace.this.namespace
        object_name              = "talos-oracle-arm64-v1.8.2-${talos_image_factory_schematic.this.id}.oci"
        operating_system         = "Talos Linux"
        operating_system_version = "v1.8.2"
        source_image_type        = "QCOW2"
        source_type              = "objectStorageTuple"
      }
      lifecycle {
        replace_triggered_by = [oci_objectstorage_object.this.content_md5]
      }
      timeouts {
        create = "30m"
      }
    }

    data "oci_identity_availability_domains" "this" {
      compartment_id = global.infrastructure.oci.compartment_id
    }

    data "talos_image_factory_extensions_versions" "this" {
      talos_version = "v1.8.2"
      filters = {
        names = [
          "tailscale",
          "zfs"
        ]
      }
    }

    resource "talos_image_factory_schematic" "this" {
      schematic = yamlencode({
        customization = {
          systemExtensions = {
            officialExtensions = data.talos_image_factory_extensions_versions.this.extensions_info.*.name
          }
        }
      })
    }

    resource "tailscale_tailnet_key" "this" {
      reusable      = true
      ephemeral     = true
      preauthorized = true
      expiry        = 3600
      description   = "Talos Cluster Nodes"
    }

    resource "oci_core_instance" "this" {
      availability_domain = data.oci_identity_availability_domains.this.availability_domains.0.name
      compartment_id      = global.infrastructure.oci.compartment_id
      shape               = "VM.Standard.A1.Flex"

      create_vnic_details {
        subnet_id = "ocid1.subnet.oc1.eu-frankfurt-1.aaaaaaaanx6eguxkndpnxkksmt7igy2dgbjogogg5okqxd3v3chg23wc2nxq"
        assign_public_ip = true
        assign_ipv6ip = true
        # use_ipv6 = true
      }
      metadata = {
        ssh_authorized_keys = null
        user_data           = base64encode(data.talos_machine_configuration.this.machine_configuration)
      }
      source_details {
        source_type = "image"
        source_id   = oci_core_image.manual.id
        boot_volume_size_in_gbs = 50
      }
      shape_config {
        memory_in_gbs = 2
        ocpus = 1
      }
      display_name = "talos-poc"
    }

    resource "cloudflare_record" "talos_endpoint" {
      zone_id = global.infrastructure.cloudflare.zone_id
      name    = "talos.moinmoin.fyi"
      value   = oci_core_instance.this.public_ip
      type    = "A"
      proxied = false
      # ttl     = "60"
    }

    resource "talos_machine_secrets" "this" {}

    data "talos_machine_configuration" "this" {
      cluster_endpoint   = "https://talos.moinmoin.fyi:6443"
      cluster_name       = "talos-poc"
      config_patches     = [yamlencode(global.talos_prep)]
      docs               = false
      examples           = false
      kubernetes_version = "1.31.2"
      talos_version      = "v1.8.2"
      machine_secrets    = talos_machine_secrets.this.machine_secrets
      machine_type       = "controlplane"
    }

    resource "talos_machine_configuration_apply" "this" {
      client_configuration        = talos_machine_secrets.this.client_configuration
      machine_configuration_input = data.talos_machine_configuration.this.machine_configuration
      node = "talos.moinmoin.fyi"
      config_patches     = [
        yamlencode(local.talos_tailscale_patch),
        yamlencode(global.talos_tailscale_node),
        yamlencode(global.talos_cni),
        yamlencode(local.talos_zfs_patch),
        # yamlencode(global.talos_network),
      ]
      depends_on = [oci_core_instance.this]
    }

    resource "time_sleep" "wait_30_seconds" {
      depends_on = [talos_machine_configuration_apply.this]
      create_duration = "30s"
    }

    resource "talos_machine_bootstrap" "this" {
      client_configuration = talos_machine_secrets.this.client_configuration
      endpoint             = "talos.moinmoin.fyi"
      node                 = "talos.moinmoin.fyi"
      depends_on = [
        time_sleep.wait_30_seconds,
        oci_core_instance.this,
        talos_machine_configuration_apply.this,
      ]
    }

    resource "helm_release" "this" {
      name  = "flannel"
      chart = "https://github.com/flannel-io/flannel/releases/latest/download/flannel.tgz"
      namespace = "kube-system"
      set {
        name = "podCidr"
        value = "10.42.0.0/16"
      }
      set {
        name = "podCidrv6"
        value = "2001:cafe:42:0::/56"
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
        oci_core_instance.this,
        talos_machine_bootstrap.this,
        local_sensitive_file.export_kubeconfig
      ]
    }

    # data "talos_cluster_health" "this" {
    #   client_configuration = talos_machine_secrets.this.client_configuration
    #   control_plane_nodes = [
    #     oci_core_instance.this.private_ip
    #   ]
    #   endpoints = [
    #     "talos.moinmoin.fyi"
    #   ]
    #   timeouts = {
    #     read = "30s"
    #   }
    #   skip_kubernetes_checks = true
    #   depends_on = [
    #     talos_machine_bootstrap.this,
    #     helm_release.this
    #   ]
    # }

    data "talos_client_configuration" "this" {
      cluster_name         = "talos-poc"
      client_configuration = talos_machine_secrets.this.client_configuration
      endpoints            = ["talos.moinmoin.fyi"]
    }

    resource "local_sensitive_file" "export_talosconfig" {
      depends_on = [data.talos_client_configuration.this]
      content    = data.talos_client_configuration.this.talos_config
      filename   = "./talosconfig"
    }

    resource "talos_cluster_kubeconfig" "this" {
    depends_on = [
      talos_machine_bootstrap.this
    ]
    client_configuration = talos_machine_secrets.this.client_configuration
    node                 = "talos.moinmoin.fyi"
  }

  resource "local_sensitive_file" "export_kubeconfig" {
      depends_on = [data.talos_client_configuration.this]
      content    = talos_cluster_kubeconfig.this.kubeconfig_raw
      filename   = "./kubeconfig"
    }

#     data "talos_cluster_health" "this" {
#       client_configuration = talos_machine_secrets.this.client_configuration
#       control_plane_nodes = ["10.0.1.124"]
#       skip_kubernetes_checks = true
#       endpoints = ["talos.moinmoin.fyi"]
#     }
  }
}