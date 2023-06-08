variable "name" {
  type = string
  default = "lab-k3s"
}

variable "compartment_id" {
  type = string
  default = "ocid1.tenancy.oc1..aaaaaaaa6pope5hp7f7kxyhpiljh53ww4v2ehsiq4xzjz3u6rpxoqj2bdoua"
}

variable "operating_system" {
  type = string
  default = "Oracle Linux"
}

variable "operating_system_version" {
  type = string
  default = "9"
}

variable "shape_name" {
  type = string
  default = "VM.Standard.A1.Flex"
}

variable "image_ocid" {
  type = string
  default = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaujyukkfkoanatqanh2qe4bxhwwg2j44fjn2folihrfvsxd5jv5bq"
}

variable "vcpus" {
  type = number
  default = 1
}

variable "memory" {
  type = number
  default = 6
}

variable "boot_volume" {
  type = number
  default = 47
}

variable "cloud_init_commands" {
  type = list(string)
  default = [
    "echo 'This instance was provisioned by Terraform.' >> /etc/motd",
//    "echo 'Downloading OCI secondary interface configuration script'",
//    "wget -O /tmp/secondary_vnic_all_configure.sh https://docs.oracle.com/en-us/iaas/Content/Resources/Assets/secondary_vnic_all_configure.sh",
//    "chmod +x /tmp/secondary_vnic_all_configure.sh",
//    "until [ $(basename -a /sys/class/net/* | wc -l) -gt 2 ]; do echo 'Waiting for secondary VNIC'; sleep 1; done",
//    "echo 'Seconday VNIC is successfully added. Waiting 5 seconds before VNIC configuration.'",
//    "sleep 5",
//    "until sudo /tmp/secondary_vnic_all_configure.sh -c; do echo 'Waiting for secondary VNIC configuration'; done",
//    "Secondary VNIC is successfully configured",
//    "echo 'sh /tmp/secondary_vnic_all_configure.sh -c' >> /etc/rc.d/rc.local",
//    "sudo chmod -v +x /etc/rc.local",
//    "VNIC configuration script successfully added to rc.local",
    "sleep 10",
    "echo 'Installing and configuring Docker'",
    "dnf install -y dnf-utils zip unzip",
    "dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo",
    "dnf remove -y runc",
    "dnf install -y docker-ce --nobest",
    "systemctl enable docker.service",
    "systemctl start docker.service",
    "systemctl status docker.service",
    "usermod -aG docker opc",
    "echo 'Allowing ports for K3s'",
    "firewall-cmd --permanent --add-port=22/tcp",
    "firewall-cmd --permanent --add-port=80/tcp",
    "firewall-cmd --permanent --add-port=443/tcp",
    "firewall-cmd --permanent --add-port=2376/tcp",
    "firewall-cmd --permanent --add-port=2379/tcp",
    "firewall-cmd --permanent --add-port=2380/tcp",
    "firewall-cmd --permanent --add-port=6443/tcp",
    "firewall-cmd --permanent --add-port=8472/udp",
    "firewall-cmd --permanent --add-port=9099/tcp",
    "firewall-cmd --permanent --add-port=10250/tcp",
    "firewall-cmd --permanent --add-port=10254/tcp",
    "firewall-cmd --permanent --add-port=30000-32767/tcp",
    "firewall-cmd --permanent --add-port=30000-32767/udp",
    "firewall-cmd --permanent --zone=trusted --add-source=10.42.0.0/16",
    "firewall-cmd --permanent --zone=trusted --add-source=2001:cafe:42:0::/56",
    "firewall-cmd --permanent --zone=trusted --add-source=10.43.0.0/16",
    "firewall-cmd --permanent --zone=trusted --add-source=2001:cafe:42:1::/112",
    "firewall-cmd --reload"
  ]
}

variable "subnets" {
  type = list(object({
    id = string
    public_access = bool
  }))
}

variable "ssh_public_keys" {
  type    = list(string)
}

variable "cloud_agent_plugins" {
  description = "Whether each Oracle Cloud Agent plugins should be ENABLED or DISABLED."
  type        = map(bool)
  default = {
    autonomous_linux        = true
    bastion                 = true
    block_volume_mgmt       = false
    custom_logs             = true
    management              = false
    monitoring              = true
    osms                    = true
    run_command             = true
    vulnerability_scanning  = true
    java_management_service = false
  }
  #* need to craft a validation condition at some point
}

variable "enable_public_access" {
  type = bool
  default = true
}

//
//variable "vcn_cidr" {
//  type = string
//  default = "10.0.0.0/16"
//}
//
//variable "name" {
//  type = string
//  default = "lab"
//}
//

//
//variable "ssh_public_keys" {
//  type    = string
//  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDXAxRvB9RCU94lxpipzMbYpXlICbLwU4HqEIgU9AvDwIsJ/6uJUGojcg67+fc1isCPlJjLVTD4hicH7hR533uOJbcHwrEQUMpwVN6IkZrRTsUUBwo9xYDxtVGaXFCLCihMWtrgC0esaY8Uy3rF/NEUq/HHFVYSJc7gEjarxkSlOEFiPae7d0HXrSSV1ysAfI9RPa7xok7CB0u1rpe3cOLzHvJlQosmZ/grWKh+Q7s3UXjIbKjU+5I5pI6enjuyxYxegFT77vDIUxRlAR/OTr0jLNAa/X2Fcr2+MoGIi4QvaJMEKtrMOrGnQW2t8DE8Tk8E+p4xvEkjiJe5jDN7bPt51gS60Jv4PEJmwbpJRN1bj0dGW2bPuGJP48lr+xqC6EBryhuGh7YyTPyqP/uEw8JOEbH0WpT8//r1J4oCJ2yRKPJBr5IG7K49fCuP/Aq9oy7sAK4TEULlX/gyuxYaO2XplIncjkw5J29y3Ph5jN3yjyFG0qcftoMw3d/yEKUZzGk= muneebhome@Muneebs-MacBook-Pro.local"
//}
//
//variable "instances_count" {
//  type = number
//  default = 2
//}
