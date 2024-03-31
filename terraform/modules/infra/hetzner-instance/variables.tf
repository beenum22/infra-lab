variable "name" {
  type = string
  default = "lab-k3s"
}

variable "server_type" {
  type = string
  default = "cx11"
}

variable "image" {
  type = string
  default = "alma-9"
}

variable "datacenter" {
  type = string
  default = "hel1-dc2"
}

variable "block_volumes" {
  type = list(string)
  default = []
}

variable "cloud_init_commands" {
  type = list(string)
  default = []
}

variable "subnets" {
  type = list(string)
}

variable "ssh_public_keys" {
  type    = list(string)
}

variable "enable_ipv4" {
  type = bool
  default = false
}

variable "enable_ipv6" {
  type = bool
  default = false
}
