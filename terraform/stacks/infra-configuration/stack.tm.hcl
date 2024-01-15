stack {
  name        = "infra-configuration"
  description = "Terramate stack for configuration of managed and unmanaged VMs"
  id          = "1180ca0f-d8e0-4ee6-90d0-c7a88b0b5c4e"
  after = [
    "tag:vms:infra-deployment"
  ]
  tags = [
    "ansible",
    "tailscale",
    "infra",
    "infra-configuration",
  ]
}
