variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
}

variable "name" {
  type = string
  default = "blocky"
}

variable "namespace" {
  type = string
  default = "dns"
}

variable "replicas" {
  type = number
  default = 2
}

variable "image" {
  type = string
  default = "ghcr.io/0xerr0r/blocky"
}

variable "tag" {
  type = string
  default = "v0.23"
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

variable "default_upstream_servers" {
  type = list(string)
  default = [
    "1.1.1.1",
    "tcp-tls:fdns1.dismail.de:853",
    # Disabling as it is not responding with answers
    #"https://dns.digitale-gesellschaft.ch/dns-query"
  ]
}

variable "custom_dns_mappings" {
  type = map(string)
  default = {}
}

variable "custom_dns_rewrites" {
  type = map(string)
  default = {}
}

variable "conditional_rewrites" {
  type = map(string)
  default = {}
}

variable "conditional_mappings" {
  type = map(string)
  default = {}
}

variable "blacklists" {
  type = map(string)
  default = {}
}

variable "expose_on_tailnet" {
  type = bool
  default = false
}

variable "tailnet_hostname" {
  type = string
  default = "dns-server"
}
