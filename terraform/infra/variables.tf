variable "compartment_id" {
  type = string
  default = "ocid1.tenancy.oc1..aaaaaaaa6pope5hp7f7kxyhpiljh53ww4v2ehsiq4xzjz3u6rpxoqj2bdoua"
}

variable "vcn_cidr" {
  type = string
  default = "10.0.0.0/16"
}

variable "name" {
  type = string
  default = "lab"
}

variable "enable_public_access" {
  type = bool
  default = true
}

# Don't change this as it recreates the Oracle VMs
variable "ssh_public_keys" {
  type = list(string)
  default = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDXAxRvB9RCU94lxpipzMbYpXlICbLwU4HqEIgU9AvDwIsJ/6uJUGojcg67+fc1isCPlJjLVTD4hicH7hR533uOJbcHwrEQUMpwVN6IkZrRTsUUBwo9xYDxtVGaXFCLCihMWtrgC0esaY8Uy3rF/NEUq/HHFVYSJc7gEjarxkSlOEFiPae7d0HXrSSV1ysAfI9RPa7xok7CB0u1rpe3cOLzHvJlQosmZ/grWKh+Q7s3UXjIbKjU+5I5pI6enjuyxYxegFT77vDIUxRlAR/OTr0jLNAa/X2Fcr2+MoGIi4QvaJMEKtrMOrGnQW2t8DE8Tk8E+p4xvEkjiJe5jDN7bPt51gS60Jv4PEJmwbpJRN1bj0dGW2bPuGJP48lr+xqC6EBryhuGh7YyTPyqP/uEw8JOEbH0WpT8//r1J4oCJ2yRKPJBr5IG7K49fCuP/Aq9oy7sAK4TEULlX/gyuxYaO2XplIncjkw5J29y3Ph5jN3yjyFG0qcftoMw3d/yEKUZzGk= muneebhome@Muneebs-MacBook-Pro.local",
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDQwc7RV/mSCCdZ/YpMujRBtUbNEe0rfng7i2kUkNWmCR9SRy1vZECLLmEMUr5i5ME/8sOrBm5JfsPTJIKaVHzZLjdr3CVCDpGAJBJp6JYLA2bAwy0xQyK+tyVUgnxtkmTJR6TQIQKW9DQy67GBe8wMCkm3tYHtJ4dQy/C9NnonEcsb5ngEMjhbHZD0tDwa+eKtdXhrCJq2KMbz4l9PAIH0EoouK/fWijECcqYxJeHw4nBhdfrnKgn3R1VK5GQFIJ6kkri6P7ibUcX4/fwKaYnmOM2H4YAv47/nHD+FGc8A5yMwT8/FM09QjDj8BtFXJj+SMK5/JqgovYHuiA+GcL2Vv11c0wBp4CjO2YUHjhUVCqDNSUcXf37+XFwtPfqGNOSOEmrYmGXjCnETGGNILMfwVr4aM3PsFh3LpJEI4V4l4IbQT4KfvwgTrdFQX4HGgITJoYUVizaHIZhaNt2QRqUp4/zF0O3B7Do3mIeQzTgNv4VxkXebuSYhEvM6X035Ecs= muneebhome@Muneebs-MacBook-Pro.local",
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC9iQnzPq0/lLg359hzQiVSnf33PAzCYaFu8gW1OIaftA2+/fUtJoPCoMBNB4TDTA5ZnHfKEmR9/ktFr4AWOQ/4oCQP2uC12zci9Lpep/aYMmXmgAGs+35sZvf1Ob44CuEw/vvwfViYNt8HAc0BTo1+Sj5gKp8QuBVY70ezS0yw+VEvHnxbXDbXxVRId1w7gANwBAhyRviKjFWSULPJsPY+t0HNoFozERnBDaov3wL7TPIy2WIHr6BE/lOwlzoqRMd8qtAIEbrDTNfZwmY+2AYvhjicLQ6H5jCfHW6UFptlV4UN9UijdVZ+thF4vM8i6huHUx87ljsyOtqwLqrwfh9t muneebahmad@beenum.local"
  ]
}

variable "instances_count" {
  type = number
  default = 2
}

variable "use_ipv6" {
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

variable "tailscale_auth_key" {
  type = string
  default = "muneeb.gandapur@gmail.com"
}

variable "users_setup" {
  type = map(object(
    {
      sudo = bool
      exists = bool
      password = optional(string)
    }
  ))
  default = {}
}

variable "ansible_destroy" {
  type = bool
  default = false
}

variable "ansible_debug" {
  type = bool
  default = false
}

variable "ansible_replay" {
  type = bool
  default = true
}
