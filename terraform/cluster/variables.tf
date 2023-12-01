variable "use_tailscale_ip" {
  type = bool
  default = true
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

# loafoe SSH provider crashes for IPv6
variable "ip_type" {
  type = string
  default = "ipv4"
}
