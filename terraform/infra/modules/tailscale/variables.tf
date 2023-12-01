variable "connection_info" {
  type = object({
    user = string
    host = string
    private_key = string
  })
  default = {
    user = null
    host = null
    private_key = null
  }
}

variable "tailscale_version" {
  type = string
  default = "1.52.0"
}

variable "tailscale_mtu" {
  type = string
#  default = "1280"
   default = "1350"
}

variable "authkey" {
  type = string
}

variable "hostname" {
  type = string
}

variable "os" {
  type = string
  default = "oracle"
}

variable "tailnet" {
  type = string
}

variable "use_sudo" {
  type = bool
  default = true
}

variable "routes" {
  type = list(string)
  default = []
}
