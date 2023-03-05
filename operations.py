import logging
import json
import requests

from helpers import Utilities, Docker

logger = logging.getLogger(__name__)
logging.getLogger("paramiko").setLevel(logging.ERROR)
logging.getLogger("git").setLevel(logging.ERROR)
logging.getLogger("urllib3").setLevel(logging.ERROR)


class Tailscale(object):

    CONTAINER_NAME = "tailscaled"
    CONTAINER_IMAGE = "tailscale/tailscale"
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

    def _container_exists(self) -> bool:
        try:
            self.docker.client.containers.get(self.CONTAINER_NAME)
            return True
        except Exception:
            return False

    def fetch_status(self) -> dict:
        return json.loads(self.docker.client.containers.get(self.CONTAINER_NAME).exec_run("tailscale --socket /tmp/tailscaled.sock status --self --json").output)

    def log_status(self) -> None:
        status = self.fetch_status()
        logger.debug(f"Tailscale v{status['Version']} is configured with '{status['Self']['DNSName']}' domain and {status['Self']['TailscaleIPs']} IPs")
        logger.debug(f"Detailed Tailscale Info: {status}")
        assert status['Self']['Online'], f"Tailscale connection is DOWN"
        if status['Self']['Online']:
            logger.info(f"Tailscale v'{status['Version']}' is UP")
        else:
            logger.error(f"Tailscale v'{status['Version']}' is DOWN")

    def _check_api_status(self) -> bool:
        r = requests.get(f"{self.API_URL}/tailnet/{self.org}/acls", headers={"Authorization": f"Bearer {self.apikey}"})
        print(r)

    def print_status(self) -> None:
        assert self.apikey, "Tailscale API key is not set! It must be provided to connect to the Tailscale API."
        assert self.org, "Tailscale org. name or tailnet is not set! It is required to fetch the network status."
        self._check_api_status()

    def connect(self) -> None:
        if not self.docker:
            self._setup_docker_client()
        if not self._container_exists():
            logger.info("Establishing Tailscale Mesh VPN connection")
            self.docker.client.containers.run(
                image=self.CONTAINER_IMAGE,
                detach=True,
                name=self.CONTAINER_NAME,
                volumes=[
                    "/var/lib:/var/lib",
                    "/dev/net/tun:/dev/net/tun",
                ],
                cap_add=[
                    "NET_RAW",
                    "NET_ADMIN"
                ],
                network_mode="host",
                environment={
                    "TS_AUTHKEY": self.authkey
                }
            )
        else:
            logger.info("Tailscale Mesh VPN connection node already exists. Skipping the Tailscale Mesh VPN connection.")
            self.docker.client.containers.get(self.CONTAINER_NAME).start()

        self.log_status()

    def disconnect(self) -> None:
        if not self.docker:
            self._setup_docker_client()
        if self._container_exists():
            logger.info("Disconnecting from Tailscale Mesh VPN")
            logger.debug("Removing Tailscale container")
            self.docker.client.containers.get(self.CONTAINER_NAME).stop()
            self.docker.client.containers.get(self.CONTAINER_NAME).remove()
        else:
            logger.info("Tailscale container doesn't exist. Skipping the Tailscale Mesh VPN disconnection.")
