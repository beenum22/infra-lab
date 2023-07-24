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
//
//variable "chart_url" {
//  type = string
//  default = "https://gtaylor.github.io/helm-charts"
//}
//
//variable "chart_name" {
//  type = string
//  default = "tailscale-subnet-router"
//}
//
//variable "chart_version" {
//  type = string
//  default = "1.2.1"
//}

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
  default = "v1.40.0"
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
