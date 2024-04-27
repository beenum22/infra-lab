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

variable "data_storage" {
  type = string
  default = "5Gi"
}

variable "data_storage_class" {
  type = string
  default = "openebs-zfs"
}

variable "config_storage" {
  type = string
  default = "1Gi"
}

variable "config_storage_class" {
  type = string
  default = "openebs-zfs"
}

variable "image" {
  type = string
  default = "filebrowser/filebrowser"
}

variable "tag" {
  type = string
  default = "v2.28.0"
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
  default = []
}

variable "shared_pvcs" {
  type = list(string)
  default = []
}

variable "admin_password" {
  type = string
  sensitive = true
}
