import logging
import json
import yaml
from yaml.loader import SafeLoader
from typing import Tuple, Any

import requests
# from kubernetes import client, config

from helpers import Utilities, Docker, OutputInfo

logger = logging.getLogger(__name__)
logging.getLogger("paramiko").setLevel(logging.ERROR)
logging.getLogger("git").setLevel(logging.ERROR)
logging.getLogger("urllib3").setLevel(logging.ERROR)


class Tailscale(object):

    CONTAINER_NAME = "tailscaled"
    CONTAINER_IMAGE = "tailscale/tailscale"
    CONTAINER_SOCKET = "/var/run/tailscaled.sock"
    API_URL = "https://api.tailscale.com/api/v2"

    def __init__(self, org, username: str, host: str, authkey: str, apikey) -> None:
        self.org = org
        self.username = username
        self.host = host
        self.authkey = authkey
        self.apikey = apikey
        self.docker = None

    def _setup_docker_client(self) -> None:
        self.docker = Docker(host=self.host, user=self.username)

    def fetch_status(self) -> dict:
        return json.loads(self.docker.client.containers.get(self.CONTAINER_NAME).exec_run(f"tailscale --socket {self.CONTAINER_SOCKET} status --self --json").output)

    def log_status(self) -> None:
        status = self.fetch_status()
        logger.debug(f"Tailscale v{status['Version']} is configured with '{status['Self']['DNSName']}' domain and {status['Self']['TailscaleIPs']} IPs")
        logger.debug(f"Detailed Tailscale Info: {status}")
        assert status['Self']['Online'], f"Tailscale connection is DOWN"
        if status['Self']['Online']:
            logger.info(f"Tailscale v'{status['Version']}' is UP")
        else:
            logger.error(f"Tailscale v'{status['Version']}' is DOWN")

    def _verify_api_status(self) -> bool:
        status, response = Utilities.request_api(self.API_URL, f"/tailnet/{self.org}/devices", self.apikey)
        if status == 200:
            logger.debug("Tailscale API is accessible.")
            return True
        logger.debug(f"Tailscale API is not accessible. Received '{status}' status code.")
        return False

    def print_status(self) -> None:
        assert self.org, "Tailscale org. name or tailnet is not set! It is required to fetch the network status."
        assert self._verify_api_status(), "Failed to connected to the Tailscale API"
        devices_json = Utilities.request_api(
            self.API_URL,
            f"tailnet/{self.org}/devices?fields=all",
            self.apikey
        )[1]
        devices = []
        for device in devices_json["devices"]:
            devices.append({
                "Name": device["hostname"],
                "Node ID": device["nodeId"],
                "Domain Name": device["name"],
                "Addresses": "\n".join(device["addresses"]),
                "OS Type": device["os"],
                "Authorized": str(device["authorized"]),
                # "Status": "True" if len(device["clientConnectivity"]["endpoints"]) > 0 else "False",
            })
        o = OutputInfo()
        o.output_details_table("Tailscale Mesh VPN Devices", devices)

    def connect(self) -> None:
        try:
            if not self.docker:
                self._setup_docker_client()
            if not self.docker.container_exists(self.CONTAINER_NAME):
                logger.info("Establishing Tailscale Mesh VPN connection")
                self.docker.client.containers.run(
                    image=self.CONTAINER_IMAGE,
                    detach=True,
                    restart_policy={
                        "Name": "always"
                    },
                    name=self.CONTAINER_NAME,
                    volumes=[
                        "/var/lib:/var/lib",
                        "/dev/net/tun:/dev/net/tun",
                        "/var/run/tailscaled:/var/run"
                    ],
                    cap_add=[
                        "NET_RAW",
                        "NET_ADMIN"
                    ],
                    network_mode="host",
                    environment={
                        "TS_ACCEPT_DNS": "true",
                        "TS_USERSPACE": "false",
                        "TS_AUTHKEY": self.authkey,
                        "TS_SOCKET": "/var/run/tailscaled.sock",
                        "TS_DEBUG_MTU": "1350"  # Change default 1280 because we have overlay over overlay :D. VxLAN over Tailscale.
                        # "TS_ROUTES": "172.31.0.0/16",
                        # "TS_EXTRA_ARGS": "--accept-routes"
                    }
                )
            else:
                logger.info(
                    "Tailscale Mesh VPN connection node already exists. Skipping the Tailscale Mesh VPN connection."
                )
                self.docker.start_container(self.CONTAINER_NAME)

            self.log_status()
        except Exception as err:
            logger.debug(err)
            raise Exception(f"Node disconnection from Tailscale Mesh VPN failed!")

    def disconnect(self) -> None:
        try:
            if not self.docker:
                self._setup_docker_client()
            if self.docker.container_exists(self.CONTAINER_NAME):
                logger.info("Disconnecting Node from Tailscale Mesh VPN")
                node_id = json.loads(self.docker.exec_command(
                    self.CONTAINER_NAME,
                    f"tailscale --socket {self.CONTAINER_SOCKET} status --self --json"
                ).output)["Self"]["ID"]
                logger.debug(f"Tailscale Node ID: {node_id}")
                logger.debug("Removing Tailscale container")
                self.docker.delete_container(self.CONTAINER_NAME)
                logger.debug(f"Removing Node [{node_id}] from the Tailscale console")
                Utilities.request_api(
                    self.API_URL,
                    f"device/{node_id}",
                    self.apikey,
                    method="DELETE"
                )
                logger.debug(f"Node [{node_id}] successfully removed from the Tailscale console")
                logger.info("Node is successfully disconnected from Tailscale Mesh VPN")
            else:
                logger.debug(
                    "Tailscale resources doesn't exist exist on the node. Skipping the node "
                    "disconnection from Tailscale Mesh VPN."
                )
        except Exception as err:
            logger.debug(err)
            raise Exception(f"Node disconnection from Tailscale Mesh VPN failed!")


class K3s(object):

    CONTAINER_NAME = "k3s"
    CONTAINER_IMAGE = "rancher/k3s"
    CONTAINER_VOLUME = "k3s-volume"

    def __init__(self, username: str, host: str, host_interface: str = "tailscale0") -> None:
        self.username = username
        self.host = host
        self.host_interface = host_interface
        self.docker = None

    def _setup_docker_client(self) -> None:
        self.docker = Docker(host=self.host, user=self.username)

    def get_kubeconfig(self, output_path: str = "/tmp/k3s.yaml", ipv6=True) -> None:
        try:
            if not self.docker:
                self._setup_docker_client()
            assert self.docker.container_exists(self.CONTAINER_NAME), f"No K3s cluster node is running"
            logger.info("Fetching kubeconfig from the K3s cluster node")
            config = yaml.load(self.docker.exec_command(self.CONTAINER_NAME, 'cat /etc/rancher/k3s/k3s.yaml').output, Loader=SafeLoader)
            for ip in self.docker.fetch_host_interface_ips(self.host_interface):
                if ipv6 and Utilities.is_ipv6(ip):
                    config["clusters"][0]["cluster"]["server"] = f"https://[{ip}]:6443"
                elif not ipv6 and not Utilities.is_ipv6(ip):
                    config["clusters"][0]["cluster"]["server"] = f"https://{ip}:6443"
            with open(output_path, 'w') as file:
                yaml.dump(config, file)
        except (Exception, AssertionError) as err:
            logger.debug(err)
            raise Exception(f"K3s cluster kubeconfig fetch failed!")

    def _k3s_node(self, role: str, token: str, init: bool = False, api_host: str = None, cluster_cidrs: str = None, service_cidrs: str = None) -> None:
        node_interface_ips = self.docker.fetch_host_interface_ips(self.host_interface)
        cmd = [
            role,
            f"--node-ip={','.join(node_interface_ips)}",
            f"--flannel-iface={self.host_interface}",
            "--kubelet-arg=node-ip=::",
            f"--token={token}"
        ]
        mounted_volumes = []

        if init:
            cmd.append("--cluster-init")
            cmd.append("--disable=servicelb")
            cmd.append(f"--cluster-cidr={cluster_cidrs}")
            cmd.append(f"--cluster-cidr={service_cidrs}")
        else:
            cmd.append(f"--server=https://{api_host}:6443")
        if role == "server":
            mounted_volumes.append("k3s-volume:/var/lib/rancher/k3s")
        self.docker.client.containers.run(
            name=self.CONTAINER_NAME,
            image=self.CONTAINER_IMAGE,
            command=cmd,
            tmpfs={
                "/run": "",
                "/var/run": ""
            },
            privileged=True,
            restart_policy={
                "Name": "always"
            },
            # environment={
            #     # "K3S_TOKEN": f"{token}",
            #     # "K3S_KUBECONFIG_MODE": 664,
            # },
            volumes=mounted_volumes,
            detach=True,
            network_mode="host",
        )

    def create(self, cluster_cidrs: str, service_cidrs: str) -> None:
        try:
            if not self.docker:
                self._setup_docker_client()
            if not self.docker.container_exists(self.CONTAINER_NAME):
                logger.info("Initializing new K3s cluster")
                logger.debug(f"Creating a container volume '{self.CONTAINER_VOLUME}' locally")
                node_interface_ips = self.docker.fetch_host_interface_ips(self.host_interface)
                if not self.docker.volume_exists(self.CONTAINER_VOLUME):
                    self.docker.create_volume(self.CONTAINER_VOLUME)
                else:
                    logger.debug(f"Container volume '{self.CONTAINER_VOLUME}' already exists. Skipping the volume creation.")
                initialization_secret = Utilities.generate_string(32)
                self.docker.client.containers.run(
                    name=self.CONTAINER_NAME,
                    image=self.CONTAINER_IMAGE,
                    command=[
                        "server",
                        f"--node-ip={','.join(node_interface_ips)}",
                        "--disable=servicelb",
                        "--kubelet-arg=node-ip=::",
                        f"--cluster-cidr={cluster_cidrs}",
                        f"--service-cidr={service_cidrs}",
                        f"--flannel-iface={self.host_interface}"
                    ],
                    tmpfs={
                        "/run": "",
                        "/var/run": ""
                    },
                    privileged=True,
                    restart_policy={
                        "Name": "always"
                    },
                    environment={
                        "K3S_TOKEN": f"{initialization_secret}",
                        "K3S_KUBECONFIG_MODE": 664,
                    },
                    volumes=[
                        "k3s-volume:/var/lib/rancher/k3s",
                    ],
                    detach=True,
                    network_mode="host",
                )
                assert self.docker.check_container_status(self.CONTAINER_NAME), f"'{self.CONTAINER_NAME}' has not started successfully"
                logger.info(f"Waiting roughly 15 seconds for K3s cluster to stabilize")
                status = False
                for i in range(0, 15):
                    if self.docker.exec_command(self.CONTAINER_NAME, "[ -f /var/lib/rancher/k3s/server/node-token ]").exit_code == 0:
                        logger.info(
                            f"K3s cluster token for new nodes: "
                            f"{str(self.docker.exec_command(self.CONTAINER_NAME, 'cat /var/lib/rancher/k3s/server/node-token').output[:-1])}. "
                            f"Please save this token at a secure place as it will be displayed again.")
                        logger.info("K3s cluster is successfully initialized")
                        status = True
                        break
                assert status, "K3s cluster failed to stabilize in time. Timeout exceeded."
            else:
                logger.info("K3s cluster is already initialized. Skipping the initialization.")
                self.docker.start_container(self.CONTAINER_NAME)
                assert self.docker.check_container_status(self.CONTAINER_NAME), f"'{self.CONTAINER_NAME}' has not started successfully"
        except (Exception, AssertionError) as err:
            logger.debug(err)
            raise Exception(f"K3s cluster initialization failed!")

    def join(self, role: str, api_host: str, token: str) -> None:
        try:
            assert role and api_host and token, f"One or all of the Node role, API URL and K3s inputs are missing!"
            api_url = f"https://{api_host}:6443"
            if not self.docker:
                self._setup_docker_client()
            if not self.docker.container_exists(self.CONTAINER_NAME):
                logger.info(f"Joining the K3s cluster ({api_url}) as '{role}'")
                node_interface_ips = self.docker.fetch_host_interface_ips(self.host_interface)

                self.docker.client.containers.run(
                    name=self.CONTAINER_NAME,
                    image=self.CONTAINER_IMAGE,
                    command=[
                        role,
                        f"--node-ip={','.join(node_interface_ips)}",
                        "--kubelet-arg=node-ip=::",
                        f"--flannel-iface={self.host_interface}"
                    ],
                    tmpfs={
                        "/run": "",
                        "/var/run": ""
                    },
                    privileged=True,
                    restart_policy={
                        "Name": "always"
                    },
                    environment={
                        "K3S_URL": api_url,
                        "K3S_TOKEN": token,
                    },
                    detach=True,
                    network_mode="host",
                )
            else:
                logger.info("Node is already part of some K3s cluster. Skipping the node setup.")
                self.docker.start_container(self.CONTAINER_NAME).start()
        except (Exception, AssertionError) as err:
            logger.debug(err)
            raise Exception(f"K3s cluster setup failed!")

    def leave(self) -> None:
        try:
            if not self.docker:
                self._setup_docker_client()
            # Drain the node first.
            # Remove the node
            # Remove container and volume
            if self.docker.container_exists(self.CONTAINER_NAME):
                logger.info("Leaving the K3s cluster")
                self.docker.delete_container(self.CONTAINER_NAME)
                if self.docker.volume_exists(self.CONTAINER_VOLUME):
                    self.docker.delete_volume(self.CONTAINER_VOLUME)
                else:
                    logger.debug(f"K3s volume/s '{self.CONTAINER_VOLUME}' doesn't exist. Skipping the volume/s deletion.")
                logger.info(f"All the K3s node resources are successfully removed from the node")
            else:
                logger.info("Node is not part of the K3s cluster. Skipping the node removal.")
        except Exception as err:
            raise Exception(f"K3s cluster node removal failed!")
