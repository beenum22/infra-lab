variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
}

variable "name" {
  type = string
  default = "plex"
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
  default = "linuxserver/plex"
}

variable "tag" {
  type = string
  default = "latest"
}

variable "ingress_class" {
  type = string
  default = "nginx"
}

variable "plex_token" {
  type = string
}
