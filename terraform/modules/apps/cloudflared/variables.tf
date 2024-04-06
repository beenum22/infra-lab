variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
}

variable "name" {
  type = string
  default = "cloudflared"
}

variable "namespace" {
  type = string
  default = "network"
}

variable "replicas" {
  type = number
  default = 1
}
#
variable "image" {
  type = string
  default = "cloudflare/cloudflared"
}

variable "tag" {
  type = string
  default = "2024.3.0"
}

variable "ingress_hostname" {
  type = string
}

variable "account_id" {
  type = string
}

variable "served_hostnames" {
  type = list(string)
  default = []
}
