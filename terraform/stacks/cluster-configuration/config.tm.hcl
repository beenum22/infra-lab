globals "terraform" {
  providers = [
    "helm",
    "kubernetes",
    "b2",
    "tailscale",
    "local",
    "cloudflare"
  ]

  remote_states = {
    stacks = [
      "cluster-deployment"
    ]
  }
}

generate_hcl "_locals.tf" {
  content {
    locals {
      nodes = [for node in data.kubernetes_nodes.this.nodes : node.metadata.0.name]
      apps = global.cluster.apps
    }
  }
}

generate_hcl "_node_labels.tf" {
  content {
    resource "kubernetes_labels" "nodes" {
      for_each = toset(local.nodes)
      api_version = "v1"
      kind        = "Node"
      metadata {
        name = each.key
      }
      labels = global.infrastructure.talos_instances[each.key].talos_config.node_labels
    }
  }
}

generate_hcl "_cluster_info.tf" {
  content {
    data "kubernetes_nodes" "this" {}

    locals {
      convert_to_ki_factor = {
        "Ki" = 1,
        "Mi" = 1024,
        "Gi" = 1024 * 1024
      }
      owners = distinct([for node in data.kubernetes_nodes.this.nodes : node.metadata.0.labels["moinmoin.fyi/owner"] if can(node.metadata.0.labels["moinmoin.fyi/owner"])])
      owner_namespaces = {
        for owner in local.owners : owner => {
          namespace = owner
          nodes = [
            for node in data.kubernetes_nodes.this.nodes : node.metadata.0.name if can(node.metadata.0.labels["moinmoin.fyi/owner"]) == owner
          ]
          cpus = try(sum([
            for node in data.kubernetes_nodes.this.nodes : tonumber(node.status.0.capacity.cpu) if can(node.metadata.0.labels["moinmoin.fyi/owner"]) == owner
          ]), 0)
          memory = "${try(sum([
            for node in data.kubernetes_nodes.this.nodes : tonumber(regex("\\d+", node.status.0.capacity.memory)) * local.convert_to_ki_factor[regex("[A-Za-z]+", node.status.0.capacity.memory)] if can(node.metadata.0.labels["moinmoin.fyi/owner"]) == owner
          ]), 0)}Ki"
          storage = "${try(sum([
            for node in data.kubernetes_nodes.this.nodes : tonumber(regex("\\d+", node.status.0.capacity.ephemeral-storage)) * local.convert_to_ki_factor[regex("[A-Za-z]+", node.status.0.capacity.ephemeral-storage)] if can(node.metadata.0.labels["moinmoin.fyi/owner"]) == owner
          ]), 0)}Ki"
        }
      }
    }

    output "nodes" {
      value = {
        owner_namespaces = local.owner_namespaces
      }
    }
  }
}

generate_hcl "_users.tf" {
  content {
    resource "kubernetes_namespace" "users" {
      for_each = local.owner_namespaces
      metadata {
        name = each.value.namespace
        labels = {
          "pod-security.kubernetes.io/enforce" = "baseline"
          "pod-security.kubernetes.io/enforce-version" = "latest"
          "pod-security.kubernetes.io/warn" = "restricted"
          "pod-security.kubernetes.io/warn-version" = "latest"
          "pod-security.kubernetes.io/audit" = "restricted"
          "pod-security.kubernetes.io/audit-version" = "latest"
        }
      }
    }

    resource "kubernetes_service_account" "users" {
      for_each = local.owner_namespaces
      metadata {
        name      = "${each.key}-sa"
        namespace = kubernetes_namespace.users[each.key].metadata.0.name
      }
    }

    resource "kubernetes_cluster_role" "cluster_viewer" {
      for_each = local.owner_namespaces
      metadata {
        name = "${each.key}-cluster-viewer"
      }
      rule {
        api_groups = [""]
        resources  = ["nodes"]
        verbs      = ["list"]
      }
      rule {
        api_groups = [""]
        resources  = ["nodes"]
        verbs      = ["get", "watch", "list"]
        resource_names = each.value.nodes
      }
      rule {
        api_groups = ["storage.k8s.io"]
        resources  = ["storageclasses"]
        verbs      = ["list"]
#        resource_names = global.cluster.users[each.key].storage_classes
      }
    }

    resource "kubernetes_cluster_role_binding" "cluster_viewer" {
      for_each = local.owner_namespaces
      metadata {
        name      = "${each.key}-cluster-viewer"
      }
      subject {
        kind      = "ServiceAccount"
        name      = kubernetes_service_account.users[each.key].metadata.0.name
        namespace = kubernetes_service_account.users[each.key].metadata.0.namespace
      }
      role_ref {
        kind     = "ClusterRole"
        name     = kubernetes_cluster_role.cluster_viewer[each.key].metadata.0.name
        api_group = "rbac.authorization.k8s.io"
      }
    }

    resource "kubernetes_role_binding" "namespace_admin" {
      for_each = local.owner_namespaces
      metadata {
        name      = "${each.key}-ns-admin"
        namespace = kubernetes_namespace.users[each.key].metadata.0.name
      }
      subject {
        kind      = "ServiceAccount"
        name      = kubernetes_service_account.users[each.key].metadata.0.name
        namespace = kubernetes_service_account.users[each.key].metadata.0.namespace
      }
      role_ref {
        kind     = "ClusterRole"
        name     = "admin"
        api_group = "rbac.authorization.k8s.io"
      }
    }

    resource "kubernetes_secret" "users" {
      for_each = local.owner_namespaces
      metadata {
        name = "${each.key}-sa"
        namespace = kubernetes_namespace.users[each.key].metadata.0.name
        annotations = {
          "kubernetes.io/service-account.name" = kubernetes_service_account.users[each.key].metadata.0.name
        }
      }
      type = "kubernetes.io/service-account-token"
    }

    resource "kubernetes_resource_quota" "users" {
      for_each = local.owner_namespaces
      metadata {
        name = "${each.key}-ns-quota"
        namespace = kubernetes_namespace.users[each.key].metadata.0.name
      }
      spec {
        hard = {
          "limits.cpu" = each.value.cpus
          "limits.memory" = each.value.memory
          "requests.storage" = each.value.storage
        }
      }
    }

    locals {
      user_kubeconfig = {
        for user, info in local.owner_namespaces: user => yamlencode({
          apiVersion  = "v1"
          kind        = "Config"
          clusters    = yamldecode(data.terraform_remote_state.cluster_deployment_stack_state.outputs.talos_kubeconfig)["clusters"]
          current-context = user
          contexts    = [{
            name = user
            context = {
              cluster = "default"
              user = user
              namespace = info.namespace
            }
          }]
          preferences = {}
          users = [{
            name = user
            user = {
              token = kubernetes_secret.users[user].data.token
            }
          }]
        })
      }
    }

    resource "local_file" "users" {
      for_each = local.owner_namespaces
      content  = local.user_kubeconfig[each.key]
      filename = "${pathexpand("~")}/.kube/${each.key}config"
      file_permission = "0700"
    }
  }
}
