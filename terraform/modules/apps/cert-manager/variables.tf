variable "flux_managed" {
  type = bool
  default = false
  description = "Whether the application is managed by FluxCD."
}

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
  default = "1.17.1"
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
