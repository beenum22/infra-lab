variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
}

variable "name" {
  type = string
  default = "mailu"
}

variable "namespace" {
  type = string
  default = "apps"
}

variable "chart_name" {
  type = string
  default = "mailu"
}

variable "chart_version" {
  type = string
  default = "0.3.5"
}

variable "chart_url" {
  type = string
  default = "https://mailu.github.io/helm-charts"
}

//variable "image" {
//  type = string
//  default = "ghcr.io/toboshii/hajimari"
//}
//
//variable "tag" {
//  type = string
//  default = "v0.3.1"
//}

variable "storage_class" {
  type = string
  default = "local-path"
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

variable "mail_domain" {
  type = string
  default = "dera.ovh"
}

variable "password" {
  type = string
  sensitive = true
}

variable "subnets" {
  type = object({
    ipv4 = string
    ipv6 = string
  })
  default = {
    ipv4 = ""
    ipv6 = ""
  }
}
