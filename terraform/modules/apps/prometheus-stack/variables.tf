variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
}

variable "name" {
  type = string
  default = "kube-prometheus-stack"
}

variable "namespace" {
  type = string
  default = "monitoring"
}

variable "chart_name" {
  type = string
  default = "kube-prometheus-stack"
}

variable "chart_version" {
  type = string
  default = "56.6.2"
}

variable "chart_url" {
  type = string
  default = "https://prometheus-community.github.io/helm-charts"
}

variable "grafana_password" {
  type = string
  sensitive = true
}

variable "retention_period" {
  type = string
  default = "10d"
}

variable "storage_class" {
  type = string
  default = "openebs-zfs"
}

variable "storage_size" {
  type = string
  default = "20Gi"
}

variable "ingress_class" {
  type = string
  default = "nginx"
}

variable "issuer" {
  type = string
}

variable "grafana_domains" {
  type = list(string)
  default = []
}

variable "prometheus_domains" {
  type = list(string)
  default = []
}

variable "ingress_hostname" {
  type = string
}
