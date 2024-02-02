stack {
  name        = "cluster-configuration"
  description = "Terramate stack for deployment of foundational Kubernetes resources"
  id          = "b97be7e9-18c0-45bf-86b3-44ffc5bcf9a8"
  after = [
    "tag:vms:infra-deployment",
    "tag:infra-configuration",
    "tag:cluster-deployment"
  ]
  tags = [
    "k8s",
    "base-apps",
    "cluster-configuration"
  ]
}
