variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
}

variable "name" {
  type = string
  default = "dashy"
}

variable "namespace" {
  type = string
  default = "apps"
}

variable "replicas" {
  type = number
  default = 1
}

variable "image" {
  type = string
  default = "ghcr.io/lissy93/dashy"
}

variable "tag" {
  type = string
  default = "latest"
}

variable "ingress_class" {
  type = string
  default = "nginx"
}

variable "ingress_host" {
  type = string
}

variable "issuer" {
  type = string
}

variable "domains" {
  type = list(string)
}
