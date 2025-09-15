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
  default = "jellyfin"
}

variable "namespace" {
  type = string
  default = "apps"
}

variable "storage_class" {
  type = string
  default = "local-path"
}

variable "config_storage" {
  type = string
  default = "1Gi"
}

variable "data_storage" {
 type = string
 default = "10Gi"
}

variable "chart_name" {
  type = string
  default = "jellyfin"
  description = "Name of the Helm chart for Jellyfin."
}

variable "chart_version" {
  type = string
  default = "2.3.0"
  description = "Version of the Helm chart for Jellyfin."
}

variable "chart_url" {
  type = string
  default = "https://jellyfin.github.io/jellyfin-helm"
  description = "URL of the Helm chart repository for Jellyfin."
}

variable "replicas" {
  type = number
  default = 1
}

variable "image" {
  type = string
  default = "linuxserver/jellyfin"
}

variable "tag" {
  type = string
  default = "latest"
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

variable "shared_pvcs" {
  type = list(object({
    name = string
    path = string
  }))
}

variable "node_selectors" {
  type = map(string)
  default = null
}

variable "oidc_client" {
  type = object({
    id                 = string
    secret             = string
    provider_name      = string
    provider_endpoint  = string
    admin_roles        = list(string)
    user_roles         = list(string)
  })
  description = "OIDC client configuration for SSO authentication"
  sensitive = true
}

variable "plugin_versions" {
  type = object({
    sso_auth = string
    custom_js = string
  })
  description = "Jellyfin plugin versions"
  default = {
    sso_auth = "3.5.2.4"
    custom_js = "0.0.0.2"
  }
}

variable "admin_username" {
  type        = string
  default     = "admin"
  description = "Default admin username (optional if using SSO-only)"
}

variable "admin_password" {
  type        = string
  default     = ""
  description = "Default admin password (leave empty to skip user creation)"
  sensitive   = true
}

variable "live_tv" {
  type = object({
    enabled = bool
    m3u_url = optional(string)
    epg_url = optional(string)
    user_agent = optional(string)
    refresh_hours = optional(number)
  })
  description = "Live TV configuration with M3U playlist and EPG settings"
  default = {
    enabled = false
  }
}

variable "velero_config" {
  type = object({
    backup = object({
      enabled = bool
      schedule = string
      retention_days = number
      storage_location = string
      volume_snapshot_location = string
    })
    restore = object({
      enabled = bool
      backup_name = optional(string)
    })
    namespace = string
  })
  description = "Velero configuration for backup and restore. If backup_name is not provided, restore will use latest backup from the same schedule."
}

variable "velero_chart_name" {
  type = string
  default = "velero-backup-restore"
  description = "Name of the Velero backup restore Helm chart."
}

variable "velero_chart_version" {
  type = string
  default = "0.1.0"
  description = "Version of the Velero backup restore Helm chart."
}

variable "velero_chart_url" {
  type = string
  default = "https://beenum22.github.io/infra-lab"
  description = "URL of the Velero backup restore Helm chart repository."
}
