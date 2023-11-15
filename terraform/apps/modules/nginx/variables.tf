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
  default = "4.6.1"
}

variable "chart_url" {
  type = string
  default = "https://kubernetes.github.io/ingress-nginx"
}

variable "image" {
  type = string
  default = "ingress-nginx/controller"
}

variable "tag" {
  type = string
  default = "v1.7.1"
}

variable "domain" {
  type = string
}
