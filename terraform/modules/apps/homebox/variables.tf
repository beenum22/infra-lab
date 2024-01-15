variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
}

variable "name" {
  type = string
  default = "homebox"
}

variable "namespace" {
  type = string
  default = "apps"
}

variable "storage_class" {
  type = string
  default = "local-path"
}

variable "storage_size" {
  type = string
  default = "10Gi"
}

variable "replicas" {
  type = number
  default = 1
}

variable "image" {
  type = string
  default = "ghcr.io/hay-kot/homebox"
}

variable "tag" {
  type = string
  default = "v0.10.2"
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

variable "publish" {
  type = bool
  default = false
}
