generate_hcl "_talos_images.tf" {
  condition = global.feature_toggles.enable_rpis == true
  content {
    locals {
      talos_versions = [
        "v1.9.4",
        "v1.10.7",
      ]
      talos_images = {
        # "talos-rpi-arm64-v1.9.4" = {
        #   name = "talos-rpi-arm64-v1.9.4"
        #   arch = "arm64"
        #   overlay = "rpi_generic"
        #   version = "v1.9.4"
        #   description = "Raspberry Pi Talos Linux"
        #   provider_config = {}
        # }
        # "talos-rpi-arm64-v1.10.7" = {
        #   name = "talos-rpi-arm64-v1.10.7"
        #   arch = "arm64"
        #   overlay = "rpi_generic"
        #   version = "v1.10.7"
        #   description = "Raspberry Pi Talos Linux"
        #   provider_config = {}
        # }
        "talos-oci-arm64-v1.9.4" = {
          name = "talos-oci-arm64-v1.9.4"
          arch = "arm64"
          version = "v1.9.4"
          overlay = null
          description = "OCI Talos Linux"
          provider_config = {
            shapes = [
              "VM.Standard.A1.Flex"
            ]
          }
        }
        "talos-oci-arm64-v1.10.7" = {
          name = "talos-oci-arm64-v1.10.7"
          arch = "arm64"
          version = "v1.10.7"
          overlay = null
          description = "OCI Talos Linux"
          provider_config = {
            shapes = [
              "VM.Standard.A1.Flex"
            ]
          }
        }
      }
      talos_local_images = {
        for key, val in local.talos_images : key => {
          name = val.name
          path = val.overlay == null ? data.external.oci_talos_images[key].result.file_path : data.external.talos_images[key].result.file_path
          md5hash = val.overlay == null ? data.external.oci_talos_images[key].result.file_md5hash : data.external.talos_images[key].result.file_md5hash
        }
      }
    }

    data "talos_image_factory_overlays_versions" "this" {
      for_each = { for k, v in local.talos_images : k => v if v.overlay != null }
      talos_version = each.value.version
      filters = {
        names = [
          each.value.overlay
        ]
      }
    }
    
    data "talos_image_factory_extensions_versions" "this" {
      for_each = local.talos_images
      talos_version = each.value.version
      filters = {
        names = [
          "tailscale",
          "zfs",
          "nfsd",
        ]
      }
    }

    resource "talos_image_factory_schematic" "this" {
      for_each = local.talos_images
      schematic = yamlencode({
        overlay = each.value.overlay != null ? {
          image = data.talos_image_factory_overlays_versions.this[each.key].overlays_info[0].image
          name  = "rpi_generic"
        } : {}
        customization = {
          systemExtensions = {
            officialExtensions = data.talos_image_factory_extensions_versions.this[each.key].extensions_info.*.name
          }
        }
      })
    }

    data "external" "talos_images" {
      for_each = { for k, v in local.talos_images : k => v if v.overlay != null }
      program = ["bash", "-c", <<EOT
        if [ ! -f /tmp/${each.value.name}-${talos_image_factory_schematic.this[each.key].id}.raw ]; then
          curl -L -o /tmp/${each.value.name}-${talos_image_factory_schematic.this[each.key].id}.raw.xz https://factory.talos.dev/image/${talos_image_factory_schematic.this[each.key].id}/${each.value.version}/metal-${each.value.arch}.raw.xz
          xz -d /tmp/${each.value.name}-${talos_image_factory_schematic.this[each.key].id}.raw.xz
        fi
        MD5_HASH=$(md5sum /tmp/${each.value.name}-${talos_image_factory_schematic.this[each.key].id}.raw | awk '{print $1}')
        echo "{
          \"file_name\": \"${each.value.name}-${talos_image_factory_schematic.this[each.key].id}.raw\",
          \"file_path\": \"/tmp/${each.value.name}-${talos_image_factory_schematic.this[each.key].id}.raw\",
          \"file_md5hash\": \"$MD5_HASH\"
        }"
      EOT
      ]
    }

    # resource "b2_bucket" "talos_images" {
    #   bucket_name = "talos-images"
    #   bucket_type = "allPrivate"
    # }

    # resource "b2_bucket_file_version" "talos_images" {
    #   for_each = local.talos_local_images
    #   bucket_id = b2_bucket.talos_images.id
    #   file_name = each.value.name
    #   source    = each.value.path
    # }

    # Note: Upload the images later to Backblaze or some centralized storage when all of this done using CI.
    output "talos_images" {
      value = local.talos_local_images
    }
  }
}