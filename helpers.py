import logging
from typing import Any

from paramiko import SSHClient, AutoAddPolicy, RSAKey
from paramiko.ssh_exception import AuthenticationException, SSHException
import os
import socket
import yaml
import json
import random
import string
from rich.table import Table
from rich import box
from rich.console import Console
import boto3
from functools import wraps
import time
import docker
from docker import errors, DockerClient
from ipaddress import ip_address, IPv6Address
import requests
from pathlib import Path

logger = logging.getLogger(__name__)
logging.getLogger("paramiko").setLevel(logging.ERROR)
logging.getLogger("git").setLevel(logging.ERROR)
logging.getLogger("urllib3").setLevel(logging.ERROR)


class AWSClient(object):
    AWS_REGION = "eu-central-1"

    def __init__(self, service: str, aws_region: str = AWS_REGION) -> None:
        self.service = service
        self.aws_region = aws_region
        AWSClient._validate_env_vars()
        self.client = boto3.client(self.service, region_name=self.aws_region)

    @staticmethod
    def _validate_env_vars() -> None:
        assert os.getenv("AWS_ACCESS_KEY_ID") or os.getenv("AWS_SECRET_ACCESS_KEY") or os.getenv("AWS_SESSION_TOKEN"), \
            "Please configure/export AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and AWS_SESSION_TOKEN env vars properly " \
            "from 'https://logon.idp.aws.corpinter.net/Home/Cli'"

    def validate_account_id(self, account_id: str) -> None:
        client = boto3.client("sts")
        current_account_id = client.get_caller_identity()["Account"]
        assert account_id == current_account_id, \
            f"You have AWS credentials/env variables configured for incorrect account ID [{current_account_id}]. " \
            f"Make sure you have exported env variables for the correct account ID [{account_id}]."


class OutputInfo(object):
    def __init__(self) -> None:
        self.console = Console()

    def output_details_table(self, title: str, table_content: list) -> None:
        table = Table(title=title, title_justify="left", box=box.HEAVY, show_lines=True, expand=True)
        for column in table_content[0].keys():
            table.add_column(column, justify="center", style="cyan", no_wrap=True if column == "Addresses" else False)
        for row in table_content:
            table.add_row(*row.values())
        self.console.print(table)


class Utilities(object):
    @staticmethod
    def time_it(func):
        @wraps(func)
        def timeit_wrapper(*args, **kwargs):
            start_time = time.perf_counter()
            result = func(*args, **kwargs)
            end_time = time.perf_counter()
            total_time = end_time - start_time
            logger.debug(f'Function {func.__name__}{args} {kwargs} Took {total_time:.4f} seconds')
            return result

        return timeit_wrapper

    @staticmethod
    def is_valid_ip(ip):
        try:
            ip_address(ip)
            return True
        except ValueError:
            return False

    @staticmethod
    def is_ipv6(ip):
        if type(ip_address(ip)) is IPv6Address:
            return True
        else:
            return False

    @staticmethod
    def resolve_hostname(name) -> str:
        return socket.gethostbyname(name)

    @staticmethod
    def generate_string(length: int) -> str:
        return ''.join(random.choices(string.ascii_lowercase + string.ascii_uppercase + string.digits, k=length))

    @staticmethod
    def request_api(api_url: str, path: str, token: str, method: str = "GET", body: dict = None, timeout: int = 10) -> tuple[int, Any]:
        try:
            assert token, f"API token is not set! It must be provided to connect to the '{api_url}' API."
            response = {}
            supported_methods = ["GET", "DELETE", "POST"]
            method = method.upper()
            assert method in supported_methods, f"Invalid API method '{method}' request. " \
                                                f"Supported methods are {','.join(supported_methods)}."
            headers = {
                "Accept": "application/json",
                "Authorization": f"Bearer {token}"
            }
            if method == "GET":
                response = requests.get(f"{api_url}/{path}", headers=headers, timeout=timeout)
            elif method == "DELETE":
                response = requests.delete(f"{api_url}/{path}", headers=headers, timeout=timeout)
            elif method == "POST":
                assert body, f"Body/data is required for {method} API request."
                response = requests.post(f"{api_url}/{path}", headers=headers, timeout=timeout, json=body)
            response_status = response.status_code
            try:
                response_json = response.json()
            except json.decoder.JSONDecodeError:
                logger.debug(f"No JSON data received from the '{api_url}' API")
                response_json = {}
            return response_status, response_json
        except (AssertionError, requests.exceptions.RequestException) as err:
            logger.debug(err)
            raise Exception(f"Failed to make a request to '{api_url}' API.")


class Docker(object):
    @Utilities.time_it
    def __init__(self, user: str, host: str) -> None:
        self.user = user
        self.host = host
        self.url = f"ssh://{self.user}@{self.host}" if self.user and self.host else "unix://var/run/docker.sock"
        try:
            if self.host and self.user:
                if not Utilities.is_valid_ip(self.host):
                    self.host = Utilities.resolve_hostname(self.host)
                elif Utilities.is_ipv6(self.host):
                    self.host = f"[{self.host}]"
            self.client = DockerClient(base_url=self.url)
            logger.debug(f"Successfully connected to the '{host}' Docker API over SSH using '{user}' user")
        except AssertionError as err:
            raise Exception(f"Invalid host '{host}' is provided that is neither IPv4 or IPv6")
        except docker.errors.APIError as err:
            raise Exception(f"Failed to connect to the Docker API ({self.url}). {err}.")

    @Utilities.time_it
    def container_exists(self, name: str) -> bool:
        try:
            self.client.containers.get(name)
            return True
        except docker.errors.NotFound:
            return False
        except docker.errors.APIError as err:
            logger.debug(f"Failed to connect to the Docker API ({self.url}). {err}.")
            raise Exception(f"Failed to check '{name}' container status")

    @Utilities.time_it
    def exec_command(self, container: str, cmd: str) -> None:
        try:
            logger.debug(f"Executing the command '{cmd}' inside a '{container}' container")
            return self.client.containers.get(container).exec_run(cmd)
        except docker.errors.APIError as err:
            logger.debug(f"Failed to connect to '{self.host}' Docker API ({self.url}). {err}")
            raise Exception(f"Failed to execute the command '{cmd}' inside a '{container}' container")

    @Utilities.time_it
    def start_container(self, name: str) -> None:
        try:
            logger.debug(f"Starting/restarting the '{name}' container")
            return self.client.containers.get(name).start()
        except docker.errors.APIError as err:
            logger.debug(f"Failed to connect to '{self.host}' Docker API ({self.url}). {err}")
            raise Exception(f"Failed to start the '{name}' container")

    @Utilities.time_it
    def check_container_status(self, name: str) -> bool:
        try:
            if self.client.containers.get(name).status == "running":
                logger.debug(f"'{name}' container is in 'running' state")
                return True
            logger.debug(f"'{name}' container is in 'exited' state")
            return False
        except docker.errors.APIError as err:
            logger.debug(f"Failed to connect to '{self.host}' Docker API ({self.url}). {err}")
            raise Exception(f"Failed to check the '{name}' container status")

    @Utilities.time_it
    def delete_container(self, name: str) -> None:
        try:
            self.client.containers.get(name).stop()
            self.client.containers.get(name).remove()
            logger.debug(f"'{name}' container is successfully deleted")
        except docker.errors.APIError as err:
            logger.debug(f"Failed to connect to '{self.host}' Docker API ({self.url}). {err}")
            raise Exception(f"Failed to delete the '{name}' container")

    @Utilities.time_it
    def volume_exists(self, name: str) -> bool:
        try:
            self.client.volumes.get(name)
            return True
        except docker.errors.NotFound:
            return False
        except docker.errors.APIError as err:
            logger.debug(f"Failed to connect to '{self.host}' Docker API ({self.url}). {err}.")
            raise Exception(f"Failed to check '{name}' container volume status")

    @Utilities.time_it
    def create_volume(self, name: str, driver: str = "local") -> None:
        try:
            assert driver in ["local"], f"Docker storage driver '{driver}' is invalid. Only supported driver is 'local."
            self.client.volumes.create(
                name=name,
                driver=driver
            )
        except docker.errors.APIError as err:
            logger.debug(f"Failed to connect to '{self.host}' Docker API ({self.url}). {err}")
            raise Exception(f"Failed to create the container volume '{name}' using '{driver}' storage driver")

    @Utilities.time_it
    def delete_volume(self, name: str) -> None:
        try:
            self.client.volumes.get(name).remove()
            logger.debug(f"'{name}' container volume is successfully deleted")
        except docker.errors.APIError as err:
            logger.debug(f"Failed to connect to '{self.host}' Docker API ({self.url}). {err}")
            raise Exception(f"Failed to delete the container volume '{name}'")

    @Utilities.time_it
    def fetch_host_interface_ips(self, interface: str) -> list:
        try:
            interfaces = []
            interface_dump = json.loads(self.client.containers.run(
                name="helper-interfaces",
                image="centos",
                command=f"ip -json addr show {interface}",
                privileged=True,
                detach=True,
                network_mode="host",
            ).logs())
            for i in interface_dump[0]["addr_info"]:
                if i["scope"] == "global":
                    interfaces.append(i["local"])
            self.delete_container("helper-interfaces")
            logger.debug(f"Container host interface '{interface}' IPs [{','.join(interfaces)}] are successfully fetched")
            return interfaces
        except docker.errors.APIError as err:
            logger.debug(f"Failed to connect to '{self.host}' Docker API ({self.url}). {err}")
            raise Exception(f"Failed to fetch the container host interface '{interface}' IPs")
        except json.decoder.JSONDecodeError:
            logger.debug(f"Container host interface '{interface}' doesn't exist on the host")
            raise Exception(f"Failed to fetch the container host interface '{interface}' IPs")