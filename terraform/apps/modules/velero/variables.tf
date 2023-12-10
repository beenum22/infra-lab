variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
}

variable "name" {
  type = string
  default = "velero"
}

variable "namespace" {
  type = string
  default = "storage"
}

variable "chart_name" {
  type = string
  default = "velero"
}

variable "chart_version" {
  type = string
  default = "5.1.6"
}

variable "chart_url" {
  type = string
  default = "https://vmware-tanzu.github.io/helm-charts/"
}

variable "backup_provider" {
  type = string
  default = "aws"
}

variable "backup_storage_bucket" {
  type = string
}

variable "volume_snapshot_bucket" {
  type = string
}

variable "access_key_id" {
  type = string
  sensitive = true
}

variable "secret_access_key" {
  type = string
  sensitive = true
}
