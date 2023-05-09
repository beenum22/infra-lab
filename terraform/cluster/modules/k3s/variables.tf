variable "name" {
  type = string
  default = "k3s"
}

variable "image" {
  type = string
  default = "rancher/k3s"
}

variable "volume_name" {
  type = string
  default = "k3s_volume"
}

variable "cluster_init" {
  type = string
  default = false
}

variable "cluster_role" {
  type = string
//  validation {
//    condition = var.cluster_role in
//  }
}

variable "flannel_interface" {
  type = string
  default = "tailscale0"
}

variable "token" {
  type = string
}

variable "api_host" {
  type = string
  default = null
}

variable "cluster_cidrs" {
  type = string
  default = "10.42.0.0/16,2001:cafe:42:0::/56"
}

variable "service_cidrs" {
  type = string
  default = "10.43.0.0/16,2001:cafe:42:1::/112"
}

variable "node_ips" {
  type = object({
    ipv4 = string
    ipv6 = string
  })
}

variable "hostname" {
  type = string
}

variable "connection_info" {
  type = object({
    user = string
    host = string
    private_key = string
  })
  default = {
    user = null
    host = null
    private_key = null
  }
}

variable "use_ipv6" {
  type = bool
  default = false
}
