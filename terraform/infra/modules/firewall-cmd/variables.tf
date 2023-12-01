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

variable "services" {
  type = list(string)
  default = [
    "k3s",
    "tailscale",
  ]
}

variable "use_sudo" {
  type = bool
  default = true
}
