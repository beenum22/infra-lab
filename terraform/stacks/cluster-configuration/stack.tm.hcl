stack {
  name        = "cluster-configuration"
  description = "Terramate stack for deployment of foundational Kubernetes resources"
  id          = "2816199f-af4e-4541-8c91-763f7c6d4ea7"
  after = [
    "tag:infra-deployment",
    "tag:cluster-deployment"
  ]
  tags = [
    "k8s",
    "base-apps",
    "cluster-configuration"
  ]
}
