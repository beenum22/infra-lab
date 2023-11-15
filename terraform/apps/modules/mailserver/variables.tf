variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
}

variable "name" {
  type = string
  default = "mailserver"
}

variable "namespace" {
  type = string
  default = "apps"
}

variable "chart_name" {
  type = string
  default = "mailserver"
}

variable "chart_version" {
  type = string
  default = "10.5.0"
}

variable "chart_url" {
  type = string
  default = "https://docker-mailserver.github.io/docker-mailserver-helm/"
}

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
