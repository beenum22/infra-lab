variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
}

variable "name" {
  type = string
  default = "dashdot"
}

variable "namespace" {
  type = string
  default = "monitoring"
}

variable "image" {
  type = string
  default = "mauricenino/dashdot"
}

variable "tag" {
  type = string
  default = "5.8.3"
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
#
# variable "publish" {
#   type = bool
#   default = false
# }
