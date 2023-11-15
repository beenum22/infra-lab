terraform {
  backend "s3" {
    bucket = "homelab-terraform-state"
    key = "cluster-terraform.tfstate"
    region = "eu-frankfurt-1"
    endpoint = "https://fr4chwnl3vil.compat.objectstorage.eu-frankfurt-1.oraclecloud.com"
    shared_credentials_file = "~/.oci/credentials"
    skip_region_validation = true
    skip_credentials_validation = true
    skip_metadata_api_check = true
    force_path_style = true
  }
}

data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
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
//    docker = {
//      source = "kreuzwerker/docker"
//      version = "3.0.2"
//    }
    tailscale = {
      source = "tailscale/tailscale"
      version = "0.13.6"
    }
//    external = {
//      source = "hashicorp/external"
//      version = "2.3.1"
//    }
  }
}

locals {
  machine_0_ip = var.use_ipv6 ? data.terraform_remote_state.infra.outputs.instances["lab-k3s-0"]["primary_ipv6_address"] : data.terraform_remote_state.infra.outputs.instances["lab-k3s-0"]["primary_public_ipv4_address"]
  machine_1_ip = var.use_ipv6 ? data.terraform_remote_state.infra.outputs.instances["lab-k3s-1"]["primary_ipv6_address"] : data.terraform_remote_state.infra.outputs.instances["lab-k3s-1"]["primary_public_ipv4_address"]
  machine_2_ip = var.use_ipv6 ? data.terraform_remote_state.infra.outputs.instances["lab-k3s-2"]["primary_ipv6_address"] : data.terraform_remote_state.infra.outputs.instances["lab-k3s-2"]["primary_public_ipv4_address"]
}

provider "tailscale" {
  api_key = var.tailscale_apikey
  tailnet = var.tailscale_org
}

locals {
  instances = {
    "lab-k3s-0" = {
      user = data.terraform_remote_state.infra.outputs.instances["lab-k3s-0"]["instance_user"]
      host = local.machine_0_ip
      hostname = data.terraform_remote_state.infra.outputs.instances["lab-k3s-0"]["instance_name"]
      k3s_version = "v1.27.3-rc1+k3s1"
      k3s_init = true
      k3s_role = "server"
      k3s_copy_kubeconfig = true
      k3s_node_labels = {
        "dera.ovh/country" = "germany"
      }
    }
    "lab-k3s-1" = {
      user = data.terraform_remote_state.infra.outputs.instances["lab-k3s-1"]["instance_user"]
      host = local.machine_1_ip
      hostname = data.terraform_remote_state.infra.outputs.instances["lab-k3s-1"]["instance_name"]
      k3s_version = "v1.27.3-rc1+k3s1"
      k3s_init = false
      k3s_role = "server"
      k3s_copy_kubeconfig = false
      k3s_node_labels = {
        "dera.ovh/country" = "germany"
      }
    }
    "lab-k3s-2" = {
      user = data.terraform_remote_state.infra.outputs.instances["lab-k3s-2"]["instance_user"]
      host = local.machine_2_ip
      hostname = data.terraform_remote_state.infra.outputs.instances["lab-k3s-2"]["instance_name"]
      k3s_version = "v1.27.3-rc1+k3s1"
      k3s_init = false
      k3s_role = "server"
      k3s_copy_kubeconfig = false
      k3s_node_labels = {
        "dera.ovh/country" = "germany"
      }
    }
  }
}
