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
  default = "tailscale-subnet-router"
}

variable "namespace" {
  type = string
  default = "tailscale"
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
  default = []
}

variable "mtu" {
  type = string
  default = "1280"
}

variable "userspace_mode" {
  type = bool
  default = true
}
