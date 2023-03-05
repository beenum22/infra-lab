import logging
from paramiko import SSHClient, AutoAddPolicy, RSAKey
from paramiko.ssh_exception import AuthenticationException, SSHException
import os
import socket
import yaml
from rich.table import Table
from rich import box
from rich.console import Console
import boto3
from functools import wraps
import time
import docker
from docker import errors, DockerClient
from ipaddress import ip_address, IPv6Address

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
        table = Table(title=title, title_justify="center", box=box.HEAVY, show_lines=True)
        for column in table_content[0].keys():
            table.add_column(column, justify="center", style="cyan")
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


class Docker(object):
    @Utilities.time_it
    def __init__(self, user: str, host: str) -> None:
        self.user = user
        self.host = host
        try:
            if self.host and self.user:
                if not Utilities.is_valid_ip(self.host):
                    self.host = Utilities.resolve_hostname(self.host)
                # assert Utilities.is_valid_ip(self.host)
                elif Utilities.is_ipv6(self.host):
                    self.host = f"[{self.host}]"
            self.client = DockerClient(base_url=f"ssh://{self.user}@{self.host}" if self.user and self.host else "unix://var/run/docker.sock")
            logger.debug(f"Successfully connected to the '{host}' Docker API over SSH using '{user}' user")
        except AssertionError as err:
            raise Exception(f"Invalid host '{host}' is provided that is neither IPv4 or IPv6")
        except Exception as err:
            logger.debug(f"Docker API connection exception: {err}")
            raise Exception(f"Failed to connect to '{host}' Docker API over SSH using '{user}' user")

    # @Utilities.time_it
    # def run(self, ):
    #     logger.debug(f"Starting a Docker container")