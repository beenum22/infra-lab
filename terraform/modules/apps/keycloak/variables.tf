variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
}

variable "name" {
  type = string
  default = "keycloak"
}

variable "namespace" {
  type = string
  default = "security"
}

variable "chart_name" {
  type = string
  default = "keycloak"
}

variable "chart_version" {
  type = string
  default = "18.1.0"
}

variable "chart_url" {
  type = string
  default = "https://charts.bitnami.com/bitnami"
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

variable "extra_values" {
  type = map(string)
  default = {}
}
