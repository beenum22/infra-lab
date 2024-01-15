globals "terraform" {
  version = ">=1.2.9"
  remote_states = {
    stacks = []
  }
}

globals "terraform" "default_providers" {
  oci = {
    source  = "oracle/oci"
    version = "4.111.0"
    config = {
      tenancy_ocid     = global.infrastructure.oci.tenancy_ocid
      user_ocid        = global.infrastructure.oci.user_ocid
      private_key_path = global.infrastructure.oci.private_key_path
      fingerprint      = global.infrastructure.oci.fingerprint
      region           = global.infrastructure.oci.region
    }
  }
  template = {
    source  = "hashicorp/template"
    version = "2.2.0"
    config  = {}
  }
  tls = {
    source  = "hashicorp/tls"
    version = "4.0.4"
    config  = {}
  }
  tailscale = {
    source  = "tailscale/tailscale"
    version = "0.13.13"
    config = {
      api_key = global.secrets.tailscale.apikey
      tailnet = global.infrastructure.tailscale.org
    }
  }
  ssh = {
    source  = "loafoe/ssh"
    version = "2.6.0"
    config  = {}
  }
#    ansible = {
#      source = "ansible/ansible"
#      version = "1.1.0"
#    }
  ansible = {
    source  = "NefixEstrada/ansible"
    version = "2.0.4"
    config  = {}
  }
  local = {
    source  = "hashicorp/local"
    version = "2.4.0"
    config  = {}
  }
  ovh = {
    source = "ovh/ovh"
    version = "0.35.0"
    config = {
      endpoint           = global.infrastructure.ovh.endpoint
      application_key    = global.secrets.ovh.application_key
      application_secret = global.secrets.ovh.application_secret
      consumer_key       = global.secrets.ovh.consumer_key
    }
  }
  helm = {
    source = "hashicorp/helm"
    version = "2.9.0"
    config = {
      config_path = "~/.kube/config"
    }
  }
  kubernetes = {
    source = "hashicorp/kubernetes"
    version = "2.20.0"
    config = {
      config_path = "~/.kube/config"
    }
  }
  b2 = {
    source = "Backblaze/b2"
    version = "0.8.4"
    config = {
      application_key = global.secrets.b2.application_key
      application_key_id = global.secrets.b2.key_id
    }
  }
}

globals "terraform" "backend" "s3" {
  region = "eu-frankfurt-1"
  bucket = "homelab-terraform-state"
  url    = "https://fr4chwnl3vil.compat.objectstorage.eu-frankfurt-1.oraclecloud.com"
}
