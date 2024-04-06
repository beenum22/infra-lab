variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
}

variable "name" {
  type = string
  default = "http-echo"
}

variable "namespace" {
  type = string
  default = "apps"
}

variable "replicas" {
  type = number
  default = 1
}

variable "image" {
  type = string
  default = "hashicorp/http-echo"
}

variable "tag" {
  type = string
  default = "1.0"
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
}

variable "echo_message" {
  type = string
  default = "Hello World!"
}
