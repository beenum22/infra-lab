globals "project" {
  name = "dera-lab"
  zone = "dera.ovh"
  domain = "dera.ovh"
  domain_email = "muneebahmad22@live.com"
  ingress_class = "nginx"
  ingress_hostname = "wormhole.dera.ovh"
  storage_class = "openebs-zfs"
  cert_manager_issuer = "letsencrypt-ovh"
}

globals "infrastructure" "ovh" {
  endpoint           = "ovh-eu"
  application_key    = global.secrets.ovh.application_key
  application_secret = global.secrets.ovh.application_secret
  consumer_key       = global.secrets.ovh.consumer_key
}

globals "infrastructure" "tailscale" {
  auth_key = global.secrets.tailscale.auth_key
  apikey   = global.secrets.tailscale.apikey
  tailnet  = "tail03622.ts.net"
  org = "muneeb.gandapur@gmail.com"
  version = "1.56.1"
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
  oci-fra-k3s-0 = {
    managed  = false
    provider = "oracle"
    user     = "opc"
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
      version   = "1.56.1"
      auth_key  = global.infrastructure.tailscale.auth_key
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
      version = "v1.28.3+k3s2"
      init = true
      root_node = false
      role = "server"
      copy_kubeconfig = true
      node_labels = {
        "dera.ovh/country" = "germany"
        "dera.ovh/provider" = "oci"
        "dera.ovh/type" = "vm"
        "openebs.io/localpv-zfs" = false
        "openebs.io/nodeid" = "oci-fra-k3s-0"
      }
    }
  }
  oci-fra-k3s-1 = {
    managed  = false
    provider = "oracle"
    user     = "opc"
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
      version   = "1.56.1"
      auth_key  = global.infrastructure.tailscale.auth_key
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
      role = "agent"
      copy_kubeconfig = false
      node_labels = {
        "dera.ovh/country" = "germany"
        "dera.ovh/provider" = "oci"
        "dera.ovh/type" = "vm"
        "openebs.io/localpv-zfs" = false
        "openebs.io/nodeid" = "oci-fra-k3s-1"
      }
    }
  }
  oci-fra-k3s-2 = {
    managed  = false
    provider = "oracle"
    user     = "opc"
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
      version   = "1.56.1"
      auth_key  = global.infrastructure.tailscale.auth_key
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
        "openebs.io/localpv-zfs" = false
        "openebs.io/nodeid" = "oci-fra-k3s-2"
      }
    }
  }
  byte-fra-k3s-0 = {
    managed  = true
    provider = "bytehosting"
    user     = "muneeb"
    host = {
      ipv4 = "45.134.39.35"
      ipv6 = "2a0e:97c0:3ea:29::1"
    }
    hostname        = "byte-fra-k3s-0"
    provider_config = {}
    tailscale_config = {
      version   = "1.56.1"
      auth_key  = global.infrastructure.tailscale.auth_key
      exit_node = false
      mtu       = "1280"
    }
    zfs_config = {
      enable = true
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
        "dera.ovh/provider" = "bytehosting"
        "dera.ovh/type" = "vm"
        "openebs.io/localpv-zfs" = true
        "openebs.io/nodeid" = "byte-fra-k3s-0"
      }
    }
  }
  hzn-neu-k3s-0 = {
    managed  = true
    provider = "hetzner"
    user     = "muneeb"
    host = {
      ipv4 = "78.46.252.116"
      ipv6 = "2a01:4f8:c0c:4015::1"
    }
    hostname        = "hzn-neu-k3s-0"
    provider_config = {}
    tailscale_config = {
      version   = "1.56.1"
      auth_key  = global.infrastructure.tailscale.auth_key
      exit_node = false
      mtu       = "1280"
    }
    zfs_config = {
      enable = true
      loopback = {
        loop0 = {
          path = "/mnt/zfs-loop0.img"
          size = "15G"
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
        "openebs.io/localpv-zfs" = true
        "openebs.io/nodeid" = "hzn-neu-k3s-0"
      }
    }
  }
  netcup-neu-k3s-0 = {
    managed  = true
    provider = "netcup"
    user     = "muneeb"
    host = {
      ipv4 = "46.232.249.165"
      ipv6 = "2a03:4000:2b:74:6466:f3ff:fe64:150"
    }
    hostname        = "netcup-neu-k3s-0"
    provider_config = {}
    tailscale_config = {
      version   = "1.56.1"
      auth_key  = global.infrastructure.tailscale.auth_key
      exit_node = true
      mtu       = "1280"
    }
    zfs_config = {
      enable = true
      loopback = {
        loop0 = {
          path = "/mnt/zfs-loop0.img"
          size = "20G"
        }
        loop1 = {
          path = "/mnt/zfs-loop1.img"
          size = "5G"
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
        "dera.ovh/provider" = "netcup"
        "dera.ovh/type" = "vm"
        "openebs.io/localpv-zfs" = true
        "openebs.io/nodeid" = "netcup-neu-k3s-0"
      }
    }
  }
}

globals "infrastructure" "config" {
  use_ipv6          = true
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
    muneeb = {
      sudo     = true
      password = null
    }
    k3s = {
      sudo     = true
      password = null
    }
  }
}

globals "infrastructure" "k3s" {
  version = "v1.28.5+k3s1"
  api_host = "oci-fra-k3s-0"
}

globals "apps" {
  backups = [
    "filebrowser",
    "homebox"
  ]
}