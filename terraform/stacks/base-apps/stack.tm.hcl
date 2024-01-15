stack {
  name        = "base-apps"
  description = "Terramate stack for deployment of foundational Kubernetes apps"
  id          = "b97be7e9-18c0-45bf-86b3-44ffc5bcf9a8"
  after = [
    "tag:vms:infra-deployment",
    "tag:infra-configuration",
    "tag:setup-cluster"
  ]
  tags = [
    "k8s",
    "base-apps",
  ]
}
