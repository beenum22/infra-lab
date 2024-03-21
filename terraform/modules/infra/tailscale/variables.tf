variable "connection_info" {
  type = object({
    user = string
    host = string
    port = number
    private_key = string
  })
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
  default = null
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

variable "exit_node" {
  type = bool
  default = false
}

variable "set_flags" {
  type = list(string)
  default = []
}
