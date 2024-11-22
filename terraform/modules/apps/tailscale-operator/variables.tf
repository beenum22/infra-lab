variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
}

variable "name" {
  type = string
  default = "tailscale-operator"
}

variable "namespace" {
  type = string
  default = "network"
}

variable "chart_name" {
  type = string
  default = "tailscale-operator"
}

variable "chart_version" {
  type = string
  default = "1.76.1"
}

variable "chart_url" {
  type = string
  default = "https://pkgs.tailscale.com/helmcharts"
}

variable "client_id" {
  type = string
  sensitive = true
}

variable "client_secret" {
  type = string
  sensitive = true
}

variable "extra_values" {
  type = map(string)
  default = {}
}
