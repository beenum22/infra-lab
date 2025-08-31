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
  default = "authelia"
  description = "Name of the Helm release for Authelia."
}

variable "namespace" {
  type = string
  default = "authelia"
  description = "Namespace where Authelia will be installed."
}

variable "chart_name" {
  type = string
  default = "authelia"
  description = "Name of the Helm chart for Authelia."
}

variable "chart_version" {
  type = string
  default = "0.10.42"
  description = "Version of the Helm chart for Authelia."
}

variable "chart_url" {
  type = string
  default = "https://charts.authelia.com"
  description = "URL of the Helm chart repository for Authelia."
}

variable "ingress_class" {
  type = string
  default = "nginx"
  description = "Ingress class to use for the Authelia ingress."
}

variable "issuer" {
  type = string
  description = "Issuer for the TLS certificates."
}

variable "domains" {
  type = list(string)
  description = "List of domains for which the Authelia ingress will be configured."
}

variable "credentials" {
  type = object({
    users = map(object({
      disabled    = bool
      displayname = string
      password    = string
      # email      = string
      groups     = list(string)
    }))
  })
}

variable "storage_class" {
  type = string
  description = "Storage class to use for persistent volumes."
}

variable "extra_values" {
  type = map(string)
  default = {}
  description = "Additional values to be passed to the Helm chart for Authelia."
}
