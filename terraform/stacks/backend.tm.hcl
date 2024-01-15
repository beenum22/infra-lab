generate_hcl "_backend.tf" {
  #  condition = tm_contains(terramate.stack.tags, "terraform")

  content {
    terraform {
      backend "s3" {
        region = global.terraform.backend.s3.region
        bucket = global.terraform.backend.s3.bucket
        key    = "${terramate.stack.name}/terraform.tfstate"
        endpoints = {
          s3 = global.terraform.backend.s3.url
        }
        shared_credentials_files    = ["~/.oci/credentials"]
        skip_region_validation      = true
        skip_credentials_validation = true
        skip_requesting_account_id  = true
        skip_metadata_api_check     = true
        skip_s3_checksum            = true
        use_path_style              = true
      }
    }
  }
}
