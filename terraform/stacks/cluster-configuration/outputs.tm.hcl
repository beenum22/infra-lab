generate_hcl "_outputs.tf" {
  content {
    output "dns_servers" {
      value = data.tailscale_device.blocky_node.addresses
    }

    output "monitoring_dashboards" {
      value = flatten([
        for node in [for node in data.kubernetes_nodes.this.nodes : node.metadata.0.name] : "https://${node}.${global.cluster.apps.dashdot.hostnames[0]}" if global.cluster.apps.dashdot.enable == true
      ])
    }

    output "ingress_endpoints" {
        value = {
            private = module.nginx.endpoint
            public  = module.cloudflared.tunnel_hostname
        }
    }
  }
}