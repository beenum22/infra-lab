variable "flux_managed" {
  type = bool
  default = false
  description = "Whether the application is managed by FluxCD."
}

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
  default = "backup"
}

variable "storage_namespace" {
  type = string
  default = "storage"
}

variable "chart_name" {
  type = string
  default = "velero"
}

variable "chart_version" {
  type = string
  default = "10.1.0"
}

variable "chart_url" {
  type = string
  default = "https://vmware-tanzu.github.io/helm-charts/"
}

variable "access_key_id" {
  type = string
  sensitive = true
}

variable "secret_access_key" {
  type = string
  sensitive = true
}

variable "backup_storage" {
  type = object({
    location_name = string
    provider      = string
    bucket        = string
  })
}

variable "volume_snapshot" {
  type = object({
    location_name = string
    provider      = string
    bucket        = string
    namespace     = string
  })
}
