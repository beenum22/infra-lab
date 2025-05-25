variable "flux_managed" {
  type = bool
  default = false
  description = "Whether the release is managed by FluxCD."
}

variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
  description = "Path to the kubeconfig file for the Kubernetes cluster."
}

variable "namespace" {
  type = string
  default = "argo-events"
  description = "Namespace where Argo Events will be installed."
}

variable "chart_url" {
  type = string
  default = "https://argoproj.github.io/argo-helm"
  description = "URL of the Helm chart repository for Argo Events."
}

variable "name" {
  type = string
  default = "argo-events"
  description = "Name of the Helm release for Argo Events."
}

variable "chart_name" {
  type = string
  default = "argo-events"
  description = "Name of the Helm chart for Argo Events."
}

variable "chart_version" {
  type = string
  default = "2.4.15"
  description = "Version of the Helm chart for Argo Events."
}

variable "extra_values" {
  type = map(string)
  default = {}
  description = "Additional values to be passed to the Helm chart for Argo Events."
}
