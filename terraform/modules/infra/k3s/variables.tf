variable "name" {
  type = string
  default = "k3s"
}

variable "k3s_version" {
  type = string
  default = "latest"
}

variable "use_sudo" {
  type = bool
  default = true
}

variable "cluster_init" {
  type = string
  default = false
}

variable "cluster_role" {
  type = string
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

variable "kubeconfig" {
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

variable "node_labels" {
  type = map(string)
  default = {}
}

variable "hostname" {
  type = string
}

variable "connection_info" {
  type = object({
    user = string
    host = string
    port = number
    private_key = string
  })
}

variable "use_ipv6" {
  type = bool
  default = false
}

variable "tailnet" {
  type = string
}

variable "graceful_destroy" {
  type = bool
  default = false
}

variable "tls_config" {
  type = map(string)
  default = {}
}
