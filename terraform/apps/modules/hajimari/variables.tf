variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
}

variable "name" {
  type = string
  default = "hajimari"
}

variable "namespace" {
  type = string
  default = "apps"
}

variable "chart_name" {
  type = string
  default = "hajimari"
}

variable "chart_version" {
  type = string
  default = "2.0.2"
}

variable "chart_url" {
  type = string
  default = "https://hajimari.io"
}

variable "image" {
  type = string
  default = "ghcr.io/toboshii/hajimari"
}

variable "tag" {
  type = string
  default = "v0.3.1"
}

variable "ingress_class" {
  type = string
  default = "nginx"
}

variable "issuer" {
  type = string
}

variable "domains" {
  type = list(string)
  default = []
}

variable "title" {
  type = string
  default = "Test Dashboard"
}

variable "enduser_name" {
  type = string
  default = "Dummies"
}

variable "target_namespaces" {
  type = list(string)
  default = ["default"]
}
