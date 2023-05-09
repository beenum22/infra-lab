variable "name" {
  type = string
  default = "tailscale"
}

variable "image" {
  type = string
  default = "tailscale/tailscale:v1.40.0"
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
