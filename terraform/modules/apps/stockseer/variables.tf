variable "flux_managed" {
  type = bool
  default = false
  description = "Whether the application is managed by FluxCD."
}

# variable "flux_bucket" {
#   type = string
#   description = "Name of the B2 bucket for Flux patches."
# }

variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
  description = "Path to the kubeconfig file for the Kubernetes cluster."
}

variable "name" {
  type = string
  default = "stockseer"
  description = "Name of the Helm release for Stockseer."
}

variable "namespace" {
  type = string
  default = "stockseer"
  description = "Namespace where Stockseer will be installed."
}

variable "image" {
  type = string
  default = "ghcr.io/aniskhan25/stockseer"
}

variable "tag" {
  type = string
  default = "main"
}

variable "ingress_class" {
  type = string
  default = "nginx"
  description = "Ingress class to use for the Stockseer ingress."
}

variable "issuer" {
  type = string
  description = "Issuer for the TLS certificates."
}

variable "domains" {
  type = list(string)
  description = "List of domains for which the Stockseer ingress will be configured."
}
