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
  default = "argo-workflows"
  description = "Namespace where Argo Workflows will be installed."
}

variable "chart_url" {
  type = string
  default = "https://argoproj.github.io/argo-helm"
  description = "URL of the Helm chart repository for Argo Workflows."
}

variable "name" {
  type = string
  default = "argo-workflows"
  description = "Name of the Helm release for Argo Workflows."
}

variable "chart_name" {
  type = string
  default = "argo-workflows"
  description = "Name of the Helm chart for Argo Workflows."
}

variable "chart_version" {
  type = string
  default = "0.45.14"
  description = "Version of the Helm chart for Argo Workflows."
}

variable "ingress_class" {
  type = string
  default = "nginx"
  description = "Ingress class to use for the Argo Workflows ingress."
}

variable "issuer" {
  type = string
  description = "Issuer for the TLS certificates."
}

variable "domains" {
  type = list(string)
  description = "List of domains for which the Argo Workflows ingress will be configured."
}

variable "extra_values" {
  type = map(string)
  default = {}
  description = "Additional values to be passed to the Helm chart for Argo Workflows."
}
