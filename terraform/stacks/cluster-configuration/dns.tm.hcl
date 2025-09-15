generate_hcl "_dns.tf" {
  content {
    resource "kubernetes_namespace" "dns" {
      metadata {
        name = "dns"
      }
    }

    data "kubernetes_service" "cluster_dns" {
      metadata {
        name = "kube-dns"
        namespace = "kube-system"
      }
    }

    module "blocky" {
      source = "${terramate.root.path.fs.absolute}/terraform/modules/apps/blocky"
      namespace = kubernetes_namespace.dns.metadata.0.name
      domains = [
        "blocky.cluster.moinmoin.fyi"
      ]
      ingress_class = global.project.ingress_class
      ingress_hostname = global.project.ingress_hostname
      issuer = module.cert_manager.issuer
      expose_on_tailnet = true
      tailnet_hostname = "talos-blocky"
      conditional_mappings = {
        "cluster.local" = data.kubernetes_service.cluster_dns.spec.0.cluster_ip
      }
      custom_dns_rewrites = {}
      custom_dns_mappings = {
#         "wormhole.tail03622.ts.net" = join(",", data.tailscale_device.nginx.0.addresses)
      }
      depends_on = [
        kubernetes_namespace.dns
      ]
    }

    data "tailscale_device" "blocky_node" {
      # name         = module.blocky.endpoint
      hostname     = module.blocky.tailscale_hostname
      wait_for = "60s"
      depends_on = [
        module.blocky
      ]
    }

    resource "tailscale_dns_nameservers" "this" {
      # nameservers = module.blocky.endpoints
      nameservers = data.tailscale_device.blocky_node.addresses
    }
  }
}