variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
}

variable "name" {
  type = string
  default = "grafana"
}

variable "namespace" {
  type = string
  default = "monitoring"
}

variable "chart_name" {
  type = string
  default = "grafana"
}

variable "chart_version" {
  type = string
  default = "7.3.0"
}

variable "chart_url" {
  type = string
  default = "https://grafana.github.io/helm-charts"
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

variable "data_sources" {
  type = list(map(string))
}

variable "password" {
  type = string
  sensitive = true
}

variable "extra_values" {
  type = map(string)
  default = {}
}
