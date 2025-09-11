globals "terraform" {
  version = ">=1.2.9"
  remote_states = {
    stacks = []
  }
}

globals "terraform" "default_providers" {
  oci = {
    source  = "oracle/oci"
    # version = "4.111.0"
    version = ">= 4.67.3, < 7.0.0"
    config = {
      config_file_profile = "DEFAULT"
      region = global.infrastructure.oci.region
      tenancy_ocid = global.infrastructure.oci.tenancy_ocid
      user_ocid = global.infrastructure.oci.user_ocid
      fingerprint = global.infrastructure.oci.fingerprint
      private_key = global.infrastructure.oci.private_key
    }
  }
  null = {
    source  = "hashicorp/null"
    version = "3.2.3"
    config  = {}
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
    version = "0.18.0"
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
     version = "1.3.0"
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
      application_key    = global.infrastructure.ovh.application_key
      application_secret = global.infrastructure.ovh.application_secret
      consumer_key       = global.infrastructure.ovh.consumer_key
    }
  }
  helm = {
    source = "hashicorp/helm"
    version = "3.0.2"
    config = {
      config_path = "~/.kube/config"
    }
  }
  kubernetes = {
    source = "hashicorp/kubernetes"
    version = "~> 2.36"
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
    # version = "5.1.0"
    version = ">= 4.29.0, <= 5.2.0"
    config = {
      api_token = global.secrets.cloudflare.api_token
    }
  }
  random = {
    source = "hashicorp/random"
    version = "3.7.1"
    config = {}
  }
  # Experimental: Testing Talos as K3s alternative
  external = {
    source = "hashicorp/external"
    version = "2.3.4"
    config = {}
  }
  # Experimental: Testing Talos as K3s alternative
  talos = {
    source = "siderolabs/talos"
    version = "0.9.0-alpha.0"
    config = {}
  }
  # Experimental: Testing as Tailscale alternative for cluster network
  zerotier = {
    source = "zerotier/zerotier"
    version = "1.6.0"
    config = {
      zerotier_central_token = global.secrets.zerotier.api_token
    }
  }
  # Experimental: Testing ArgoCD
  argocd = {
    source = "argoproj-labs/argocd"
    version = "7.6.1"
    config = {
      username = global.secrets.argocd.username
      password = global.secrets.argocd.password
      server_addr = global.cluster.cicd.argocd.domain
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
