globals "terraform" {
  version = ">=1.2.9"
  remote_states = {
    stacks = []
  }
}

globals "terraform" "default_providers" {
  oci = {
    source  = "oracle/oci"
    version = "6.18.0"
    config = {
      config_file_profile = "DEFAULT"
      region = global.infrastructure.oci.region
      tenancy_ocid = global.infrastructure.oci.tenancy_ocid
      user_ocid = global.infrastructure.oci.user_ocid
      fingerprint = global.infrastructure.oci.fingerprint
      private_key = global.infrastructure.oci.private_key
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
   ansible = {
     source = "ansible/ansible"
     version = "1.2.0"
     config = {}
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
  hcloud = {
    source = "hetznercloud/hcloud"
    version = "1.45.0"
    config = {
      token = global.secrets.hetzner.api_token
    }
  }
  cloudflare = {
    source = "cloudflare/cloudflare"
    version = "4.29.0"
    config = {
      api_token = global.secrets.cloudflare.api_token
    }
  }
}

globals "terraform" "backend" "s3" {
  region = "eu-central-003"
  bucket = "dera-lab-terraform-states"
  url    = "https://s3.eu-central-003.backblazeb2.com"
  access_key = global.secrets.b2.key_id
  secret_key = global.secrets.b2.application_key
}
