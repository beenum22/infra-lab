variable "name" {
  type = string
  default = "tailscale-subnet-router"
}

variable "hostname" {
  type = string
}

variable "namespace" {
  type = string
  default = "tailscale"
}

variable "routes" {
  type = list(string)
}
