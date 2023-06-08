variable "name" {
  type = string
  default = "tailscale"
}

variable "image" {
  type = string
  default = "tailscale/tailscale"
}

variable "tag" {
  type = string
  default = "v1.40.0"
}

variable "volume_name" {
  type = string
  default = "tailscale-state"
}

variable "authkey" {
  type = string
}

variable "hostname" {
  type = string
}

variable "tailnet" {
  type = string
}

variable "routes" {
  type = list
  default = []
}
