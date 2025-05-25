variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
  description = "Path to the kubeconfig file for the Kubernetes cluster."
}

variable "name" {
  type = string
  default = "fluxcd"
  description = "Name of the Helm release for FluxCD."
}

variable "namespace" {
  type = string
  default = "fluxcd"
  description = "Namespace where FluxCD will be installed."
}

variable "chart_name" {
  type = string
  default = "flux2"
  description = "Name of the Helm chart for FluxCD."
}

variable "chart_version" {
  type = string
  default = "2.15.0"
  description = "Version of the Helm chart for FluxCD."
}

variable "chart_url" {
  type = string
  default = "https://fluxcd-community.github.io/helm-charts"
  description = "URL of the Helm chart repository for FluxCD."
}

variable "extra_values" {
  type = map(string)
  default = {}
  description = "Additional values to be passed to the Helm chart for FluxCD."
}
