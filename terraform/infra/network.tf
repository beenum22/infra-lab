module "vcn" {
  source = "./modules/oci_vcn"
  compartment_id = var.compartment_id
  name = "lab"
  enable_public_access = true
}