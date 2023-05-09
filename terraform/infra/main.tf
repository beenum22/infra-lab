terraform {
  backend "s3" {
    bucket = "homelab-terraform-state"
    key = "infra-terraform.tfstate"
    region = "eu-frankfurt-1"
    endpoint = "https://fr4chwnl3vil.compat.objectstorage.eu-frankfurt-1.oraclecloud.com"
    shared_credentials_file = "~/.oci/credentials"
    skip_region_validation = true
    skip_credentials_validation = true
    skip_metadata_api_check = true
    force_path_style = true
  }
}

terraform {
  required_version = ">=1.2.9"
  required_providers {
    oci = {
      source = "oracle/oci"
      version = "4.111.0"
    }
    template = {
      source = "hashicorp/template"
      version = "2.2.0"
    }
  }
}

provider "oci" {
  tenancy_ocid = "ocid1.tenancy.oc1..aaaaaaaa6pope5hp7f7kxyhpiljh53ww4v2ehsiq4xzjz3u6rpxoqj2bdoua"
  user_ocid = "ocid1.user.oc1..aaaaaaaa7o5auyixstrtsrcgvoo5gyp2yj5iwwirowqpeaa2cbbtedzpgala"
  private_key_path = "~/.oci/oci_api_key.pem"
  fingerprint = "0e:02:8e:7e:15:92:04:7c:89:df:a6:46:3e:36:e5:d5"
  region = "eu-frankfurt-1"
}
