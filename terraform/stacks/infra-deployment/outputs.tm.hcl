generate_hcl "_outputs.tf" {
  content {
    output "oci_vcn_id" {
      value = module.oci_vcn.vcn.vcn_id
    }

    output "oci_public_subnet_id" {
      value = module.oci_vcn.public_subnet_id
    }

    output "oci_talos_image_ids" {
      value = {for k,v in oci_core_image.this : k => v.id}
    }
  }
}
