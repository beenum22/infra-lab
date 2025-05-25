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

variable "namespace" {
  type = string
  default = "tekton"
  description = "Namespace where Tekton Operator will be installed."
}

variable "chart_url" {
  type = string
  default = "https://github.com/tektoncd/operator/releases/download"
  description = "URL of the Helm chart repository for Tekton Operator."
}

variable "name" {
  type = string
  default = "tekton-operator"
  description = "Name of the Helm release for Tekton Operator."
}

variable "chart_name" {
  type = string
  default = "tekton-operator"
  description = "Name of the Helm chart for Tekton Operator."
}

variable "chart_version" {
  type = string
  default = "0.75.0"
  description = "Version of the Helm chart for Tekton Operator."
}

variable "ingress_class" {
  type = string
  default = "nginx"
  description = "Ingress class to use for the Tekton Operator ingress."
}

variable "issuer" {
  type = string
  description = "Issuer for the TLS certificates."
}

variable "domains" {
  type = list(string)
  description = "List of domains for which the Tekton Operator ingress will be configured."
}

variable "extra_values" {
  type = map(string)
  default = {}
  description = "Additional values to pass to the Helm chart."
}
