terraform {
  required_providers {
    tailscale = {
      source = "tailscale/tailscale"
    }
  }
}

# TODO: --accept-routes=true is not working. Probably because the condition you have set to check the state file is not working.
locals {
  install = {
    oracle = join(";", [
      "curl -fsSL https://tailscale.com/install.sh | sh",
      "if [ -f /etc/debian_version ]; then ${var.use_sudo ? "sudo " : ""}apt-get update && ${var.use_sudo ? "sudo " : ""} apt-get install -y --allow-downgrades tailscale=${var.tailscale_version}; elif [ -f /etc/redhat-release ]; then ${var.use_sudo ? "sudo " : ""}dnf install -y tailscale-${var.tailscale_version}; else echo \"Unsupported operating system\" && exit 1; fi",
      "if [ ! $(cat /etc/default/tailscaled  | grep MTU) ]; then echo 'TS_DEBUG_MTU=${var.tailscale_mtu}' | ${var.use_sudo ? "sudo " : ""}tee -a /etc/default/tailscaled; fi",
      "${var.use_sudo ? "sudo " : ""}systemctl restart tailscaled",
      "if ${var.use_sudo ? "sudo " : ""}test -f '/var/lib/tailscale/tailscaled.state'; then ${var.use_sudo ? "sudo " : ""}tailscale up; else ${var.use_sudo ? "sudo " : ""}tailscale up --auth-key=${var.authkey}; fi"
    ])
  }
  upgrade = {
    oracle = "curl -fsSL https://tailscale.com/install.sh | sh"
  }
  set_config_flags = join(";", concat([
    "${var.use_sudo ? "sudo " : ""}tailscale set --advertise-exit-node=${var.exit_node}",
    "${var.use_sudo ? "sudo " : ""}tailscale set --accept-dns=true",
    "${var.use_sudo ? "sudo " : ""}tailscale set --accept-routes=true",
  ], [
    for flag in var.set_flags : "${var.use_sudo ? "sudo " : ""}tailscale set ${flag}"
  ]))
  uninstall = {
    oracle = join(";", [
      "${var.use_sudo ? "sudo " : ""}tailscale down",
      "if [ -f /etc/debian_version ]; then ${var.use_sudo ? "sudo " : ""} apt-get remove -y tailscale=${var.tailscale_version}; elif [ -f /etc/redhat-release ]; then ${var.use_sudo ? "sudo " : ""}dnf remove -y tailscale-${var.tailscale_version}; else echo \"Unsupported operating system\" && exit 1; fi",
      "${var.use_sudo ? "sudo " : ""} rm -rf /var/lib/tailscale"
    ])
  }
}

resource "null_resource" "install" {
  triggers = {
    host = var.connection_info.host
    user = var.connection_info.user
    port = var.connection_info.port
    private_key = var.connection_info.private_key
    install_script = local.install.oracle
    uninstall_script = local.uninstall.oracle
    mtu = var.tailscale_mtu
    authkey = var.authkey
  }
  connection {
    type     = "ssh"
    user     = self.triggers.user
    private_key = self.triggers.private_key
    host     = self.triggers.host
    port     = self.triggers.port
  }
  provisioner "remote-exec" {
    on_failure = fail
    inline = [
      self.triggers.install_script
    ]
  }
  provisioner "remote-exec" {
    when = destroy
    on_failure = fail
    inline = [
      self.triggers.uninstall_script
    ]
  }
}

resource "null_resource" "config" {
  depends_on = [null_resource.install]
  triggers = {
    host = var.connection_info.host
    user = var.connection_info.user
    port = var.connection_info.port
    private_key = var.connection_info.private_key
    config_flags = local.set_config_flags
  }
  connection {
    type     = "ssh"
    user     = self.triggers.user
    private_key = self.triggers.private_key
    host     = self.triggers.host
    port     = self.triggers.port
  }
  provisioner "remote-exec" {
    on_failure = fail
    inline = [
      self.triggers.config_flags
    ]
  }
}

data "tailscale_device" "device" {
  name     = "${var.hostname}.${var.tailnet}"
  wait_for = "60s"
  depends_on = [null_resource.install]
}

resource "tailscale_device_key" "disable_key_expiry" {
  device_id = data.tailscale_device.device.id
  key_expiry_disabled = true
  depends_on = [
    data.tailscale_device.device
  ]
}

# TODO: Setup ACL here
#resource "tailscale_acl" "this" {
#  acl = jsonencode(
#    {
#      "autoApprovers": {
#        "routes": {
#          "10.42.0.0/16": [
#            "group:admin",
#            "tag:k3s",
#          ],
#          "2001:cafe:42:0::/56": [
#            "group:admin",
#            "tag:k3s",
#          ],
#          "10.43.0.0/16": [
#            "group:admin",
#            "tag:k3s",
#          ],
#          "2001:cafe:42:1::/112": [
#            "group:admin",
#            "tag:k3s",
#          ],
#        },
#        "exitNode": [
#          "group:admin",
#          "tag:k3s",
#        ],
#      },
#      "groups": {
#        "group:admin": [
#          "muneeb.gandapur@gmail.com",
#        ],
#        "group:k3s-users": [
#          "msagheer92@gmail.com",
#          "mahrukhanwari1@gmail.com",
#          // "muneeb.gandapur@gmail.com",
#        ],
#        "group:exit-node-users": [
#          "mahrukhanwari1@gmail.com",
#          // "msagheer92@gmail.com",
#          // "muneeb.gandapur@gmail.com",
#        ],
#      },
#      "tagOwners": {
#        "tag:k3s":          ["group:admin"],
#        "tag:k8s-operator": [],
#        "tag:k8s":          ["group:admin", "tag:k8s-operator"],
#        "tag:admin":        ["group:admin"],
#      },
#
#      // Declare convenient hostname aliases to use in place of IP addresses.
#      "hosts": {
#        "k3s-cluster-ipv4": "10.42.0.0/16",
#        "k3s-cluster-ipv6": "2001:cafe:42:0::/56",
#        "k3s-service-ipv4": "10.43.0.0/16",
#        "k3s-service-ipv6": "2001:cafe:42:1::/112",
#        "wormhole-ipv4":    "10.43.217.93",
#        "wormhole-ipv6":    "2001:cafe:42:1::e33d",
#        "dns-ipv4":         "10.43.249.210",
#        "dns-ipv6":         "2001:cafe:42:1::f1b6",
#        "google":           "8.8.8.8",
#        "google-ipv6":      "2001:4860:4860::8888",
#        "tailscale-dns":    "100.100.100.100",
#      },
#      // Define access control lists for users, groups, autogroups, tags,
#      // Tailscale IP addresses, and subnet ranges.
#      "acls": [
#        // Match absolutely everything.
#        // Comment this section out if you want to define specific restrictions.
#        // {"action": "accept", "src": ["*"], "dst": ["*:*"]},
#        // Allow resources in K3s subnets to communicate with each other
#        {
#          "action": "accept",
#          "src": [
#            "k3s-cluster-ipv4",
#            "k3s-cluster-ipv6",
#            "k3s-service-ipv4",
#            "k3s-service-ipv6",
#          ],
#          "dst": [
#            "k3s-cluster-ipv4:*",
#            "k3s-cluster-ipv6:*",
#            "k3s-service-ipv4:*",
#            "k3s-service-ipv6:*",
#          ],
#        },
#        // Allow all k3s tagged devices to communicate with each other and cluster subnets
#        {
#          "action": "accept",
#          "src": [
#            "tag:k3s",
#          ],
#          "dst": [
#            "tag:k3s:*",
#            "k3s-cluster-ipv4:*",
#            "k3s-cluster-ipv6:*",
#            "k3s-service-ipv4:*",
#            "k3s-service-ipv6:*",
#          ],
#        },
#        // Allow admind devices to access everything
#        {
#          "action": "accept",
#          "src": [
#            "group:admin",
#          ],
#          "dst": [
#            // "*:*",
#            "autogroup:internet:*",
#            "tag:k3s:*",
#            "tag:k8s:*",
#            "tag:k8s-operator:*",
#            "k3s-cluster-ipv4:*",
#            "k3s-cluster-ipv6:*",
#            "k3s-service-ipv4:*",
#            "k3s-service-ipv6:*",
#            // "tailscale-dns:53",
#          ],
#        },
#        // Allow user group to access DNS server and hosted HTTPS services
#        {
#          "action": "accept",
#          "src":    ["group:k3s-users"],
#          "dst": [
#            "wormhole-ipv4:443",
#            "wormhole-ipv6:443",
#            "dns-ipv4:53",
#            "dns-ipv6:53",
#            "tag:k8s:443",
#          ],
#        },
#        // Allow access to Internet through exit nodes
#        {
#          "action": "accept",
#          "src":    ["group:exit-node-users"],
#          "dst":    ["autogroup:internet:*"],
#        },
#      ],
#
#      // Define users and devices that can use Tailscale SSH.
#      "ssh": [
#        // Allow all users to SSH into their own devices in check mode.
#        // Comment this section out if you want to define specific restrictions.
#        {
#          "action": "check",
#          "src":    ["autogroup:member"],
#          "dst":    ["autogroup:self"],
#          "users":  ["autogroup:nonroot", "root"],
#        },
#        // {
#        // 	"action": "check",
#        // 	"src":    ["group:admin"],
#        // 	"dst":    ["tag:k3s"],
#        // 	"users":  ["autogroup:nonroot", "root"],
#        // },
#      ],
#
#      // Test access rules every time they're saved.
#      "tests": []
#    }
#  )
#}
