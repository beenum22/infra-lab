variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
}

variable "name" {
  type = string
  default = "cert-manager"
}

variable "namespace" {
  type = string
  default = "security"
}

variable "chart_name" {
  type = string
  default = "cert-manager"
}

variable "chart_url" {
  type = string
  default = "https://charts.jetstack.io"
}

variable "chart_version" {
  type = string
  default = "1.12.1"
}

variable "webhook_chart_name" {
  type = string
  default = "cert-manager-webhook-ovh"
}

variable "webhook_chart_url" {
  type = string
  default = "https://aureq.github.io/cert-manager-webhook-ovh/"
}

variable "webhook_chart_version" {
  type = string
  default = "0.4.2"
}

variable "webhook_image" {
  type = string
  default = "ghcr.io/aureq/cert-manager-webhook-ovh"
}

variable "webhook_tag" {
  type = string
  default = "v0.4.2"
}

variable "image" {
  type = string
  default = "quay.io/jetstack/cert-manager-controller"
}

variable "tag" {
  type = string
  default = "v1.12.1"
}

variable "domain_email" {
  type = string
}

variable "group_name" {
  type = string
}

variable "ovh_consumer_key" {
  type = string
}

variable "ovh_app_key" {
  type = string
}

variable "ovh_app_secret" {
  type = string
  sensitive = true
}

variable "ingress_class" {
  type = string
}
