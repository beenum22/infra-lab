//variable "hosts" {
//  type = list(object({
//    host_user = string
//    host_ip = string
//  }))
//}

variable "use_tailscale_ip" {
  type = bool
  default = false
}

variable "tailscale_authkey" {
  type = string
  default = "tskey-auth-kyoQKo1CNTRL-UbTurGjqcXEJVzHD9pVmTEfXj1m3aEUAQ"
}

variable "tailscale_apikey" {
  type = string
  default = "tskey-api-kKEjSs6CNTRL-sZJVW2KCNRVP8yKeAdoqLVq412apHnvm8"
}

variable "tailscale_tailnet" {
  type = string
  default = "tail15637.ts.net"
}

variable "tailscale_org" {
  type = string
  default = "beenum22.github"
}

variable "use_ipv6" {
  type = bool
  default = true
}
