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
}

variable "tailscale_tailnet" {
  type = string
  default = "tail03622.ts.net"
}

variable "tailscale_org" {
  type = string
  default = "muneeb.gandapur@gmail.com"
}

variable "use_ipv6" {
  type = bool
  default = true
}
