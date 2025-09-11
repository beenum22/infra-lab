globals "terraform" {
  providers = [
    "oci",
    "external",
    "talos",
    "tailscale",
    "cloudflare",
  ]
}

# generate_hcl "_pxe_server.tf" {
#   condition = global.feature_toggles.enable_pxe_server == true
#   content {
#     locals {
#       talos_pxe_images = {
#         "arm64-${global.infrastructure.talos.version}" = {
#           name = "talos-arm64-${global.infrastructure.talos.version}"
#           arch = "arm64"
#           version = global.infrastructure.talos.version
#           description = "Talos Linux"
#         }
#       }
#     }
#     data "external" "talos_pxe_images" {
#       for_each = local.talos_pxe_images
#       program = ["bash", "-c", <<EOT
#         if [ ! -f /tmp/${each.value.arch}-${each.value.version}-${talos_image_factory_schematic.this.id}-initramfs.xz ]; then
#           curl -L -o /tmp/${each.value.arch}-${each.value.version}-${talos_image_factory_schematic.this.id}-initramfs.xz https://factory.talos.dev/image/${talos_image_factory_schematic.this.id}/${each.value.version}/initramfs-${each.value.arch}.xz
#         fi
#         if [ ! -f /tmp/${each.value.arch}-${each.value.version}-${talos_image_factory_schematic.this.id}-kernel ]; then
#           curl -L -o /tmp/${each.value.arch}-${each.value.version}-${talos_image_factory_schematic.this.id}-kernel https://factory.talos.dev/image/${talos_image_factory_schematic.this.id}/${each.value.version}/kernel-${each.value.arch}
#         fi
#         INITRAMFS_MD5_HASH=$(md5sum /tmp/${each.value.arch}-${each.value.version}-${talos_image_factory_schematic.this.id}-initramfs.xz | awk '{print $1}')
#         KERNEL_MD5_HASH=$(md5sum /tmp/${each.value.arch}-${each.value.version}-${talos_image_factory_schematic.this.id}-kernel | awk '{print $1}')
#         echo "{
#           \"initramfs_file_name\": \"${each.value.arch}-${each.value.version}-${talos_image_factory_schematic.this.id}-initramfs.xz\",
#           \"initramfs_file_path\": \"/tmp/${each.value.arch}-${each.value.version}-${talos_image_factory_schematic.this.id}-initramfs.xz\",
#           \"initramfs_file_md5hash\": \"$INITRAMFS_MD5_HASH\"
#           \"kernel_file_name\": \"${each.value.arch}-${each.value.version}-${talos_image_factory_schematic.this.id}-kernel\",
#           \"kernel_file_path\": \"/tmp/${each.value.arch}-${each.value.version}-${talos_image_factory_schematic.this.id}-kernel\",
#           \"kernel_file_md5hash\": \"$KERNEL_MD5_HASH\"
#         }"
#       EOT
#       ]
#     }
#   }
# }

generate_hcl "_locals.tf" {
  content {
    locals {
      nodes = global.infrastructure.talos_instances
      talos_nodes = {for node, info in local.nodes : node => info if info.enable == true}
      oci_talos_nodes = {
        for node, info in local.talos_nodes : node => info if info.provider == "oracle"
      }
    }
  }
}

generate_hcl "_oci.tf" {
  content {
    module "oci_vcn" {
      source         = "${terramate.root.path.fs.absolute}/terraform/modules/infra/oci-vcn"
      compartment_id = global.infrastructure.oci.compartment_id
      name           = tm_replace(global.project.name, "-", "")
      enable_ssh     = true
      enable_ipv4_nat_egress = false
      ssh_ports      = [22, 2203]
    }
  }
}
