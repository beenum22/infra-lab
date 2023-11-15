variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
}

variable "name" {
  type = string
  default = "kube-ops-view"
}

variable "namespace" {
  type = string
  default = "apps"
}

variable "chart_name" {
  type = string
  default = "kube-ops-view"
}

variable "chart_version" {
  type = string
  default = "2.10.0"
}

variable "chart_url" {
  type = string
  default = "https://christianknell.github.io/helm-charts"
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
  default = true
}

variable "ingress_hostname" {
  type = string
}

variable "extra_values" {
  type = map(string)
  default = {}
}
