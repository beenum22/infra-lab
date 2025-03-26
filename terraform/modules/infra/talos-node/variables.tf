variable "talos_version" {
  type = string
}

variable "k8s_version" {
  type = string
}

# variable "talosconfig_filepath" {
#   type = string
#   default = null
# }

# variable "kubeconfig_filepath" {
#   type = string
#   default = null
# }

variable "machine_secret" {
  type = object({
    id = string
    client_configuration = object({
      ca_certificate = string
      client_certificate = string
      client_key = string
    })
    machine_secrets = object({
      certs = object({
        etcd = object({
          cert = string
          key = string
        })
        k8s = object({
          cert = string
          key = string
        })
        k8s_aggregator = object({
          cert = string
          key = string
        })
        k8s_serviceaccount = object({
          key = string
        })
        os = object({
          cert = string
          key = string
        })
      })
      cluster = object({
        id = string
        secret = string
      })
      secrets = object({
        bootstrap_token = string
        secretbox_encryption_secret = string
      })
      trustdinfo = object({
        token = string
      })
    })
    talos_version = string
  })
}

variable "machine_name" {
  type = string
}

variable "machine_type" {
  type = string
}

variable "machine_domain" {
  type = string
}

variable "machine_network_overlay" {
  type = object({
    tailscale = object({
      advertise_exit_node = bool
      accept_routes = bool
      accept_dns = bool
      tailnet = string
    })
  })
}

variable "machine_bootstrap" {
  type = bool
}

variable "machine_cert_sans" {
  type = list(string)
}

# variable "cluster_network" {
#   type = object({
#     cni = object({
#       type = string
#       namespace = string
#       flannel = optional(object({
#         interface = string
#       }))
#     })
#     overlay = object({
#       type = string
#       tailscale = optional(object({
#         tailnet = string
#       }))
#     })
#   })
#   validation {
#     condition = contains(["flannel"], var.cluster_network.cni.type)
#     error_message = "CNI type must be 'flannel'."
#   }
#   validation {
#     condition = contains(["tailscale"], var.cluster_network.overlay.type)
#     error_message = "Overlay type must be 'tailscale'."
#   }
#   validation {
#     condition = var.cluster_network.cni.type != "flannel" || (var.cluster_network.cni.type == "flannel" && var.cluster_network.cni.flannel != null)
#     error_message = "Flannel CNI requires the flannel configuration object."
#   }
# }

variable "cluster_endpoint" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "cluster_advertised_subnets" {
  type = list(string)
}

# variable "cluster_pod_subnets" {
#   type = object({
#     ipv4 = string
#     ipv6 = string
#   })
# }

# variable "cluster_service_subnets" {
#   type = object({
#     ipv4 = string
#     ipv6 = string
#   })
# }

variable "machine_kernel_modules" {
  type = list(object({
    name = string
  }))
  default = [{
    name = "zfs"
  }]
}

variable "cluster_config" {
  type = object({
    cluster = object({
      allowSchedulingOnControlPlanes = bool
      etcd = object({
        advertisedSubnets = list(string)
      })
      network = object({
        podSubnets = list(string)
        serviceSubnets = list(string)
        cni = object({
          name = string
        })
      })
      inlineManifests = list(object({
        name = string
        contents = string
      }))
    })
  })
}
