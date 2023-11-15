terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "3.0.2"
    }
    tailscale = {
      source = "tailscale/tailscale"
      version = "0.13.6"
    }
  }
}

resource "docker_volume" "volume" {
  name = var.volume_name
}

resource "docker_image" "image" {
  name = "${var.image}:${var.tag}"
}

resource "docker_container" "container" {
  name  = var.name
  image = docker_image.image.image_id
  restart = "always"
  capabilities {
    add = [
      "NET_RAW",
      "NET_ADMIN"
    ]
  }
  volumes {
    container_path = "/var/lib/tailscale/state"
    volume_name = var.volume_name
  }
  volumes {
    container_path = "/var/lib"
    host_path = "/var/lib"
  }
  volumes {
    container_path = "/dev/net/tun"
    host_path = "/dev/net/tun"
  }
  volumes {
    container_path = "/var/run"
    host_path = "/var/run/tailscaled"
  }
  network_mode = "host"
  env = [
    "TS_ACCEPT_DNS=true",
    "TS_USERSPACE=false",
    "TS_AUTHKEY=${var.authkey}",
    "TS_SOCKET=/var/run/tailscaled.sock",
    "TS_DEBUG_MTU=1350",
    "TS_STATE_DIR=/var/lib/tailscale/state"
  ]
}

data "tailscale_device" "device" {
  name     = "${var.hostname}.${var.tailnet}"
  wait_for = "60s"
  depends_on = [docker_container.container]
}

resource "tailscale_device_subnet_routes" "routes" {
  device_id = data.tailscale_device.device.id
  routes = var.routes
  depends_on = [
    docker_container.container,
    data.tailscale_device.device
  ]
}

resource "tailscale_device_key" "disable_key_expiry" {
  device_id = data.tailscale_device.device.id
  key_expiry_disabled = true
  depends_on = [
    docker_container.container,
    data.tailscale_device.device
  ]
}
