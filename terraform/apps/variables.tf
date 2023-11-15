variable "kubeconfig" {
  type = string
  default = "~/.kube/config"
}

variable "tailscale_namespace" {
  type = string
  default = "tailscale"
}

variable "tailscale_client_id" {
  type = string
}

variable "tailscale_client_secret" {
  type = string
}

variable "tailscale_proxy_image" {
  type = string
  default = "beenum/tailscale-nftables:latest"
}

variable "tailscale_authkey" {
  type = string
  default = "tskey-auth-k6rWmo6CNTRL-ViFCSCmvYR4KPyCvHXWfR4aBvLzdvj5FT"
  sensitive = true
}

variable "tailscale_apikey" {
  type = string
  sensitive = true
}

variable "pihole_password" {
  type = string
  sensitive = true
}

variable "pihole_api_key" {
  type = string
  sensitive = true
}

variable "cert_manager_ovh_app_key" {
  type = string
  sensitive = true
}

variable "cert_manager_ovh_app_secret" {
  type = string
  sensitive = true
}

variable "cert_manager_ovh_consumer_key" {
  type = string
  sensitive = true
}

variable "mailu_password" {
  type = string
  sensitive = true
}

variable "netdata_password" {
  type = string
  sensitive = true
}
