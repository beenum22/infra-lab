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

variable "tailscale_apikey" {
  type = string
  default = "tskey-api-kr11Wi6CNTRL-gwcSqTHLZNaWmdxHt9kkJaMbevtAZ7ZJ"
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
