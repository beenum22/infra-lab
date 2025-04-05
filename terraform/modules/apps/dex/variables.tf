variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
}

variable "name" {
  type = string
  default = "dex"
}

variable "namespace" {
  type = string
  default = "apps"
}

variable "chart_name" {
  type = string
  default = "dex"
}

variable "chart_version" {
  type = string
  default = "0.23.0"
}

variable "chart_url" {
  type = string
  default = "https://charts.dexidp.io"
}

variable "tag" {
  type = string
  default = "v2.42.0"
}

# variable "ingress_class" {
#   type = string
#   default = "nginx"
# }

# variable "ingress_hostname" {
#   type = string
# }

# variable "issuer" {
#   type = string
# }

variable "domains" {
  type = list(string)
  default = []
}
