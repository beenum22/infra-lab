globals "project" {
  name = "dera-lab"
  zone = "moinmoin.fyi"
  domain = "moinmoin.fyi"
  domain_email = "muneeb.gandapur@gmail.com"
  ingress_class = "nginx"
  ingress_hostname = "wormhole.moinmoin.fyi"
  storage_class = "openebs-zfs"
  cert_manager_issuer = "cert-manager-cloudflare"
}

globals "feature_toggles" {
  enable_talos = true
}

globals "infrastructure" "dns" {
  zone = "moinmoin.fyi"
}

globals "infrastructure" "ovh" {
  endpoint           = "ovh-eu"
  application_key    = global.secrets.ovh.application_key
  application_secret = global.secrets.ovh.application_secret
  consumer_key       = global.secrets.ovh.consumer_key
}

globals "infrastructure" "tailscale" {
  tailnet  = "tail03622.ts.net"
  org = "muneeb.gandapur@gmail.com"
  version = "1.76.1"
  cidrs = [
    "100.64.0.0/10",
    "fd7a:115c:a1e0::/48",
  ]
  acl = {
    admins = [
      "muneeb.gandapur@gmail.com",
    ]
    k3s_web_apps_consumers = [
#      "muneeb.gandapur@gmail.com",
      "msagheer92@gmail.com",
      "mahrukhanwari1@gmail.com"
    ]
    k3s_api_consumers = [
#      "muneeb.gandapur@gmail.com",
      "msagheer92@gmail.com"
    ]
    exit_node_consumers = [
#      "msagheer92@gmail.com"
      "mahrukhanwari1@gmail.com"
    ]
  }
}

globals "infrastructure" "oci" {
  tenancy_ocid     = "ocid1.tenancy.oc1..aaaaaaaa6pope5hp7f7kxyhpiljh53ww4v2ehsiq4xzjz3u6rpxoqj2bdoua"
  user_ocid        = "ocid1.user.oc1..aaaaaaaa7o5auyixstrtsrcgvoo5gyp2yj5iwwirowqpeaa2cbbtedzpgala"
  private_key      = global.secrets.oci.private_key
  fingerprint      = "8b:16:de:80:45:8d:22:69:be:32:dc:c3:81:e5:b9:bf"
  region           = "eu-frankfurt-1"
  compartment_id   = "ocid1.tenancy.oc1..aaaaaaaa6pope5hp7f7kxyhpiljh53ww4v2ehsiq4xzjz3u6rpxoqj2bdoua"
}

globals "infrastructure" "k3s" {
  version = "v1.31.1+k3s1"
#   api_host = tm_join(".", ["oci-fra-1", global.infrastructure.tailscale.tailnet])
  api_host = {
    # domain = "k8s-api.moinmoin.fyi"
    # TODO: Implemetation is incorrect currently as it's supposed to add domain in Cloudflare
    domain = "oci-fra-1"
    target = "oci-fra-1"
  }
  cluster_cidrs = [
    "10.42.0.0/16",
    "2001:cafe:42:0::/56"
  ]
  service_cidrs = [
    "10.43.0.0/16",
    "2001:cafe:42:1::/112"
  ]
}

globals "infrastructure" "talos" {
  version = "v1.9.4"
  k8s_version = "1.32.2"
  cluster_name = "dera-lab"
  cluster_endpoint = "endpoint.cluster.${global.infrastructure.dns.zone}"
  cluster_cidrs = [
    # "10.42.0.0/16",
    # "2001:cafe:42:0::/56"
    "10.244.0.0/16",
    "2001:db8:42:0::/56",
  ]
  service_cidrs = [
    # "10.43.0.0/16",
    # "2001:cafe:42:1::/112"
    "10.96.0.0/12",
    "2001:db8:42:1::/112",
  ]
  bootstrap_node = "oci-fra-0"
}

globals "infrastructure" "talos_instances" {
  oci-fra-0 = {
    enable = true
    managed  = false
    provider = "oracle"
    hostname = "oci-fra-0.cluster.${global.infrastructure.dns.zone}"
    provider_config = {
      shape_name    = "VM.Standard.A1.Flex"
      image_ocid    = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaujyukkfkoanatqanh2qe4bxhwwg2j44fjn2folihrfvsxd5jv5bq"
      vcpus         = 1
      memory        = 6
      boot_volume   = 50
      block_volumes = []
    }
    tailscale_config = {
      version   = global.infrastructure.tailscale.version
      exit_node = false
      mtu       = "1280"
      routes    = ""
    }
    zfs_config = {
      enable = false
      loopback = {
        loop0 = {
          path = "/mnt/zfs-loop0.img"
          size = "20G"
        }
      }
      devices = {}
    }
    talos_config = {
      version = global.infrastructure.talos.version
      k8s_version = global.infrastructure.talos.k8s_version
      bootstrap = true
      machine_type = "controlplane"
      node_labels = {
        "moinmoin.fyi/country" = "germany"
        "moinmoin.fyi/provider" = "oci"
        "moinmoin.fyi/type" = "vm"
        "moinmoin.fyi/owner" = "munna"
        "openebs.io/localpv-zfs" = false
        "openebs.io/nodeid" = "oci-fra-0"
      }
    }
  }
  oci-fra-1 = {
    enable   = true
    managed  = false
    provider = "oracle"
    hostname = "oci-fra-1.cluster.${global.infrastructure.dns.zone}"
    provider_config = {
      shape_name    = "VM.Standard.A1.Flex"
      image_ocid    = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaujyukkfkoanatqanh2qe4bxhwwg2j44fjn2folihrfvsxd5jv5bq"
      vcpus         = 1
      memory        = 6
      boot_volume   = 50
      block_volumes = []
    }
    tailscale_config = {
      version   = global.infrastructure.tailscale.version
      exit_node = true
      mtu       = "1280"
    }
    zfs_config = {
      enable = false
      loopback = {
        loop0 = {
          path = "/mnt/zfs-loop0.img"
          size = "20G"
        }
      }
      devices = {}
    }
    talos_config = {
      version = global.infrastructure.talos.version
      k8s_version = global.infrastructure.talos.k8s_version
      bootstrap = false
      machine_type = "controlplane"
      node_labels = {
        "moinmoin.fyi/country" = "germany"
        "moinmoin.fyi/provider" = "oci"
        "moinmoin.fyi/owner" = "munna"
        "moinmoin.fyi/type" = "vm"
        "openebs.io/localpv-zfs" = false
        "openebs.io/nodeid" = "oci-fra-1"
      }
    }
  }
  oci-fra-2 = {
    enable = true
    managed  = false
    provider = "oracle"
    hostname = "oci-fra-2.cluster.${global.infrastructure.dns.zone}"
    provider_config = {
      shape_name    = "VM.Standard.A1.Flex"
      # image_ocid    = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaujyukkfkoanatqanh2qe4bxhwwg2j44fjn2folihrfvsxd5jv5bq"
      vcpus         = 2
      memory        = 12
      boot_volume   = 50
      block_volumes = [50]
    }
    tailscale_config = {
      version   = global.infrastructure.tailscale.version
      exit_node = true
      mtu       = "1280"
      routes    = ""
    }
    zfs_config = {
      enable = false
      loopback = {
        loop0 = {
          path = "/mnt/zfs-loop0.img"
          size = "20G"
        }
      }
      devices = {}
    }
    talos_config = {
      version = global.infrastructure.talos.version
      k8s_version = global.infrastructure.talos.k8s_version
      bootstrap = false
      machine_type = "controlplane"
      # copy_kubeconfig = true
      node_labels = {
        "moinmoin.fyi/country" = "germany"
        "moinmoin.fyi/provider" = "oci"
        "moinmoin.fyi/type" = "vm"
        "moinmoin.fyi/owner" = "munna"
        "openebs.io/localpv-zfs" = true
        "openebs.io/nodeid" = "oci-fra-0"
      }
    }
  }
}

globals "infrastructure" "config" {
  use_ipv6          = false
  use_tailscale_ipv6  = false
  ssh_key_file_name = "${tm_replace(global.project.name, "-", "_")}_id_rsa"
  ssh_keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDXAxRvB9RCU94lxpipzMbYpXlICbLwU4HqEIgU9AvDwIsJ/6uJUGojcg67+fc1isCPlJjLVTD4hicH7hR533uOJbcHwrEQUMpwVN6IkZrRTsUUBwo9xYDxtVGaXFCLCihMWtrgC0esaY8Uy3rF/NEUq/HHFVYSJc7gEjarxkSlOEFiPae7d0HXrSSV1ysAfI9RPa7xok7CB0u1rpe3cOLzHvJlQosmZ/grWKh+Q7s3UXjIbKjU+5I5pI6enjuyxYxegFT77vDIUxRlAR/OTr0jLNAa/X2Fcr2+MoGIi4QvaJMEKtrMOrGnQW2t8DE8Tk8E+p4xvEkjiJe5jDN7bPt51gS60Jv4PEJmwbpJRN1bj0dGW2bPuGJP48lr+xqC6EBryhuGh7YyTPyqP/uEw8JOEbH0WpT8//r1J4oCJ2yRKPJBr5IG7K49fCuP/Aq9oy7sAK4TEULlX/gyuxYaO2XplIncjkw5J29y3Ph5jN3yjyFG0qcftoMw3d/yEKUZzGk= muneebhome@Muneebs-MacBook-Pro.local",
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDQwc7RV/mSCCdZ/YpMujRBtUbNEe0rfng7i2kUkNWmCR9SRy1vZECLLmEMUr5i5ME/8sOrBm5JfsPTJIKaVHzZLjdr3CVCDpGAJBJp6JYLA2bAwy0xQyK+tyVUgnxtkmTJR6TQIQKW9DQy67GBe8wMCkm3tYHtJ4dQy/C9NnonEcsb5ngEMjhbHZD0tDwa+eKtdXhrCJq2KMbz4l9PAIH0EoouK/fWijECcqYxJeHw4nBhdfrnKgn3R1VK5GQFIJ6kkri6P7ibUcX4/fwKaYnmOM2H4YAv47/nHD+FGc8A5yMwT8/FM09QjDj8BtFXJj+SMK5/JqgovYHuiA+GcL2Vv11c0wBp4CjO2YUHjhUVCqDNSUcXf37+XFwtPfqGNOSOEmrYmGXjCnETGGNILMfwVr4aM3PsFh3LpJEI4V4l4IbQT4KfvwgTrdFQX4HGgITJoYUVizaHIZhaNt2QRqUp4/zF0O3B7Do3mIeQzTgNv4VxkXebuSYhEvM6X035Ecs= muneebhome@Muneebs-MacBook-Pro.local",
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC9iQnzPq0/lLg359hzQiVSnf33PAzCYaFu8gW1OIaftA2+/fUtJoPCoMBNB4TDTA5ZnHfKEmR9/ktFr4AWOQ/4oCQP2uC12zci9Lpep/aYMmXmgAGs+35sZvf1Ob44CuEw/vvwfViYNt8HAc0BTo1+Sj5gKp8QuBVY70ezS0yw+VEvHnxbXDbXxVRId1w7gANwBAhyRviKjFWSULPJsPY+t0HNoFozERnBDaov3wL7TPIy2WIHr6BE/lOwlzoqRMd8qtAIEbrDTNfZwmY+2AYvhjicLQ6H5jCfHW6UFptlV4UN9UijdVZ+thF4vM8i6huHUx87ljsyOtqwLqrwfh9t muneebahmad@beenum.local"
  ]
  ansible_settings = {
    debug  = false
    replay = false
  }
  packages = [
    "jq",
    "net-tools",
    "firewalld",
    "curl",
    "iptables",
  ]
  users = {
    k3s = {
      sudo     = true
      password = null
    }
  }
}

globals "infrastructure" "cloudflare" {
  zone_id = "caee740b96fd9709c0fcc1934bd59da9"
  account_id = "03614fa9b630f5b0984e241fe4aa1fc9"
}

globals "cluster" {
  users = {
    munna = {
      namespace = "munna"
      storage_class = [
        "openebs-zfs",
        "openebs-hostpath",
        "openebs-kernel-nfs"
      ]
    }
    jakku = {
      namespace = "jakku"
      storage_class = [
        "openebs-zfs",
        "openebs-hostpath",
#        "openebs-kernel-nfs"
      ]
    }
  }
}

globals "cluster" "apps" {
  filebrowser = {
    enable = false
    backup = true
    hostnames = ["filebrowser.cluster.moinmoin.fyi"]
    public = false
  }
  homebox = {
    enable = false
    backup = true
    hostnames = ["homebox.moinmoin.fyi"]
    public = false
  }
  dashy = {
    enable = true
    backup = false
    hostnames = ["dashy.cluster.moinmoin.fyi"]
    public = false
  }
  jellyfin = {
    enable = false
    backup = false
    hostnames = ["jellyfin.moinmoin.fyi"]
    public = false
  }
  # WARNING: Cloudflare tunneling doesn't work for multilevel domains and also faced intermittent 301 redirect issues. Disabling public access.
  # TODO: Check if this issue can be fixed.
  http_echo = {
    enable = true
    backup = false
    hostnames = ["echo.cluster.moinmoin.fyi"]
    public = false
  }
  dashdot = {
    enable = true
    backup = false
    hostnames = [
      "dashdot.cluster.moinmoin.fyi"
    ]
    public = false
  }
}

globals "apps" {
  # backups = [
  #   "filebrowser",
  #   "homebox",
  #   "nfs-share"
  # ]

  public_hostnames = [
    "echo.moinmoin.fyi"
  ]
  private_hostnames = [
    "filebrowser.moinmoin.fyi",
    "dashy.moinmoin.fyi",
    "homebox.moinmoin.fyi",
    "jellyfin.moinmoin.fyi",
    "oci-fra-0.dashdot.moinmoin.fyi",
    "oci-fra-1.dashdot.moinmoin.fyi",
    "oci-fra-2.dashdot.moinmoin.fyi",
    "hzn-hel-0.dashdot.moinmoin.fyi",
    "netcup-neu-0.dashdot.moinmoin.fyi",
    "rpi-dik-0.dashdot.moinmoin.fyi",
  ]
}