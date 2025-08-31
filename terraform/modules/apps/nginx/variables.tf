variable "flux_managed" {
  type = bool
  default = false
  description = "Whether the application is managed by FluxCD."
}

variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
}

variable "name" {
  type = string
  default = "ingress-nginx"
}

variable "namespace" {
  type = string
  default = "network"
}

variable "chart_name" {
  type = string
  default = "ingress-nginx"
}

variable "chart_version" {
  type = string
  default = "4.10.0"
}

variable "chart_url" {
  type = string
  default = "https://kubernetes.github.io/ingress-nginx"
}

variable "domain" {
  type = string
}

variable "expose_on_tailnet" {
  type = bool
  default = false
}

variable "tailnet_hostname" {
  type = string
  default = "wormhole"
}
