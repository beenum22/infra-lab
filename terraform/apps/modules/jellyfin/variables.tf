variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
}

variable "name" {
  type = string
  default = "jellyfin"
}

variable "namespace" {
  type = string
  default = "apps"
}

variable "storage_class" {
  type = string
  default = "local-path"
}

variable "replicas" {
  type = number
  default = 1
}

variable "image" {
  type = string
  default = "linuxserver/jellyfin"
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

variable "publish" {
  type = bool
  default = false
}
