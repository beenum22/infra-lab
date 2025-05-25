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
  default = "drone"
  description = "Name of the Helm release for Drone CI."
}

variable "namespace" {
  type = string
  default = "drone"
  description = "Namespace where Drone CI will be installed."
}

variable "chart_name" {
  type = string
  default = "drone"
  description = "Name of the Helm chart for Drone CI."
}

variable "chart_version" {
  type = string
  default = "0.1.3"
  description = "Version of the Helm chart for Drone CI."
}

variable "chart_url" {
  type = string
  default = "https://community-charts.github.io/helm-charts"
  description = "URL of the Helm chart repository for Drone CI."
}

variable "ingress_class" {
  type = string
  default = "nginx"
  description = "Ingress class to use for the Drone CI ingress."
}

variable "issuer" {
  type = string
  description = "Issuer for the TLS certificates."
}

variable "domains" {
  type = list(string)
  description = "List of domains for which the Drone CI ingress will be configured."
}

variable "extra_values" {
  type = map(string)
  default = {}
  description = "Additional values to be passed to the Helm chart for Drone CI."
}
