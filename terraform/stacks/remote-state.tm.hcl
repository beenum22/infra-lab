generate_hcl "_remote_state.tf" {
  content {
    tm_dynamic "data" {
      for_each = global.terraform.remote_states.stacks
      iterator = item
      labels   = ["terraform_remote_state", "${tm_replace(item.value, "-", "_")}_stack_state"]
      content {
        backend = "s3"
        config = {
          bucket = global.terraform.backend.s3.bucket
          key    = tm_try("${item.value}/terraform.tfstate")
          region = global.terraform.backend.s3.region
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
}
