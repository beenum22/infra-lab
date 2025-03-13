globals "terraform" {
  providers = [
    "oci",
    "external",
    "talos",
    "tailscale",
  ]
}

globals "infrastructure" "oci" {}

globals "infrastructure" "instances" {}

globals "infrastructure" "config" {
  ssh_keys = []
}

generate_hcl "_oci_talos_image.tf" {
  content {
    locals {
      oci_image_shapes = {
        "arm64-VM.Standard.A1.Flex" = {
          arch = "arm64"
          shape = "VM.Standard.A1.Flex"
        }
      }
      oci_talos_images = {
        "arm64-${global.infrastructure.talos.version}" = {
          name = "Talos-arm64-${global.infrastructure.talos.version}"
          arch = "arm64"
          version = global.infrastructure.talos.version
          os = "Talos Linux"
          shapes = [
            "VM.Standard.A1.Flex"
          ]
        }
      }
    }

    data "oci_objectstorage_namespace" "this" {
      compartment_id = global.infrastructure.oci.compartment_id
    }

    data "talos_image_factory_extensions_versions" "this" {
      talos_version = global.infrastructure.talos.version
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

    data "external" "talos_image" {
      for_each = local.oci_talos_images
      program = ["bash", "-c", <<EOT
        if [ ! -f /tmp/oracle-${each.value.arch}-${each.value.version}-${talos_image_factory_schematic.this.id}.qcow2 ]; then
          curl -L -o /tmp/oracle-${each.value.arch}-${each.value.version}-${talos_image_factory_schematic.this.id}.raw.xz https://factory.talos.dev/image/${talos_image_factory_schematic.this.id}/${each.value.version}/oracle-${each.value.arch}.raw.xz
          xz -d /tmp/oracle-${each.value.arch}-${each.value.version}-${talos_image_factory_schematic.this.id}.raw.xz
          qemu-img convert -f raw -O qcow2 /tmp/oracle-${each.value.arch}-${each.value.version}-${talos_image_factory_schematic.this.id}.raw /tmp/oracle-${each.value.arch}-${each.value.version}-${talos_image_factory_schematic.this.id}.qcow2
        fi
        MD5_HASH=$(md5sum /tmp/oracle-${each.value.arch}-${each.value.version}-${talos_image_factory_schematic.this.id}.qcow2 | awk '{print $1}')
        echo "{
          \"file_name\": \"oracle-${each.value.arch}-${each.value.version}-${talos_image_factory_schematic.this.id}.qcow2\",
          \"file_path\": \"/tmp/oracle-${each.value.arch}-${each.value.version}-${talos_image_factory_schematic.this.id}.qcow2\",
          \"file_md5hash\": \"$MD5_HASH\"
        }"
      EOT
      ]
    }

    resource "random_id" "images_bucket" {
      byte_length = 8
    }

    resource "oci_objectstorage_bucket" "images" {
      compartment_id = global.infrastructure.oci.compartment_id
      namespace      = data.oci_objectstorage_namespace.this.namespace
      name           = "custom-images-${random_id.images_bucket.hex}"
      access_type    = "NoPublicAccess"
      auto_tiering   = "Disabled"
      versioning     = "Disabled"
    }

    resource "oci_objectstorage_object" "this" {
      for_each       = local.oci_talos_images
      bucket         = oci_objectstorage_bucket.images.name
      namespace      = data.oci_objectstorage_namespace.this.namespace
      object         = data.external.talos_image[each.key].result.file_name
      source         = data.external.talos_image[each.key].result.file_path
    }

    resource "oci_core_image" "this" {
      for_each       = local.oci_talos_images
      compartment_id = global.infrastructure.oci.compartment_id
      display_name   = each.value.name
      launch_mode    = "PARAVIRTUALIZED"
      image_source_details {
        bucket_name              = oci_objectstorage_bucket.images.name
        namespace_name           = data.oci_objectstorage_namespace.this.namespace
        object_name              = oci_objectstorage_object.this[each.key].object
        operating_system         = each.value.os
        operating_system_version = each.value.version
        source_image_type        = "QCOW2"
        source_type              = "objectStorageTuple"
      }
      timeouts {
        create = "30m"
      }
    }

    data "oci_core_compute_global_image_capability_schemas" "this" {}

    data "oci_core_compute_global_image_capability_schema" "this" {
      compute_global_image_capability_schema_id = data.oci_core_compute_global_image_capability_schemas.this.compute_global_image_capability_schemas[0].id
    }

    data "oci_core_compute_global_image_capability_schemas_versions" "this" {
      compute_global_image_capability_schema_id = data.oci_core_compute_global_image_capability_schema.this.id
    }

    resource "oci_core_compute_image_capability_schema" "custom_image_capability_schema" {
      for_each       = local.oci_talos_images
      compartment_id = global.infrastructure.oci.compartment_id
      compute_global_image_capability_schema_version_name = data.oci_core_compute_global_image_capability_schemas_versions.this.compute_global_image_capability_schema_versions[1].name
      display_name                                        = "Talos-Linux-Capability-Schema"
      image_id                                            = oci_core_image.this[each.key].id

      schema_data = {
        # "Compute.AMD_SecureEncryptedVirtualization" = jsonencode(
        #   {
        #     defaultValue   = false
        #     descriptorType = "boolean"
        #     source         = "IMAGE"
        #   }
        # )
        "Compute.Firmware" = jsonencode(
          {
            defaultValue   = "UEFI_64"
            descriptorType = "enumstring"
            source         = "IMAGE"
            values = [
              # "BIOS",
              "UEFI_64",
            ]
          }
        )
        "Compute.LaunchMode" = jsonencode(
          {
            defaultValue   = "PARAVIRTUALIZED"
            descriptorType = "enumstring"
            source         = "IMAGE"
            values = [
              "NATIVE",
              "EMULATED",
              "PARAVIRTUALIZED",
              "CUSTOM",
            ]
          }
        )
        "Compute.SecureBoot" = jsonencode(
          {
            defaultValue   = false
            descriptorType = "boolean"
            source         = "IMAGE"
          }
        )
        "Network.AttachmentType" = jsonencode(
          {
            defaultValue   = "PARAVIRTUALIZED"
            descriptorType = "enumstring"
            source         = "IMAGE"
            values = [
              "VFIO",
              "PARAVIRTUALIZED",
              "E1000",
            ]
          }
        )
        # "Network.IPv6Only" = jsonencode(
        #   {
        #     defaultValue   = false
        #     descriptorType = "boolean"
        #     source         = "IMAGE"
        #   }
        # )
        "Storage.BootVolumeType" = jsonencode(
          {
            defaultValue   = "PARAVIRTUALIZED"
            descriptorType = "enumstring"
            source         = "IMAGE"
            values = [
              "ISCSI",
              "PARAVIRTUALIZED",
              "SCSI",
              "IDE",
            ]
          }
        )
        "Storage.ConsistentVolumeNaming" = jsonencode(
          {
            defaultValue   = true
            descriptorType = "boolean"
            source         = "IMAGE"
          }
        )
        "Storage.Iscsi.MultipathDeviceSupported" = jsonencode(
          {
            defaultValue   = false
            descriptorType = "boolean"
            source         = "IMAGE"
          }
        )
        "Storage.LocalDataVolumeType" = jsonencode(
          {
            defaultValue   = "PARAVIRTUALIZED"
            descriptorType = "enumstring"
            source         = "IMAGE"
            values = [
              "ISCSI",
              "PARAVIRTUALIZED",
              "SCSI",
              "IDE",
            ]
          }
        )
        "Storage.ParaVirtualization.AttachmentVersion" = jsonencode(
          {
            defaultValue   = 2
            descriptorType = "enuminteger"
            source         = "IMAGE"
            values = [
              1,
              2,
            ]
          }
        )
        "Storage.ParaVirtualization.EncryptionInTransit" = jsonencode(
          {
            defaultValue   = true
            descriptorType = "boolean"
            source         = "IMAGE"
          }
        )
        "Storage.RemoteDataVolumeType" = jsonencode(
          {
            defaultValue   = "PARAVIRTUALIZED"
            descriptorType = "enumstring"
            source         = "IMAGE"
            values = [
              "ISCSI",
              "PARAVIRTUALIZED",
              "SCSI",
              "IDE",
            ]
          }
        )
      }
    }

    resource "oci_core_shape_management" "amphere_shape" {
      # for_each       = local.oci_image_shapes
      for_each = {
        for key, value in flatten([
          for k, v in local.oci_talos_images : [
            for shape in v.shapes : {
              key   = k
              arch  = v.arch
              shape = shape
            }
          ]
        ]) : "${value.key}-${value.shape}" => value
      }
      compartment_id = global.infrastructure.oci.compartment_id
      image_id = oci_core_image.this[each.value.key].id
      shape_name = each.value.shape
    }
  }
}

generate_hcl "_tailscale.tf" {
  content {
    # TODO: This might not be working. Verify the changes here.
    resource "tailscale_acl" "this" {
      acl = jsonencode(
        {
          autoApprovers = {
            routes = {
              "10.244.0.0/16" = [
                "group:admin",
                "tag:talos",
              ]
              "2001:db8:42:0::/56" = [
                "group:admin",
                "tag:talos",
              ]
              "10.96.0.0/12" = [
                "group:admin",
                "tag:talos",
                "tag:k8s",
              ]
              "2001:db8:42:1::/112" = [
                "group:admin",
                "tag:talos",
                "tag:k8s",
              ],
              "10.42.0.0/16" = [
                "group:admin",
                "tag:k3s",
              ]
              "2001:cafe:42:0::/56" = [
                "group:admin",
                "tag:k3s",
              ]
              "10.43.0.0/16" = [
                "group:admin",
                "tag:k3s",
                "tag:k8s",
              ]
              "2001:cafe:42:1::/112" = [
                "group:admin",
                "tag:k3s",
                "tag:k8s",
              ]
            }
            exitNode = [
              "group:admin",
              "tag:k3s",
              "tag:talos",
            ]
          }
          groups = {
            "group:admin" = global.infrastructure.tailscale.acl.admins
            "group:k3s-users" = global.infrastructure.tailscale.acl.k3s_web_apps_consumers
            "group:k3s-developers" = global.infrastructure.tailscale.acl.k3s_api_consumers
            "group:exit-node-users" = global.infrastructure.tailscale.acl.exit_node_consumers
          }
          tagOwners = {
            "tag:talos" = [
              "group:admin"
            ]
            "tag:k3s" = [
              "group:admin"
            ]
            "tag:k8s-operator" = []
            "tag:k8s" = [
              "group:admin",
              "tag:k8s-operator"
            ]
            "tag:k8s-ingress": [
              "group:admin",
              "tag:k8s-operator"
            ],
            "tag:k8s-router": [
              "group:admin",
              "tag:k8s-operator"
            ],
            "tag:admin" = [
              "group:admin"
            ]
          }
          // Declare convenient hostname aliases to use in place of IP addresses.
          hosts = {
            talos-cluster-ipv4 = global.infrastructure.talos.cluster_cidrs[0]
            talos-cluster-ipv6 = global.infrastructure.talos.cluster_cidrs[1]
            talos-service-ipv4 = global.infrastructure.talos.service_cidrs[0]
            talos-service-ipv6 = global.infrastructure.talos.service_cidrs[1]
            k3s-cluster-ipv4 = "10.42.0.0/16"
            k3s-cluster-ipv6 = "2001:cafe:42:0::/56"
            k3s-service-ipv4 = "10.43.0.0/16"
            k3s-service-ipv6 = "2001:cafe:42:1::/112"
            wormhole-ipv4 = "10.43.217.93"
            wormhole-ipv6 = "2001:cafe:42:1::e33d"
            dns-ipv4 = "10.43.249.210"
            dns-ipv6 = "2001:cafe:42:1::f1b6"
            google = "8.8.8.8"
            google-ipv6 = "2001:4860:4860::8888"
            tailscale-dns = "100.100.100.100"
          }
          // Define access control lists for users, groups, autogroups, tags,
          // Tailscale IP addresses, and subnet ranges.
          acls = [
            // Match absolutely everything.
            // Comment this section out if you want to define specific restrictions.
            # {"action": "accept", "src": ["*"], "dst": ["*:*"]},
            // Allow resources in K3s subnets to communicate with each other
#            {
#              action = "accept"
#              src = [
#                "k3s-cluster-ipv4",
#                "k3s-cluster-ipv6",
#                "k3s-service-ipv4",
#                "k3s-service-ipv6",
#              ]
#              dst = [
#                "k3s-cluster-ipv4:*",
#                "k3s-cluster-ipv6:*",
#                "k3s-service-ipv4:*",
#                "k3s-service-ipv6:*",
#              ]
#            },
            // Allow all k3s tagged devices to communicate with each other and cluster subnets
            {
              action = "accept"
              src = [
                "tag:k3s",
                "tag:talos",
                "tag:k8s",
                "k3s-cluster-ipv4",
                "k3s-cluster-ipv6",
                "k3s-service-ipv4",
                "k3s-service-ipv6",
                "talos-cluster-ipv4",
                "talos-cluster-ipv6",
                "talos-service-ipv4",
                "talos-service-ipv6",
              ]
              dst = [
                "tag:k3s:*",
                "tag:talos:*",
                "tag:k8s:*",
                "k3s-cluster-ipv4:*",
                "k3s-cluster-ipv6:*",
                "k3s-service-ipv4:*",
                "k3s-service-ipv6:*",
                "talos-cluster-ipv4:*",
                "talos-cluster-ipv6:*",
                "talos-service-ipv4:*",
                "talos-service-ipv6:*",
              ]
            },
            // Allow admin devices to access everything
            {
              action = "accept"
              src = [
                "group:admin",
              ]
              dst = [
                "autogroup:internet:*",
                "tag:k3s:*",
                "tag:talos:*",
                "tag:k8s:*",
                "tag:k8s-ingress:*",
                "tag:k8s-router:*",
                "tag:k8s-operator:*",
                "k3s-cluster-ipv4:*",
                "k3s-cluster-ipv6:*",
                "k3s-service-ipv4:*",
                "k3s-service-ipv6:*",
                "talos-cluster-ipv4:*",
                "talos-cluster-ipv6:*",
                "talos-service-ipv4:*",
                "talos-service-ipv6:*",
              ]
            },
            // Allow user group to access DNS server and hosted HTTPS services
            {
              action = "accept"
              src = ["group:k3s-users"]
              dst = [
                "wormhole-ipv4:443",
                "wormhole-ipv6:443",
                "dns-ipv4:53",
                "dns-ipv6:53",
                "tag:k8s:443",
                "tag:k8s-ingress:443",
              ]
            },
            {
              action = "accept"
              dst    = [
                "tag:k3s:6443",
                "tag:talos:6443",
              ]
              src    = [
                "group:k3s-developers",
              ]
            },
            // Allow access to Internet through exit nodes
            {
              action = "accept"
              src = [
                "group:exit-node-users",
                "tag:k3s",
                "tag:talos",
              ]
              dst = [
                "autogroup:internet:*",
              ]
            }
          ]
          // Define users and devices that can use Tailscale SSH.
          ssh = [
            // Allow all users to SSH into their own devices in check mode.
            // Comment this section out if you want to define specific restrictions.
            {
              action = "check"
              src = ["autogroup:member"]
              dst = ["autogroup:self"]
              users = ["autogroup:nonroot", "root"]
            },
            // {
            // 	"action": "check",
            // 	"src":    ["group:admin"],
            // 	"dst":    ["tag:k3s"],
            // 	"users":  ["autogroup:nonroot", "root"],
            // },
          ]
          nodeAttrs = [
            {
              attr = [
                "funnel",
              ]
              target = [
                "autogroup:member",
              ]
            }
          ]
          // Test access rules every time they're saved.
          tests = [
            {
              accept = [
                "wormhole-ipv4:443"
              ]
              src = "group:admin"
            },
            {
              accept = [
                "tag:k3s:443",
                "10.43.0.0:53",
                "10.43.0.10:443",
                "10.42.0.20:80",
              ]
              src = "tag:k3s"
            },
            {
              accept = [
                "wormhole-ipv4:443"
              ]
              deny = [
                "8.8.8.8:53"
              ]
              src = "group:k3s-users"
            },
            {
              accept = [
                "tag:k3s:6443"
              ]
              src = "group:k3s-developers"
            },
            {
              accept = [
                "8.8.8.8:53"
              ]
              deny = [
                "10.43.0.0:443"
              ]
              src = "group:exit-node-users"
            }
          ]
        }
      )
    }
  }
}

generate_hcl "_oci.tf" {
  content {
    locals {
      oci_nodes = {
        for node, info in local.nodes : node => info if info.provider == "oracle"
      }
    }

    module "oci_vcn" {
      source         = "${terramate.root.path.fs.absolute}/terraform/modules/infra/oci-vcn"
      compartment_id = global.infrastructure.oci.compartment_id
      name           = tm_replace(global.project.name, "-", "")
      enable_ssh     = true
      enable_ipv4_nat_egress = false
      ssh_ports      = [22, 2203]
    }

    module "oci_instances" {
      source        = "${terramate.root.path.fs.absolute}/terraform/modules/infra/oci-instance"
      for_each      = local.oci_nodes
      name          = each.key
      shape_name    = each.value.provider_config.shape_name
      image_ocid    = each.value.provider_config.image_ocid
      vcpus         = each.value.provider_config.vcpus
      memory        = each.value.provider_config.memory
      boot_volume   = each.value.provider_config.boot_volume
      block_volumes = each.value.provider_config.block_volumes
      subnets       = [
        {
          id            = module.oci_vcn.public_subnet_id
          public_access = true
        }
      ]
      ssh_public_keys = concat(try([trimspace(tls_private_key.this.public_key_openssh)], []), global.infrastructure.config.ssh_keys)
      cloud_init_commands = [
        for cmd in local.ssh_port_config : replace(cmd, "SSH_PORT", each.value.port)
      ]
    }
  }
}

# generate_hcl "_hetzner.tf" {
#   content {
#     locals {
#       hetzner_nodes = {
#         for node, info in local.nodes : node => info if info.provider == "hetzner"
#       }
#     }
#
#     resource "hcloud_ssh_key" "this" {
#       name       = "Terraform Key"
#       public_key = trimspace(tls_private_key.this.public_key_openssh)
#     }
#
#     resource "hcloud_network" "this" {
#       name     = "lab"
#       ip_range = "10.0.0.0/16"
#     }
#
#     resource "hcloud_network_subnet" "this" {
#       type         = "cloud"
#       network_id   = hcloud_network.this.id
#       network_zone = "eu-central"
#       ip_range     = "10.0.0.0/24"
#     }
#
#     moved {
#       from = module.hetzner_instances["hzn-neu-0"]
#       to = module.hetzner_instances["hzn-hel-0"]
#     }
#
#     module "hetzner_instances" {
#       source        = "${terramate.root.path.fs.absolute}/terraform/modules/infra/hetzner-instance"
#       for_each      = local.hetzner_nodes
#       name          = each.key
#       server_type   = each.value.provider_config.server_type
#       image         = each.value.provider_config.image
#       datacenter    = each.value.provider_config.datacenter
#       block_volumes = each.value.provider_config.block_volumes
#       enable_ipv4   = true
#       enable_ipv6   = true
#       subnets       = [
#         hcloud_network.this.id
#       ]
#       ssh_public_keys = [hcloud_ssh_key.this.id]
# #       ssh_public_keys     = concat(try([
# #         trimspace(tls_private_key.this.public_key_openssh)
# #       ], []), global.infrastructure.config.ssh_keys)
#       cloud_init_commands = [
#         for cmd in local.ssh_port_config : replace(cmd, "SSH_PORT", each.value.port)
#       ]
#     }
#
#     moved {
#       from = hcloud_server.this["hzn-neu-k3s-0"]
#       to = module.hetzner_instances["hzn-neu-0"].hcloud_server.this
#     }
#
#     moved {
#       from = hcloud_volume.this["hzn-neu-k3s-0"]
#       to = module.hetzner_instances["hzn-neu-0"].hcloud_volume.this["20"]
#     }
#   }
# }
