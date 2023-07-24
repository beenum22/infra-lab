terraform {
  backend "s3" {
    bucket = "homelab-terraform-state"
    key = "apps-terraform.tfstate"
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
    helm = {
      source = "hashicorp/helm"
      version = "2.9.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.20.0"
    }
  }
}

provider "kubernetes" {
  config_path = var.kubeconfig
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig
  }
}
