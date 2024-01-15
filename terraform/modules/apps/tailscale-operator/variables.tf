variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
}

variable "name" {
  type = string
  default = "tailscale-operator"
}

variable "namespace" {
  type = string
  default = "network"
}

#variable "image" {
#  type = string
#  default = null
#}
#
#variable "tag" {
#  type = string
#  default = null
#}
#
#variable "dualstack" {
#  type = bool
#  default = true
#}
#
#variable "expose" {
#  type = bool
#  default = false
#}
#
#variable "ingress_class" {
#  type = string
#  default = "nginx"
#}

#variable "issuer" {
#  type = string
#}
#
#variable "domains" {
#  type = list(string)
#  default = []
#}

#variable "password" {
#  type = string
#  default = "admin"
#  sensitive = true
#}

#variable "publish" {
#  type = bool
#  default = false
#}

#variable "ingress_hostname" {
#  type = string
#}

variable "client_id" {
  type = string
  sensitive = true
}

variable "client_secret" {
  type = string
  sensitive = true
}

variable "extra_values" {
  type = map(string)
  default = {}
}
