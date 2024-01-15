variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
}

variable "name" {
  type = string
  default = "openebs"
}

variable "namespace" {
  type = string
  default = "storage"
}

variable "chart_name" {
  type = string
  default = "openebs"
}

variable "chart_version" {
  type = string
  default = "3.9.0"
}

variable "chart_url" {
  type = string
  default = "https://openebs.github.io/charts"
}

variable "device_localpv" {
  type = bool
  default = true
}
