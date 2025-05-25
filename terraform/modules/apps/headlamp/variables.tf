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
  default = "headlamp"
  description = "Name of the Helm release for Headlamp."
}

variable "namespace" {
  type = string
  default = "headlamp"
  description = "Namespace where Headlamp will be installed."
}

variable "chart_name" {
  type = string
  default = "headlamp"
  description = "Name of the Helm chart for Headlamp."
}

variable "chart_version" {
  type = string
  default = "0.30.1"
  description = "Version of the Helm chart for Headlamp."
}

variable "chart_url" {
  type = string
  default = "https://kubernetes-sigs.github.io/headlamp"
  description = "URL of the Helm chart repository for Headlamp."
}

variable "ingress_class" {
  type = string
  default = "nginx"
  description = "Ingress class to use for the Headlamp ingress."
}

variable "issuer" {
  type = string
  description = "Issuer for the TLS certificates."
}

variable "domains" {
  type = list(string)
  description = "List of domains for which the Headlamp ingress will be configured."
}

# TODO: Plugins need to be configured properly
variable "plugins" {
  type = list(string)
  default = []
  description = "List of plugins to enable in Headlamp."
}
