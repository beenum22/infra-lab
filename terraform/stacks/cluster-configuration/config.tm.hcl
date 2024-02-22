globals "terraform" {
  providers = [
    "helm",
    "kubernetes",
    "b2",
    "tailscale",
    "local"
  ]

  remote_states = {
    stacks = [
      "cluster-deployment"
    ]
  }
}

generate_hcl "_network.tf" {
  content {
    resource "kubernetes_namespace" "network" {
      metadata {
        name = "network"
      }
    }

    module "nginx" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/nginx"
      namespace = kubernetes_namespace.network.metadata.0.name
      domain = "wormhole.${global.project.zone}"
      expose_on_tailnet = false
      depends_on = [kubernetes_namespace.network]
    }

    resource "tailscale_tailnet_key" "auth_key" {
      reusable      = true
      ephemeral     = true
      preauthorized = true
      expiry        = 3600
      description   = "K3s Tailscale Apps"
    }

    module "tailscale_router" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/tailscale-router"
      namespace = kubernetes_namespace.network.metadata.0.name
      tag = "v1.56.1"
      replicas = 1
      authkey = tailscale_tailnet_key.auth_key.key
      routes = [
        "10.43.0.0/16",
        "2001:cafe:42:1::/112"
      ]
      mtu = "1280"
      userspace_mode = true
      extra_args = []
      depends_on = [kubernetes_namespace.network]
    }

#    module "tailscale_vpn" {
#      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/tailscale-vpn"
#      namespace = kubernetes_namespace.network.metadata.0.name
#      replicas = 1
#      tag = "v1.56.1"
#      authkey = tailscale_tailnet_key.auth_key.key
#      mtu = "1280"  # Consider 1350 in case of MTU issues with IPv6
#      userspace_mode = true
#      routes = []
#      depends_on = [kubernetes_namespace.network]
#    }

#    module "tailscale_operator" {
#      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/tailscale-operator"
#      namespace = kubernetes_namespace.network.metadata.0.name
#      client_id = var.tailscale_operator_client_id
#      client_secret = var.tailscale_operator_client_secret
#      depends_on = [kubernetes_namespace.network]
#    }
  }
}

generate_hcl "_storage.tf" {
  content {
    resource "kubernetes_namespace" "storage" {
      metadata {
        name = "storage"
      }
    }

    module "openebs" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/openebs"
      namespace = kubernetes_namespace.storage.metadata[0].name
      depends_on = [
        kubernetes_namespace.storage
      ]
    }

    resource "kubernetes_manifest" "zfs_snapshot" {
      manifest = {
        apiVersion = "snapshot.storage.k8s.io/v1"
        kind       = "VolumeSnapshotClass"
        metadata = {
          name      = "openebs-zfs"
          labels = {
            "velero.io/csi-volumesnapshot-class" = "true"
          }
          annotations = {
            "snapshot.storage.kubernetes.io/is-default-class" = "true"
          }
        }
        driver = "zfs.csi.openebs.io"
        deletionPolicy = "Delete"
      }
      depends_on = [
        module.openebs
      ]
    }
  }
}

generate_hcl "_security.tf" {
  content {
    resource "kubernetes_namespace" "security" {
      metadata {
        name = "security"
      }
    }

    module "cert_manager" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/cert-manager"
      namespace = kubernetes_namespace.security.metadata.0.name
      domain_email = global.project.domain_email
      group_name = "acme.${global.project.domain}"
      ovh_app_key = global.infrastructure.ovh.application_key
      ovh_app_secret = global.infrastructure.ovh.application_secret
      ovh_consumer_key = global.infrastructure.ovh.consumer_key
      ingress_class = global.project.ingress_class
      depends_on = [kubernetes_namespace.security]
    }
  }
}

generate_hcl "_backup.tf" {
  content {
    resource "kubernetes_namespace" "backup" {
      metadata {
        name = "backup"
      }
    }

    module "velero" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/velero"
      namespace = kubernetes_namespace.backup.metadata[0].name
      backup_storage_provider = "aws"
      volume_snapshot_provider = "openebs.io/zfspv-blockstore"
      backup_storage_bucket = "k3s-backup"
      volume_snapshot_bucket = "k3s-snapshots"
      access_key_id = global.secrets.b2.key_id
      secret_access_key = global.secrets.b2.application_key
      depends_on = [
        kubernetes_namespace.backup
      ]
    }

    import {
      id = "cdffc0d87ceecfa880c10e17"
      to = module.velero.b2_bucket.backup_storage
    }

    import {
      id = "8d9ff0688c1ecfa880c10e17"
      to = module.velero.b2_bucket.volume_snapshots
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
      nodes = [for node in data.kubernetes_nodes.this.nodes : node.metadata.0.name]
      owners = distinct([for node in data.kubernetes_nodes.this.nodes : node.metadata.0.labels["dera.ovh/owner"] if can(node.metadata.0.labels["dera.ovh/owner"])])
      owner_namespaces = {
        for owner in local.owners : owner => {
          namespace = owner
          nodes = [
            for node in data.kubernetes_nodes.this.nodes : node.metadata.0.name if node.metadata.0.labels["dera.ovh/owner"] == owner
          ]
          cpus = sum([
            for node in data.kubernetes_nodes.this.nodes : tonumber(node.status.0.capacity.cpu) if node.metadata.0.labels["dera.ovh/owner"] == owner
          ])
          memory = "${sum([
            for node in data.kubernetes_nodes.this.nodes : tonumber(regex("\\d+", node.status.0.capacity.memory)) * local.convert_to_ki_factor[regex("[A-Za-z]+", node.status.0.capacity.memory)] if node.metadata.0.labels["dera.ovh/owner"] == owner
          ])}Ki"
          storage = "${sum([
            for node in data.kubernetes_nodes.this.nodes : tonumber(regex("\\d+", node.status.0.capacity.ephemeral-storage)) * local.convert_to_ki_factor[regex("[A-Za-z]+", node.status.0.capacity.ephemeral-storage)] if node.metadata.0.labels["dera.ovh/owner"] == owner
          ])}Ki"
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

generate_hcl "_k3s_users.tf" {
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
          clusters    = yamldecode(data.terraform_remote_state.cluster_deployment_stack_state.outputs.kubeconfig)["clusters"]
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
