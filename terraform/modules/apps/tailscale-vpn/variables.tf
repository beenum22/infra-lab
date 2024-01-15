variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
}

variable "annotations" {
  type = map(string)
  default = null
}

variable "labels" {
  type = map(string)
  default = null
}

variable "name" {
  type = string
  default = "tailscale-vpn"
}

variable "namespace" {
  type = string
  default = "network"
}

variable "replicas" {
  type = number
  default = 1
}

variable "authkey" {
  type = string
}

variable "image" {
  type = string
  default = "tailscale/tailscale"
}

variable "tag" {
  type = string
  default = "latest"
}

variable "routes" {
  type = list(string)
}

variable "extra_args" {
  type = list(string)
  default = ["--advertise-exit-node", "--accept-dns"]
}

variable "mtu" {
  type = string
  default = "1280"
}

variable "vpn_label" {
  type = string
  default = "dera.ovh/country"
}

variable "vpn_countries" {
  type = list(string)
  default = [
    "germany"
  ]
}

variable "userspace_mode" {
  type = bool
  default = true
}
