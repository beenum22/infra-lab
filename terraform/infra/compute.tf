data "oci_identity_availability_domains" "oracle_ads" {
  compartment_id = var.compartment_id
}

data "oci_core_images" "oracle_images" {
  compartment_id           = var.compartment_id
  operating_system         = "Oracle Linux"
  operating_system_version = "9"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

module "k3s_instances" {
  count = var.instances_count
  source = "./modules/oci_instance"
  name = "lab-k3s-${count.index}"
  shape = data.oci_core_images.oracle_images.shape
  subnets = [
//    {
//      id = module.vcn.private_subnet_id
//      public_access = false
//    },
    {
      id = module.vcn.public_subnet_id
      public_access = false
    }
  ]
  ssh_public_keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDXAxRvB9RCU94lxpipzMbYpXlICbLwU4HqEIgU9AvDwIsJ/6uJUGojcg67+fc1isCPlJjLVTD4hicH7hR533uOJbcHwrEQUMpwVN6IkZrRTsUUBwo9xYDxtVGaXFCLCihMWtrgC0esaY8Uy3rF/NEUq/HHFVYSJc7gEjarxkSlOEFiPae7d0HXrSSV1ysAfI9RPa7xok7CB0u1rpe3cOLzHvJlQosmZ/grWKh+Q7s3UXjIbKjU+5I5pI6enjuyxYxegFT77vDIUxRlAR/OTr0jLNAa/X2Fcr2+MoGIi4QvaJMEKtrMOrGnQW2t8DE8Tk8E+p4xvEkjiJe5jDN7bPt51gS60Jv4PEJmwbpJRN1bj0dGW2bPuGJP48lr+xqC6EBryhuGh7YyTPyqP/uEw8JOEbH0WpT8//r1J4oCJ2yRKPJBr5IG7K49fCuP/Aq9oy7sAK4TEULlX/gyuxYaO2XplIncjkw5J29y3Ph5jN3yjyFG0qcftoMw3d/yEKUZzGk= muneebhome@Muneebs-MacBook-Pro.local",
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDQwc7RV/mSCCdZ/YpMujRBtUbNEe0rfng7i2kUkNWmCR9SRy1vZECLLmEMUr5i5ME/8sOrBm5JfsPTJIKaVHzZLjdr3CVCDpGAJBJp6JYLA2bAwy0xQyK+tyVUgnxtkmTJR6TQIQKW9DQy67GBe8wMCkm3tYHtJ4dQy/C9NnonEcsb5ngEMjhbHZD0tDwa+eKtdXhrCJq2KMbz4l9PAIH0EoouK/fWijECcqYxJeHw4nBhdfrnKgn3R1VK5GQFIJ6kkri6P7ibUcX4/fwKaYnmOM2H4YAv47/nHD+FGc8A5yMwT8/FM09QjDj8BtFXJj+SMK5/JqgovYHuiA+GcL2Vv11c0wBp4CjO2YUHjhUVCqDNSUcXf37+XFwtPfqGNOSOEmrYmGXjCnETGGNILMfwVr4aM3PsFh3LpJEI4V4l4IbQT4KfvwgTrdFQX4HGgITJoYUVizaHIZhaNt2QRqUp4/zF0O3B7Do3mIeQzTgNv4VxkXebuSYhEvM6X035Ecs= muneebhome@Muneebs-MacBook-Pro.local"
  ]
  depends_on = [
    module.vcn
  ]
}
