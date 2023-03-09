#!/usr/bin/env python
# -*- coding: utf-8 -*-

import argparse
import json
import logging.config
import coloredlogs
# from transit_services import TransitServices
from helpers import Utilities, Docker
from operations import Tailscale, K3s


@Utilities.time_it
def main():
    logger = logging.getLogger()
    coloredlogs.DEFAULT_FIELD_STYLES = {
        "asctime": {
            "color": "green"
        },
        "hostname": {
            "color": "magenta"
        },
        "levelname": {
            "faint": True,
            "color": "cyan"
        },
        "name": {
            "color": "blue"
        },
        "programname": {
            "color": "cyan"
        },
        "username": {
            "color": "yellow"
        }
    }
    coloredlogs.DEFAULT_LEVEL_STYLES = {
        "critical": {
            "bold": True,
            "color": "red"
        },
        "debug": {
            "color": "green",
            "faint": True
        },
        "error": {
            "color": "red"
        },
        "info": {
            "color": "green"
        },
        "notice": {
            "color": "magenta"
        },
        "success": {
            "bold": True,
            "color": "green"
        },
        "verbose": {
            "color": "blue"
        },
        "warning": {
            "color": "yellow"
        },
        "deprecated": {
            "color": "yellow",
            "faint": True
        }
    }
    coloredlogs.install(fmt="%(levelname)s: %(message)s", level='DEBUG')
    try:
        # logging.basicConfig(format="%(levelname)s: %(message)s")
        parser = argparse.ArgumentParser(
            prog="home_lab")
        parser.add_argument(
            "--debug",
            default=None,
            help="Set debug mode."
        )
        parser.add_argument(
            "--ssh-username",
            default=None,
            help="SSH username."
        )
        parser.add_argument(
            "--ssh-ip",
            default=None,
            help="SSH IP."
        )
        subparsers = parser.add_subparsers(
            title="Home Lab Helper",
            description="A simple Python helper script to manage deployment and operations of all the Home Lab resources.",
            dest="lab"
        )
        tailscale = subparsers.add_parser("tailscale", help="Connect/Disconnect to the Tailscale Mesh VPN")
        tailscale.add_argument(
            "operation",
            nargs="+",
            choices=[
                "connect",
                "disconnect",
                "status"
            ],
            help="Tailscale Operations.\n"
                 "connect: Connect to the tailscale Mesh VPN.\n"
                 "disconnect: Disonnect from the tailscale Mesh VPN.\n"
                 "status: Print out tailscale Mesh VPN status/details.\n"
        )
        tailscale.add_argument(
            "--tailscale-org",
            default="beenum22.github",
            help="Tailscale organization name or tailnet."
        )
        tailscale.add_argument(
            "--tailscale-authkey",
            default=None,
            help="Tailscale authorization key to use for connection."
        )
        tailscale.add_argument(
            "--tailscale-apikey",
            default=None,
            help="Tailscale API key to use for connection."
        )
        k3s = subparsers.add_parser("k3s", help="Initialize/Join/Leave K3s cluster")
        k3s.add_argument(
            "operation",
            nargs="+",
            choices=[
                "init",
                "join",
                "leave",
                "status",
                "config"
            ],
            help="K3s Operations.\n"
                 "init: Initialize a K3s cluster.\n"
                 "join: Join a K3s cluster as master or worker node.\n"
                 "leave: Leave a K3s cluster.\n"
                 "status: Print out K3s cluster status/details.\n"
                 "status: Print out K3s cluster kubeconfig.\n"
        )
        k3s.add_argument(
            "--k3s-cluster-cidrs",
            default="10.42.0.0/16,2001:cafe:42:0::/56",
            help="K3s cluster subnets/CIDRs that will be used for K3s Pods network."
        )
        k3s.add_argument(
            "--k3s-service-cidrs",
            default="10.43.0.0/16,2001:cafe:42:1::/112",
            help="K3s service subnets/CIDRs that will be used for K3s services network."
        )
        k3s.add_argument(
            "--k3s-additional-flags",
            nargs="+",
            default=[
                "--disable servicelb",
                "--kubelet-arg=node-ip=::"
            ],
            help="K3s tool additional flags/inputs to pass."
        )
        k3s.add_argument(
            "--k3s-node-role",
            default=None,
            help="Node role in K3s cluster.",
            choices=[
                "server",
                "agent"
            ]
        )
        k3s.add_argument(
            "--k3s-token",
            default=None,
            help="K3s cluster token."
        )
        k3s.add_argument(
            "--k3s-api",
            default=None,
            help="K3s cluster API URL."
        )
        k3s.add_argument(
            "--k3s-ipv6-only",
            default=False,
            help="K3s cluster API URL with IPv6 only."
        )

        args = parser.parse_args()
        if args.lab == "tailscale":
            tailscale_client = Tailscale(
                org=args.tailscale_org,
                host=args.ssh_ip,
                username=args.ssh_username,
                authkey=args.tailscale_authkey,
                apikey=args.tailscale_apikey
            )
            if "connect" in args.operation:
                tailscale_client.connect()
            elif "disconnect" in args.operation:
                tailscale_client.disconnect()
            elif "status" in args.operation:
                tailscale_client.print_status()
        elif args.lab == "k3s":
            k3s_client = K3s(
                host=args.ssh_ip,
                username=args.ssh_username
            )
            if "init" in args.operation:
                k3s_client.create(args.k3s_cluster_cidrs, args.k3s_service_cidrs)
            elif "join" in args.operation:
                k3s_client.join(args.k3s_node_role, args.k3s_api, args.k3s_token)
            elif "leave" in args.operation:
                k3s_client.leave()
            elif "config" in args.operation:
                k3s_client.get_kubeconfig(ipv6=args.k3s_ipv6_only)
    except Exception as err:
        logger.error("Oh shoot!")
        logger.error(err)
        raise


if __name__ == '__main__':
    main()