variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
}

variable "name" {
  type = string
  default = "external-dns"
}

variable "namespace" {
  type = string
  default = "dns"
}

variable "chart_name" {
  type = string
  default = "external-dns"
}

variable "chart_url" {
  type = string
  default = "https://kubernetes-sigs.github.io/external-dns/"
}

variable "chart_version" {
  type = string
  default = "1.12.2"
}

variable "image" {
  type = string
  default = "registry.k8s.io/external-dns/external-dns"
}

variable "tag" {
  type = string
  default = "v0.13.4"
}

variable "pihole_password" {
  type = string
  sensitive = true
}

variable "pihole_server" {
  type = string
}
