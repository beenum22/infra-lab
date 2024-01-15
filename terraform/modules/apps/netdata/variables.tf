variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
}

variable "name" {
  type = string
  default = "netdata"
}

variable "namespace" {
  type = string
  default = "monitoring"
}

variable "chart_name" {
  type = string
  default = "netdata"
}

variable "chart_version" {
  type = string
  default = "3.7.80"
}

variable "chart_url" {
  type = string
  default = "https://netdata.github.io/helmchart"
}

//variable "image" {
//  type = string
//  default = null
//}
//
//variable "tag" {
//  type = string
//  default = null
//}

variable "dualstack" {
  type = bool
  default = true
}

variable "expose" {
  type = bool
  default = false
}

variable "ingress_class" {
  type = string
  default = "nginx"
}

variable "issuer" {
  type = string
}

variable "domains" {
  type = list(string)
  default = []
}

variable "ingress_password" {
  type = string
  default = null
  sensitive = true
}

variable "publish" {
  type = bool
  default = false
}

variable "ingress_hostname" {
  type = string
}

variable "ingress_protection" {
  type = bool
  default = false
}

variable "storage_class" {
  type = string
  default = "local-path"
}

variable "parent_database_storage_size" {
  type = string
  default = "2Gi"
}

variable "parent_alarm_storage_size" {
  type = string
  default = "1Gi"
}

variable "k8s_state_storage_size" {
  type = string
  default = "1Gi"
}

variable "extra_values" {
  type = map(string)
  default = {}
}
