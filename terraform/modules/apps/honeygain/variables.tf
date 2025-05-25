variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
  description = "Path to the kubeconfig file for the Kubernetes cluster."
}

variable "name" {
  type = string
  default = "honeygain"
  description = "Name of the Honeygain Deployment."
}

variable "namespace" {
  type = string
  default = "apps"
  description = "Namespace where Honeygain will be installed."
}

variable "image" {
  type = string
  default = "honeygain/honeygain"
  description = "Docker image for Honeygain."
}

variable "tag" {
  type = string
  default = "0.8.1"
  description = "Tag of the Honeygain Docker image."
}

variable "account_name" {
  type = string
  description = "Honeygain account name/email ID."
}

variable "account_password" {
  type = string
  description = "Honeygain account password."
}

variable "node_selector" {
  type = map(string)
  default = null
  description = "Node selector for Honeygain pods."
}
