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
    password = optional(string)
  }))
  default = {}
}

variable "default_ssh_key" {
  type = string
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

variable "zfs_config" {
  type = object({
    enable = bool
    loopback = map(any)
    devices = map(any)
  })
}

#variable "tailscale_config" {
#  type = map(string)
#}
