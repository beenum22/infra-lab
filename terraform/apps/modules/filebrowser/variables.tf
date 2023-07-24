variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
}

variable "name" {
  type = string
  default = "filebrowser"
}

variable "namespace" {
  type = string
  default = "apps"
}

variable "storage_class" {
  type = string
  default = "local-path"
}

variable "image" {
  type = string
  default = "filebrowser/filebrowser"
}

variable "tag" {
  type = string
  default = "v2.18.0"
}

variable "chart_name" {
  type = string
  default = "filebrowser"
}

variable "chart_version" {
  type = string
  default = "1.4.2"
}

variable "chart_url" {
  type = string
  default = "https://k8s-at-home.com/charts/"
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

variable "publish" {
  type = bool
  default = false
}
