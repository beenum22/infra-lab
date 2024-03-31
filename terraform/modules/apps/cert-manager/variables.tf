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
  default = "1.14.4"
}

variable "domain_email" {
  type = string
}

variable "cloudflare_api_token" {
  type = string
}

variable "ingress_class" {
  type = string
}
