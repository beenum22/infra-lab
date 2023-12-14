variable "default_state" {
  type = string
}

variable "debug" {
  type = bool
}

variable "replay" {
  type = bool
}

variable "connection_info" {
  type = object({
    user = string
    host = string
    private_key_file = string
  })
}

variable "users" {
#  type = list(
#    object({
#      name = string
#      sudo = bool
#      exists = bool
#  }))
#  default = []
  type = map(object({
    sudo = bool
    exists = bool
    password = optional(string)
  }))
  default = {}
}

variable "ssh_keys" {
  type = list(string)
  default = []
}

variable "packages" {
  type = list(string)
  default = []
}

variable "hostname" {
  type = string
}

#variable "tailscale_config" {
#  type = map(string)
#}
