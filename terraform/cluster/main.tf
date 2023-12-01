terraform {
  backend "s3" {
    bucket = "homelab-terraform-state"
    key = "cluster-terraform.tfstate"
    region = "eu-frankfurt-1"
    endpoints = {
      s3 = "https://fr4chwnl3vil.compat.objectstorage.eu-frankfurt-1.oraclecloud.com"
    }
    shared_credentials_files = [ "~/.oci/credentials" ]
    skip_region_validation = true
    skip_credentials_validation = true
    skip_requesting_account_id = true
    skip_metadata_api_check = true
    skip_s3_checksum = true
    use_path_style = true
  }
}

data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = "homelab-terraform-state"
    key = "infra-terraform.tfstate"
    region = "eu-frankfurt-1"
    endpoints = {
      s3 = "https://fr4chwnl3vil.compat.objectstorage.eu-frankfurt-1.oraclecloud.com"
    }
    shared_credentials_files = [ "~/.oci/credentials" ]
    skip_region_validation = true
    skip_credentials_validation = true
    skip_requesting_account_id = true
    skip_metadata_api_check = true
    skip_s3_checksum = true
    use_path_style = true
  }
}

terraform {
  required_version = ">=1.2.9"
  required_providers {
//    docker = {
//      source = "kreuzwerker/docker"
//      version = "3.0.2"
//    }
    tailscale = {
      source = "tailscale/tailscale"
      version = "0.13.6"
    }
    ssh = {
      source = "loafoe/ssh"
      version = "2.6.0"
    }
  }
}

provider "tailscale" {
  api_key = var.tailscale_apikey
  tailnet = var.tailscale_org
}

provider "ssh" {}

locals {
  instances = {
    "lab-k3s-0" = {
      user = data.terraform_remote_state.infra.outputs.nodes["lab-k3s-0"]["user"]
      host = var.use_tailscale_ip ? data.terraform_remote_state.infra.outputs.nodes["lab-k3s-0"]["tailscale_ips"][var.ip_type] : data.terraform_remote_state.infra.outputs.nodes["lab-k3s-0"]["ips"][var.ip_type]
      hostname = data.terraform_remote_state.infra.outputs.nodes["lab-k3s-0"]["hostname"]
      k3s_version = "v1.28.3+k3s2"
      k3s_init = true
      k3s_role = "server"
      k3s_copy_kubeconfig = true
      k3s_node_labels = {
        "dera.ovh/country" = "germany"
        "dera.ovh/provider" = "oracle"
      }
    }
    "lab-k3s-1" = {
      user = data.terraform_remote_state.infra.outputs.nodes["lab-k3s-1"]["user"]
#      host = var.use_tailscale_ip ? data.terraform_remote_state.infra.outputs.nodes["lab-k3s-1"]["tailscale_ips"][var.ip_type] : data.terraform_remote_state.infra.outputs.nodes["lab-k3s-1"]["ips"][var.ip_type]
      host = var.use_tailscale_ip ? data.terraform_remote_state.infra.outputs.nodes["lab-k3s-1"]["tailscale_ips"][var.ip_type] : data.terraform_remote_state.infra.outputs.nodes["lab-k3s-1"]["ips"][var.ip_type]
      hostname = data.terraform_remote_state.infra.outputs.nodes["lab-k3s-1"]["hostname"]
      k3s_version = "v1.28.3+k3s2"
      k3s_init = false
      k3s_role = "server"
      k3s_copy_kubeconfig = false
      k3s_node_labels = {
        "dera.ovh/country" = "germany"
        "dera.ovh/provider" = "oracle"
      }
    }
    "lab-k3s-2" = {
      user = data.terraform_remote_state.infra.outputs.nodes["lab-k3s-2"]["user"]
      host = var.use_tailscale_ip ? data.terraform_remote_state.infra.outputs.nodes["lab-k3s-2"]["tailscale_ips"][var.ip_type] : data.terraform_remote_state.infra.outputs.nodes["lab-k3s-2"]["ips"][var.ip_type]
      hostname = data.terraform_remote_state.infra.outputs.nodes["lab-k3s-2"]["hostname"]
      k3s_version = "v1.28.3+k3s2"
      k3s_init = false
      k3s_role = "server"
      k3s_copy_kubeconfig = false
      k3s_node_labels = {
        "dera.ovh/country" = "germany"
        "dera.ovh/provider" = "oracle"
      }
    }
  }
}
