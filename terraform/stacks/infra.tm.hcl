globals "infra" "cluster" "talos" {
  version = "1.8.2"
  k8s_version = "1.31.2"
}

globals "infra" "network" "tailscale" {
  tailnet  = "tail03622.ts.net"
  org = "muneeb.gandapur@gmail.com"
  version = "1.76.1"
  mtu = "1280"
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

globals "infra" "dns" {
  zone = "moinmoin.fyi"
}

globals "infra" "cluster" "instances" {
  oci-de-fra-0 = {
    managed  = false
    provider = "oracle"
    hostname = "oci-de-fra-0"
    provider_config = {
      shape_name    = "VM.Standard.A1.Flex"
      image_ocid    = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaujyukkfkoanatqanh2qe4bxhwwg2j44fjn2folihrfvsxd5jv5bq"
      vcpus         = 1
      memory        = 6
      boot_volume   = 50
      block_volumes = []
    }
    tailscale_config = {
      version   = global.infra.network.tailscale.version
      exit_node = false
      mtu       = global.infra.network.tailscale.mtu
      # routes    = "10.42.2.0/24,2001:cafe:42:3::/64"
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
      version = global.infra.cluster.talos.version
      boostrap = false
      cluster_endpoint = false
      type = "controlplane"
      node_labels = {
        "${global.infra.dns.zone}/country" = "germany"
        "${global.infra.dns.zone}/provider" = "oci"
        "${global.infra.dns.zone}/type" = "vm"
        "${global.infra.dns.zone}/owner" = "munna"
        "openebs.io/localpv-zfs" = false
        "openebs.io/nodeid" = "oci-de-fra-0"
      }
    }
  }
  oci-de-fra-1 = {
    managed  = false
    provider = "oracle"
    hostname = "oci-de-fra-1"
    provider_config = {
      shape_name    = "VM.Standard.A1.Flex"
      image_ocid    = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaujyukkfkoanatqanh2qe4bxhwwg2j44fjn2folihrfvsxd5jv5bq"
      vcpus         = 1
      memory        = 6
      boot_volume   = 50
      block_volumes = []
    }
    tailscale_config = {
      version   = global.infra.network.tailscale.version
      exit_node = true
      mtu       = global.infra.network.tailscale.mtu
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
  }
  # oci-fra-2 = {
  #   managed  = false
  #   provider = "oracle"
  #   user     = "opc"
  #   port     = 2203
  #   host     = {}
  #   hostname = null
  #   provider_config = {
  #     shape_name  = "VM.Standard.A1.Flex"
  #     image_ocid  = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaujyukkfkoanatqanh2qe4bxhwwg2j44fjn2folihrfvsxd5jv5bq"
  #     vcpus       = 2
  #     memory      = 12
  #     boot_volume = 50
  #     block_volumes = [
  #       50
  #     ]
  #   }
  #   tailscale_config = {
  #     version   = global.infrastructure.tailscale.version
  #     exit_node = false
  #     mtu       = "1280"
  #   }
  #   zfs_config = {
  #     enable = true
  #     loopback = {}
  #     devices = {
  #       sdb = {}
  #     }
  #   }
  #   k3s_config = {
  #     version = global.infrastructure.k3s.version
  #     init = false
  #     root_node = false
  #     role = "server"
  #     copy_kubeconfig = false
  #     node_labels = {
  #       "${global.infra.dns.zone}/country" = "germany"
  #       "${global.infra.dns.zone}/provider" = "oci"
  #       "${global.infra.dns.zone}/type" = "vm"
  #       "${global.infra.dns.zone}/owner" = "munna"
  #       "openebs.io/localpv-zfs" = true
  #       "openebs.io/nodeid" = "oci-fra-2"
  #       "openebs.io/nfs-server" = true
  #     }
  #   }
  # }
  #   Disabling Hetzner machines to save costs. Re-add later if needed.
  #   hzn-hel-0 = {
  #     managed  = false
  #     provider = "hetzner"
  #     user     = "muneeb"
  #     port     = 2203
  #     host = {}
  #     hostname        = "hzn-hel-0"
  #     provider_config = {
  #       image       = "alma-9"
  #       server_type = "cx11"
  #       datacenter  = "hel1-dc2"
  #       block_volumes = ["20"]
  #     }
  #     tailscale_config = {
  #       version   = global.infrastructure.tailscale.version
  #       exit_node = true
  #       mtu       = "1280"
  #     }
  #     zfs_config = {
  #       enable = true
  #       loopback = {
  #         loop1 = {
  #           path = "/mnt/zfs-loop1.img"
  #           size = "5G"
  #         }
  #       }
  #       devices = {
  #         sdb = {}
  #       }
  #     }
  #     k3s_config = {
  #       version = global.infrastructure.k3s.version
  #       init = false
  #       root_node = false
  #       role = "agent"
  #       copy_kubeconfig = false
  #       node_labels = {
  #         "${global.infra.dns.zone}/country" = "finland"
  #         "${global.infra.dns.zone}/provider" = "hetnzer"
  #         "${global.infra.dns.zone}/type" = "vm"
  #         "${global.infra.dns.zone}/owner" = "munna"
  #         "openebs.io/localpv-zfs" = true
  #         "openebs.io/nodeid" = "hzn-hel-0"
  #         "openebs.io/nfs-server" = true
  #       }
  #     }
  #   }
  #   Disabling Netcup machines to save costs. Re-add later if needed.
  #   netcup-neu-0 = {
  #     managed  = true
  #     provider = "netcup"
  #     user     = "muneeb"
  #     port     = 2203
  #     host = {
  #       ipv4 = "46.232.249.165"
  #       ipv6 = "2a03:4000:2b:74:6466:f3ff:fe64:150"
  #     }
  #     hostname        = "netcup-neu-0"
  #     provider_config = {}
  #     tailscale_config = {
  #       version   = global.infrastructure.tailscale.version
  #       exit_node = true
  #       mtu       = "1280"
  #     }
  #     zfs_config = {
  #       enable = true
  #       loopback = {}
  #       devices = {
  #         vda4 = {}
  #       }
  #     }
  #     k3s_config = {
  #       version = global.infrastructure.k3s.version
  #       init = true
  #       root_node = false
  #       role = "server"
  #       copy_kubeconfig = false
  #       node_labels = {
  #         "${global.infra.dns.zone}/country" = "germany"
  #         "${global.infra.dns.zone}/provider" = "netcup"
  #         "${global.infra.dns.zone}/type" = "vm"
  #         "${global.infra.dns.zone}/owner" = "munna"
  #         "openebs.io/localpv-zfs" = true
  #         "openebs.io/nodeid" = "netcup-neu-0"
  #       }
  #     }
  #   }
  #   rpi-dik-0 = {
  #     managed  = false
  #     provider = "self-hosted"
  #     user     = "pi"
  #     port     = 2203
  #     host = {
  #       ipv4 = "192.168.100.51"
  #       ipv6 = ""
  #     }
  #     hostname        = "rpi-dik-0"
  #     provider_config = {}
  #     tailscale_config = {
  #       version   = global.infrastructure.tailscale.version
  #       exit_node = true
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
  #         "${global.infra.dns.zone}/country" = "pakistan"
  #         "${global.infra.dns.zone}/provider" = "self-hosted"
  #         "${global.infra.dns.zone}/type" = "sbc"
  #         "${global.infra.dns.zone}/owner" = "munna"
  #         "openebs.io/localpv-zfs" = true
  #         "openebs.io/nodeid" = "rpi-dik-0"
  #         "openebs.io/nfs-server" = true
  #       }
  #     }
  #   }
}