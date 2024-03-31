variable "name" {
  type = string
  default = "lab-k3s"
}

variable "vcn_cidrs" {
  type = list(string)
  default = ["10.0.0.0/16"]
}

variable "compartment_id" {
  type = string
  default = "ocid1.tenancy.oc1..aaaaaaaa6pope5hp7f7kxyhpiljh53ww4v2ehsiq4xzjz3u6rpxoqj2bdoua"
}

variable "enable_ssh" {
  type = bool
  default = true
}

variable "ssh_ports" {
  type = list(number)
  default = [22]
}

variable "enable_ipv4_nat_egress" {
  type = bool
  default = false
}
