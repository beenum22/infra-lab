generate_hcl "_talos_images.tf" {
  condition = global.feature_toggles.enable_rpis == true
  content {
    locals {
      talos_versions = [
        "v1.9.4",
        "v1.10.7",
      ]
      talos_images = {
        for version in local.talos_versions : "talos-rpi-arm64-${version}" => {
          name = "talos-rpi-arm64-${version}"
          arch = "arm64"
          overlay = "rpi_generic"
          version = version
          description = "Raspberry Pi Talos Linux"
        }
      }
    }

    data "talos_image_factory_overlays_versions" "this" {
      for_each = local.talos_images
      talos_version = each.value.version
      filters = {
        names = [
          each.value.overlay
        ]
      }
    }

    resource "talos_image_factory_schematic" "images" {
      for_each = local.talos_images
      schematic = yamlencode({
        overlay = each.value.overlay != null ? {
          image = data.talos_image_factory_overlays_versions.this[each.key].overlays_info[0].image
          name  = "rpi_generic"
        } : {}
        customization = {
          systemExtensions = {
            officialExtensions = data.talos_image_factory_extensions_versions.this.extensions_info.*.name
          }
        }
      })
    }

    data "external" "talos_images" {
      for_each = local.talos_images
      program = ["bash", "-c", <<EOT
        if [ ! -f /tmp/${each.value.name}-${talos_image_factory_schematic.images[each.key].id}.raw ]; then
          curl -L -o /tmp/${each.value.name}-${talos_image_factory_schematic.images[each.key].id}.raw.xz https://factory.talos.dev/image/${talos_image_factory_schematic.images[each.key].id}/${each.value.version}/metal-${each.value.arch}.raw.xz
          xz -d /tmp/${each.value.name}-${talos_image_factory_schematic.images[each.key].id}.raw.xz
        fi
        MD5_HASH=$(md5sum /tmp/${each.value.name}-${talos_image_factory_schematic.images[each.key].id}.raw | awk '{print $1}')
        echo "{
          \"file_name\": \"${each.value.name}-${talos_image_factory_schematic.images[each.key].id}.raw\",
          \"file_path\": \"/tmp/${each.value.name}-${talos_image_factory_schematic.images[each.key].id}.raw\",
          \"file_md5hash\": \"$MD5_HASH\"
        }"
      EOT
      ]
    }

    # Note: Upload the images later to Backblaze or some centralized storage when all of this done using CI.
    output "talos_images" {
      value = [ for key, val in local.talos_images : {
        name = val.name
        path = data.external.talos_images[key].result.file_path
        md5hash = data.external.talos_images[key].result.file_md5hash
      }]
    }
  }
}