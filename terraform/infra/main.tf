terraform {
  backend "s3" {
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
    oci = {
      source = "oracle/oci"
      version = "4.111.0"
    }
    template = {
      source = "hashicorp/template"
      version = "2.2.0"
    }
    tls = {
      source = "hashicorp/tls"
      version = "4.0.4"
    }
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

provider "tls" {}

provider "tailscale" {
  api_key = var.tailscale_apikey
  tailnet = var.tailscale_org
}

provider "oci" {
  tenancy_ocid = "ocid1.tenancy.oc1..aaaaaaaa6pope5hp7f7kxyhpiljh53ww4v2ehsiq4xzjz3u6rpxoqj2bdoua"
  user_ocid = "ocid1.user.oc1..aaaaaaaa7o5auyixstrtsrcgvoo5gyp2yj5iwwirowqpeaa2cbbtedzpgala"
  private_key_path = "~/.oci/oci_api_key.pem"
  fingerprint = "0c:4c:7a:f7:c6:d7:8c:e6:65:46:df:90:d1:e0:d2:b7"
  region = "eu-frankfurt-1"
}

locals {
  instances = {
    "lab-k3s-0" = {
      managed = false
      provider = "oracle"
      user = "opc"
      host = null
      hostname = null
      provider_config = {
        shape_name = "VM.Standard.A1.Flex"
        image_ocid = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaujyukkfkoanatqanh2qe4bxhwwg2j44fjn2folihrfvsxd5jv5bq"
        vcpus = 1
        memory = 6
        boot_volume = 50
        block_volumes = []
      }
      tailscale_config = {
        version = "1.54.0"
        auth_key = var.tailscale_auth_key
        exit_node = false
        mtu = 1350
        routes = "10.42.2.0/24,2001:cafe:42:3::/64"
      }
    }
    "oci-fra-k3s-1" = {
      managed = false
      provider = "oracle"
      user = "opc"
      host = null
      hostname = null
      provider_config = {
        shape_name = "VM.Standard.A1.Flex"
        image_ocid = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaujyukkfkoanatqanh2qe4bxhwwg2j44fjn2folihrfvsxd5jv5bq"
        vcpus = 1
        memory = 6
        boot_volume = 50
        block_volumes = []
      }
      tailscale_config = {
        version = "1.54.0"
        auth_key = var.tailscale_auth_key
        exit_node = true
        mtu = "1350"
      }
    }
    "oci-fra-k3s-2" = {
      managed = false
      provider = "oracle"
      user = "opc"
      host = {
        ipv4 = null
        ipv6 = null
      }
      hostname = null
      provider_config = {
        shape_name = "VM.Standard.A1.Flex"
        image_ocid = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaujyukkfkoanatqanh2qe4bxhwwg2j44fjn2folihrfvsxd5jv5bq"
        vcpus = 2
        memory = 12
        boot_volume = 50
        block_volumes = [
          50
        ]
      }
      tailscale_config = {
        version = "1.54.0"
        auth_key = var.tailscale_auth_key
        exit_node = true
        mtu = "1350"
      }
    }
    "byte-fra-k3s-0" = {
      managed = true
      provider = "bytehosting"
      user = "k3s"
      host = {
        ipv4 = "45.134.39.35"
        ipv6 = "2a0e:97c0:3ea:29::1"
      }
      hostname = "byte-fra-k3s-0"
      provider_config = {}
      tailscale_config = {
        version = "1.54.0"
        auth_key = var.tailscale_auth_key
        exit_node = false
        mtu = "1280"
      }
    }
    "hzn-neu-k3s-0" = {
      managed = true
      provider = "hetzner"
      user = "k3s"
      host = {
        ipv4 = "78.46.252.116"
        ipv6 = "2a01:4f8:c0c:4015::1"
      }
      hostname = "hzn-neu-k3s-0"
      provider_config = {}
      tailscale_config = {
        version = "1.54.0"
        auth_key = var.tailscale_auth_key
        exit_node = false
        mtu = "1280"
      }
    }
  }
}
