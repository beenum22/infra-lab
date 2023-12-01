module "oracle_vcn" {
  source = "./modules/oci_vcn"
  compartment_id = var.compartment_id
  name = "lab"
  enable_ssh = true
}
