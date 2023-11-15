variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
}

variable "name" {
  type = string
  default = "longhorn"
}

variable "namespace" {
  type = string
  default = "storage"
}

variable "chart_name" {
  type = string
  default = "longhorn"
}

variable "chart_version" {
  type = string
  default = "1.4.2"
}

variable "chart_url" {
  type = string
  default = "https://charts.longhorn.io"
}

//variable "engine_image" {
//  type = string
//  default = "longhornio/longhorn-engine"
//}

variable "app_version" {
  type = string
  default = "v1.4.2"
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

variable "publish" {
  type = bool
  default = false
}

variable "extra_values" {
  type = map(string)
  default = {}
}
