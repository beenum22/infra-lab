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
        for version in local.talos_versions : "arm64-${version}" => {
          name = "Talos-arm64-${version}"
          arch = "arm64"
          version = version
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
          "zfs",
          "nfsd",
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