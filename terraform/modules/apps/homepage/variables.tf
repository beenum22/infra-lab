variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
}

variable "name" {
  type = string
  default = "homepage"
}

variable "namespace" {
  type = string
  default = "monitoring"
}

variable "chart_name" {
  type = string
  default = "homepage"
}

variable "chart_version" {
  type = string
  default = "1.2.1"
}

variable "chart_url" {
  type = string
  default = "https://jameswynn.github.io/helm-charts"
}

variable "ingress_hostname" {
  type = string
}

variable "ingress_class" {
  type = string
  default = "nginx"
}

variable "domains" {
  type = list(string)
  default = []
}

variable "issuer" {
  type = string
}

variable "service_groups" {
  type = any
#  type = list(map(list(map(any))))
#  type = list(any)
  default = []
}

variable "extra_values" {
  type = map(string)
  default = {}
}
