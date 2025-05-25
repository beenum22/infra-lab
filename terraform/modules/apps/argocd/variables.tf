variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
  description = "Path to the kubeconfig file for the Kubernetes cluster."
}

variable "name" {
  type = string
  default = "argocd"
  description = "Name of the Helm release for Argo CD."
}

variable "namespace" {
  type = string
  default = "apps"
  description = "Namespace where Argo CD will be installed."
}

variable "chart_name" {
  type = string
  default = "argo-cd"
  description = "Name of the Helm chart for Argo CD."
}

variable "chart_version" {
  type = string
  default = "8.0.0"
  description = "Version of the Helm chart for Argo CD."
}

variable "chart_url" {
  type = string
  default = "https://argoproj.github.io/argo-helm"
  description = "URL of the Helm chart repository for Argo CD."
}

variable "ingress_class" {
  type = string
  default = "nginx"
  description = "Ingress class to use for the Argo CD ingress."
}

variable "issuer" {
  type = string
  description = "Issuer for the TLS certificates."
}

variable "domain" {
  type = string
  description = "Domain for which the Argo CD ingress will be configured."
}

variable "admin_password" {
  type = string
  default = "admin"
  description = "Admin password for Argo CD."
}

variable "extra_values" {
  type = map(string)
  default = {}
  description = "Additional values to be passed to the Helm chart for Argo CD."
}
