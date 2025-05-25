variable "flux_managed" {
  type = bool
  default = false
  description = "Whether the application is managed by FluxCD."
}

variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
  description = "Path to the kubeconfig file for the Kubernetes cluster."
}

variable "name" {
  type = string
  default = "woodpecker"
  description = "Name of the Helm release for Woodpecker CI."
}

variable "namespace" {
  type = string
  default = "woodpecker"
  description = "Namespace where Woodpecker CI will be installed."
}

variable "chart_name" {
  type = string
  default = "woodpecker"
  description = "Name of the Helm chart for Woodpecker CI."
}

variable "chart_version" {
  type = string
  default = "3.1.1"
  description = "Version of the Helm chart for Woodpecker CI."
}

variable "chart_url" {
  type = string
  default = "https://woodpecker-ci.org/"
  description = "URL of the Helm chart repository for Woodpecker CI."
}

variable "ingress_class" {
  type = string
  default = "nginx"
  description = "Ingress class to use for the Woodpecker CI ingress."
}

variable "issuer" {
  type = string
  description = "Issuer for the TLS certificates."
}

variable "domains" {
  type = list(string)
  description = "List of domains for which the Woodpecker CI ingress will be configured."
}

variable "github_client_id" {
  type = string
  description = "GitHub OAuth Client ID for Woodpecker CI."
}

variable "github_client_secret" {
  type = string
  description = "GitHub OAuth Client Secret for Woodpecker CI."
}

variable "extra_values" {
  type = map(string)
  default = {}
}
