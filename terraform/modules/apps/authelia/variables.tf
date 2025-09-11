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
  default = "0.10.40"
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

variable "oidc_authorization_policies" {
  type = map(object({
    default_policy = string
    rules = list(object({
      policy  = string
      domain  = optional(list(string))
      subject = optional(list(string))
    }))
  }))
  default = {}
  description = "Authorization policies for OIDC clients"
}

variable "oidc_clients" {
  type = list(object({
    client_id                        = string
    client_name                      = string
    client_secret                    = string
    public                           = bool
    claims_policy                    = optional(string, "")
    authorization_policy             = string
    require_pkce                     = optional(bool, false)
    pkce_challenge_method            = optional(string, "plain")
    consent_mode                     = optional(string, "auto")
    redirect_uris                    = list(string)
    scopes                           = list(string)
    response_types                   = optional(list(string), ["code"])
    grant_types                      = list(string)
    access_token_signed_response_alg = optional(string, "none")
    # userinfo_signed_response_alg     = optional(string, "none")
    token_endpoint_auth_method       = optional(string, "none")
  }))
  default = []
  description = "List of OIDC clients to configure for various applications"
  sensitive = true

  validation {
    condition = alltrue([
      for client in var.oidc_clients : 
      client.public == true ? client.token_endpoint_auth_method == "none" : true
    ])
    error_message = "When public=true, token_endpoint_auth_method must be 'none' for OIDC security compliance."
  }
}
