stack {
  name        = "setup-cluster"
  description = "Terramate stack for deployment of Kubernetes Cluster"
  id          = "f174978e-09bd-4d69-95ac-93d279eba710"
  after = [
    "tag:vms:infra-deployment",
    "tag:infra-configuration"
  ]
  tags = [
    "k8s",
    "k3s",
    "cluster",
    "setup-cluster",
  ]
}
