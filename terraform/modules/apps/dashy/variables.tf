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
  default = "2.1.1"
}

variable "ingress_class" {
  type = string
  default = "nginx"
}

variable "ingress_hostname" {
  type = string
}

variable "issuer" {
  type = string
}

variable "domains" {
  type = list(string)
}

variable "page_config" {
  type = object({
    title = string
    description = string
    theme = string
  })
  default = {
    title = "Dera Lab"
    description = "Nur Der Dera"
    theme = "colorful"
  }
}