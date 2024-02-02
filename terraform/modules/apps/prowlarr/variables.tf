variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
}

variable "name" {
  type = string
  default = "prowlarr"
}

variable "namespace" {
  type = string
  default = "apps"
}

variable "storage_class" {
  type = string
  default = "openebs-zfs"
}

variable "config_storage" {
  type = string
  default = "1Gi"
}

variable "shared_pvcs" {
  type = list(string)
  default = []
}

variable "replicas" {
  type = number
  default = 1
}

variable "image" {
  type = string
  default = "linuxserver/prowlarr"
}

variable "tag" {
  type = string
  default = "1.13.1-nightly"
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
