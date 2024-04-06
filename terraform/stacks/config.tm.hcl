globals "project" {
  name = "dera-lab"
  zone = "dera.ovh"
  domain = "dera.ovh"
  domain_email = "muneeb.gandapur@gmail.com"
  ingress_class = "nginx"
  ingress_hostname = "wormhole.dera.ovh"
  storage_class = "openebs-zfs"
  cert_manager_issuer = "cert-manager-cloudflare"
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
  version = "1.62.1"
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
  private_key_path = "~/.oci/oci_api_key.pem"
  fingerprint      = "0c:4c:7a:f7:c6:d7:8c:e6:65:46:df:90:d1:e0:d2:b7"
  region           = "eu-frankfurt-1"
  compartment_id   = "ocid1.tenancy.oc1..aaaaaaaa6pope5hp7f7kxyhpiljh53ww4v2ehsiq4xzjz3u6rpxoqj2bdoua"
}

globals "infrastructure" "instances" {
  oci-fra-0 = {
    managed  = false
    provider = "oracle"
    user     = "opc"
    port     = 2203
    host     = {}
    hostname = null
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
      routes    = "10.42.2.0/24,2001:cafe:42:3::/64"
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
    k3s_config = {
      version = global.infrastructure.k3s.version
      init = false
      root_node = false
      role = "server"
      copy_kubeconfig = true
      node_labels = {
        "dera.ovh/country" = "germany"
        "dera.ovh/provider" = "oci"
        "dera.ovh/type" = "vm"
        "dera.ovh/owner" = "munna"
        "openebs.io/localpv-zfs" = false
        "openebs.io/nodeid" = "oci-fra-0"
      }
    }
  }
  oci-fra-1 = {
    managed  = false
    provider = "oracle"
    user     = "opc"
    port     = 2203
    host     = {}
    hostname = null
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
    k3s_config = {
      version = global.infrastructure.k3s.version
      init = false
      root_node = false
      role = "server"
      copy_kubeconfig = false
      node_labels = {
        "dera.ovh/country" = "germany"
        "dera.ovh/provider" = "oci"
        "dera.ovh/owner" = "munna"
        "dera.ovh/type" = "vm"
        "openebs.io/localpv-zfs" = false
        "openebs.io/nodeid" = "oci-fra-1"
      }
    }
  }
  oci-fra-2 = {
    managed  = false
    provider = "oracle"
    user     = "opc"
    port     = 2203
    host     = {}
    hostname = null
    provider_config = {
      shape_name  = "VM.Standard.A1.Flex"
      image_ocid  = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaujyukkfkoanatqanh2qe4bxhwwg2j44fjn2folihrfvsxd5jv5bq"
      vcpus       = 2
      memory      = 12
      boot_volume = 50
      block_volumes = [
        50
      ]
    }
    tailscale_config = {
      version   = global.infrastructure.tailscale.version
      exit_node = false
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
    k3s_config = {
      version = global.infrastructure.k3s.version
      init = false
      root_node = false
      role = "agent"
      copy_kubeconfig = false
      node_labels = {
        "dera.ovh/country" = "germany"
        "dera.ovh/provider" = "oci"
        "dera.ovh/type" = "vm"
        "dera.ovh/owner" = "munna"
        "openebs.io/localpv-zfs" = false
        "openebs.io/nodeid" = "oci-fra-2"
      }
    }
  }
  hzn-hel-0 = {
    managed  = false
    provider = "hetzner"
    user     = "muneeb"
    port     = 2203
    host = {}
    hostname        = "hzn-hel-0"
    provider_config = {
      image       = "alma-9"
      server_type = "cx11"
      datacenter  = "hel1-dc2"
      block_volumes = ["20"]
    }
    tailscale_config = {
      version   = global.infrastructure.tailscale.version
      exit_node = true
      mtu       = "1280"
    }
    zfs_config = {
      enable = true
      loopback = {
        loop1 = {
          path = "/mnt/zfs-loop1.img"
          size = "5G"
        }
      }
      devices = {
        sdb = {}
      }
    }
    k3s_config = {
      version = global.infrastructure.k3s.version
      init = false
      root_node = false
      role = "agent"
      copy_kubeconfig = false
      node_labels = {
        "dera.ovh/country" = "germany"
        "dera.ovh/provider" = "hetnzer"
        "dera.ovh/type" = "vm"
        "dera.ovh/owner" = "munna"
        "openebs.io/localpv-zfs" = true
        "openebs.io/nodeid" = "hzn-hel-0"
      }
    }
  }
  netcup-neu-0 = {
    managed  = true
    provider = "netcup"
    user     = "muneeb"
    port     = 2203
    host = {
      ipv4 = "46.232.249.165"
      ipv6 = "2a03:4000:2b:74:6466:f3ff:fe64:150"
    }
    hostname        = "netcup-neu-0"
    provider_config = {}
    tailscale_config = {
      version   = global.infrastructure.tailscale.version
      exit_node = true
      mtu       = "1280"
    }
    zfs_config = {
      enable = true
      loopback = {}
      devices = {
        vda4 = {}
      }
    }
    k3s_config = {
      version = global.infrastructure.k3s.version
      init = true
      root_node = false
      role = "server"
      copy_kubeconfig = false
      node_labels = {
        "dera.ovh/country" = "germany"
        "dera.ovh/provider" = "netcup"
        "dera.ovh/type" = "vm"
        "dera.ovh/owner" = "munna"
        "openebs.io/localpv-zfs" = true
        "openebs.io/nodeid" = "netcup-neu-0"
      }
    }
  }
#   ovh-ldn-k3s-0 = {
#     managed  = true
#     provider = "ovh"
#     user     = "ubuntu"
#     port     = 22
#     host = {
#       ipv4 = "57.128.170.166"
#       ipv6 = "2001:41d0:801:2000::b48"
#     }
#     hostname        = "ovh-ldn-k3s-0"
#     provider_config = {}
#     tailscale_config = {
#       version   = global.infrastructure.tailscale.version
#       auth_key  = global.infrastructure.tailscale.auth_key
#       exit_node = true
#       mtu       = "1280"
#     }
#     zfs_config = {
#       enable = true
#       loopback = {
#         loop100 = {
#           path = "/mnt/zfs-loop100.img"
#           size = "5G"
#         }
#       }
#       devices = {}
#     }
#     k3s_config = {
#       version = global.infrastructure.k3s.version
#       init = false
#       root_node = false
#       role = "agent"
#       copy_kubeconfig = false
#       node_labels = {
#         "dera.ovh/country" = "england"
#         "dera.ovh/provider" = "ovh"
#         "dera.ovh/type" = "vm"
#         "dera.ovh/owner" = "jakku"
#         "openebs.io/localpv-zfs" = true
#         "openebs.io/nodeid" = "ovh-ldn-k3s-0"
#       }
#     }
#   }
#   ovh-fra-k3s-1 = {
#     managed  = true
#     provider = "ovh"
#     user     = "ubuntu"
#     port     = 22
#     host = {
#       ipv4 = "54.37.205.201"
#       ipv6 = "2001:41d0:701:1100::19f1"
#     }
#     hostname        = "ovh-fra-k3s-1"
#     provider_config = {}
#     tailscale_config = {
#       version   = global.infrastructure.tailscale.version
#       auth_key  = global.infrastructure.tailscale.auth_key
#       exit_node = true
#       mtu       = "1280"
#     }
#     zfs_config = {
#       enable = true
#       loopback = {
#         loop100 = {
#           path = "/mnt/zfs-loop100.img"
#           size = "5G"
#         }
#       }
#       devices = {}
#     }
#     k3s_config = {
#       version = global.infrastructure.k3s.version
#       init = false
#       root_node = false
#       role = "agent"
#       copy_kubeconfig = false
#       node_labels = {
#         "dera.ovh/country" = "germany"
#         "dera.ovh/provider" = "ovh"
#         "dera.ovh/type" = "vm"
#         "dera.ovh/owner" = "jakku"
#         "openebs.io/localpv-zfs" = true
#         "openebs.io/nodeid" = "ovh-fra-k3s-1"
#       }
#     }
#   }
#   rpi4-ham-k3s-0 = {
#     managed  = false
#     provider = "self-hosted"
#     user     = "pi"
#     port     = 22
#     host = {
#       ipv4 = "192.168.2.211"
#       ipv6 = "2003:e4:171c:ac4f:b686:e01c:b9f6:2458"
#     }
#     hostname        = "rpi4-ham-k3s-0"
#     provider_config = {}
#     tailscale_config = {
#       version   = "1.60.1"
#       auth_key  = global.infrastructure.tailscale.auth_key
#       exit_node = false
#       mtu       = "1280"
#     }
#     zfs_config = {
#       enable = true
#       loopback = {}
#       devices = {
#         sda3 = {}
#       }
#     }
#     k3s_config = {
#       version = global.infrastructure.k3s.version
#       init = false
#       root_node = false
#       role = "agent"
#       copy_kubeconfig = false
#       node_labels = {
#         "dera.ovh/country" = "germany"
#         "dera.ovh/provider" = "self-hosted"
#         "dera.ovh/type" = "sbc"
#         "dera.ovh/owner" = "munna"
#         "openebs.io/localpv-zfs" = false
#         "openebs.io/nodeid" = "rpi4-ham-k3s-0"
#       }
#     }
#   }
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

globals "infrastructure" "k3s" {
  version = "v1.28.5+k3s1"
  api_host = "netcup-neu-0"
  cluster_cidrs = [
    "10.42.0.0/16",
    "2001:cafe:42:0::/56"
  ]
  service_cidrs = [
    "10.43.0.0/16",
    "2001:cafe:42:1::/112"
  ]
}

globals "infrastructure" "cloudflare" {
  zone_id = "17e986ac03eea904a1ced4c28a48240a"
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

globals "apps" {
  backups = [
    "filebrowser",
    "homebox",
    "nfs-share"
  ]
}