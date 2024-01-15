variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
}

variable "name" {
  type = string
  default = "jitsi-meet"
}

variable "namespace" {
  type = string
  default = "apps"
}

variable "chart_name" {
  type = string
  default = "jitsi-meet"
}

variable "chart_version" {
  type = string
  default = "1.3.6"
}

variable "chart_url" {
  type = string
  default = "https://jitsi-contrib.github.io/jitsi-helm/"
}

variable "publish" {
  type = bool
  default = true
}

variable "tag" {
  type = string
  default = "v0.3.1"
}

variable "ingress_class" {
  type = string
  default = "nginx"
}

variable "ingress_hostname" {
  type = string
}

variable "issuer" {
  type = string
}

variable "domains" {
  type = list(string)
  default = []
}

variable "title" {
  type = string
  default = "Test Dashboard"
}

variable "enduser_name" {
  type = string
  default = "Dummies"
}

variable "target_namespaces" {
  type = list(string)
  default = ["default"]
}
