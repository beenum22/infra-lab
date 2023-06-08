terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}

locals {
  base_cmd = [
    var.cluster_role,
    "--node-ip=${join(",", values(var.node_ips))}",
    "--flannel-iface=${var.flannel_interface}",
    "--kubelet-arg=node-ip=::",
    "--token=${var.token}",
    "--disable=traefik"
  ]
  init_cmd = var.cluster_init ? concat(local.base_cmd, ["--cluster-init", "--disable=servicelb"]) : concat(local.base_cmd, ["--server=https://${var.api_host}:6443"])
  final_cmd = var.cluster_role == "server" ? concat(local.init_cmd, ["--cluster-cidr=${var.cluster_cidrs}", "--service-cidr=${var.service_cidrs}"]) : local.init_cmd
}

resource "docker_volume" "volume" {
  name = var.volume_name
}

resource "docker_image" "image" {
  name = "${var.image}:${var.tag}"
  keep_locally = true
}

resource "docker_container" "container" {
  name  = var.name
  image = docker_image.image.image_id
  command = local.final_cmd
  tmpfs = {
    "/run": "",
    "/var/run": ""
  }
  privileged = true
  restart = "always"
  dynamic volumes {
    for_each = var.cluster_role == "server" ? [1] : []
    content {
      container_path = "/var/lib/rancher/k3s"
      volume_name = var.volume_name
    }
  }
  network_mode = "host"
  depends_on = [
    docker_volume.volume
  ]
}

resource "null_resource" "container_post_deploy" {
  triggers = {
    name = var.name
    hostname = var.hostname
    host = var.connection_info.host
    user = var.connection_info.user
    private_key = var.connection_info.private_key
  }
  connection {
    type     = "ssh"
    user     = self.triggers.user
    private_key = self.triggers.private_key
    host     = self.triggers.host
  }
  provisioner "remote-exec" {
    on_failure = continue
    inline = [
      "docker exec -ti ${self.triggers.name} sh -c \"until kubectl get nodes ${self.triggers.hostname}; do echo 'Waiting for node'; sleep 1; done\""
    ]
  }
  depends_on = [
    docker_container.container
  ]
}

resource "null_resource" "container_pre_destroy" {
  count = ! var.cluster_init ? 1 : 0
  triggers = {
    name = var.name
    hostname = var.hostname
    host = var.connection_info.host
    user = var.connection_info.user
    private_key = var.connection_info.private_key
  }
  connection {
    type     = "ssh"
    user     = self.triggers.user
    private_key = self.triggers.private_key
    host     = self.triggers.host
  }
  provisioner "remote-exec" {
    when = destroy
    on_failure = continue
    inline = [
      "docker exec -ti ${self.triggers.name} kubectl --request-timeout 15s drain --ignore-daemonsets --delete-emptydir-data ${self.triggers.hostname}",
      "docker exec -ti ${self.triggers.name} kubectl --request-timeout 15s delete node ${self.triggers.hostname}"
    ]
  }
  depends_on = [
    docker_container.container
  ]
}

resource "null_resource" "copy_kubeconfig" {
  count = var.cluster_init ? 1 : 0
  triggers = {
    name = var.name
    api_host = var.use_ipv6 ? "[${var.node_ips.ipv6}]" : var.node_ips.ipv4
    host = var.connection_info.host
    user = var.connection_info.user
    private_key = var.connection_info.private_key
  }
  connection {
    type     = "ssh"
    user     = self.triggers.user
    private_key = self.triggers.private_key
    host     = self.triggers.host
  }
  provisioner "remote-exec" {
    inline = [
      "docker cp ${self.triggers.name}:/etc/rancher/k3s/k3s.yaml /tmp/config",
      "sed -i 's/127.0.0.1/${self.triggers.api_host}/g' /tmp/config"
    ]
  }
  provisioner "local-exec" {
    command = "scp -i ~/.ssh/id_rsa ${self.triggers.user}@${self.triggers.host}:/tmp/config ~/.kube/config"
  }
  provisioner "remote-exec" {
    inline = [
      "docker cp ${self.triggers.name}:/var/lib/rancher/k3s/server/token /tmp/node-token"
    ]
  }
  provisioner "local-exec" {
    command = "scp -i ~/.ssh/id_rsa  ${self.triggers.user}@${self.triggers.host}:/tmp/node-token ~/.kube/node-token"
  }
  depends_on = [
    docker_container.container,
    null_resource.container_post_deploy
  ]
}

