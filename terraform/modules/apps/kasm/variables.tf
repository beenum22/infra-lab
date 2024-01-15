variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
}

variable "name" {
  type = string
  default = "kasm"
}

variable "namespace" {
  type = string
  default = "monitoring"
}

variable "storage_class" {
  type = string
  default = "local-path"
}

variable "replicas" {
  type = number
  default = 1
}

variable "chart_name" {
  type = string
  default = "kasm"
}

variable "chart_version" {
  type = string
  default = "4.0.18"
}

variable "chart_url" {
  type = string
  default = "https://charts.truecharts.org/"
}

variable "image" {
  type = string
  default = "linuxserver/kasm"
}

variable "tag" {
  type = string
  default = "1.13.0"
}

variable "ingress_class" {
  type = string
  default = "nginx"
}
