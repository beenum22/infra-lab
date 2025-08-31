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
  default = "4.4.0-develop"
}

variable "chart_url" {
  type = string
  default = "https://openebs.github.io/openebs"
}
