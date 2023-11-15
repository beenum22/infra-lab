variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
}

variable "name" {
  type = string
  default = "homepage"
}

variable "namespace" {
  type = string
  default = "monitoring"
}

variable "chart_name" {
  type = string
  default = "homepage"
}

variable "chart_version" {
  type = string
  default = "1.1.0"
}

variable "chart_url" {
  type = string
  default = "https://jameswynn.github.io/helm-charts"
}

variable "image" {
  type = string
  default = "ghcr.io/benphelps/homepage"
}

variable "tag" {
  type = string
  default = "v0.6.10"
}

variable "ingress_class" {
  type = string
  default = "nginx"
}

variable "domains" {
  type = list(string)
  default = []
}
