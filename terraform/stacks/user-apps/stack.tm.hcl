stack {
  name        = "user-apps"
  description = "Terramate stack for deployment of user Kubernetes apps"
  id          = "4533d353-e1cd-4bed-977b-5f45d6e55d26"
  after = [
    "tag:vms:infra-deployment",
    "tag:infra-configuration",
    "tag:setup-cluster",
    "tag:base-apps"
  ]
  tags = [
    "k8s",
    "apps",
    "user-apps"
  ]
}
