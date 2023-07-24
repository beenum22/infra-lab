variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
}

variable "name" {
  type = string
  default = "pihole"
}

variable "namespace" {
  type = string
  default = "dns"
}

variable "chart_name" {
  type = string
  default = "pihole"
}

variable "chart_version" {
  type = string
  default = "2.11.1"
}

variable "chart_url" {
  type = string
  default = "https://mojo2600.github.io/pihole-kubernetes/"
}

variable "image" {
  type = string
  default = "pihole/pihole"
}

variable "tag" {
  type = string
  default = "2023.03.1"
}

variable "dualstack" {
  type = bool
  default = true
}

variable "expose" {
  type = bool
  default = false
}

variable "ingress_class" {
  type = string
  default = "traefik"
}

variable "issuer" {
  type = string
}

variable "domains" {
  type = list(string)
  default = []
}

variable "password" {
  type = string
  default = "admin"
  sensitive = true
}

variable "publish" {
  type = bool
  default = false
}
