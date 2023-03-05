#!/usr/bin/env python
# -*- coding: utf-8 -*-

import argparse
import json
import logging.config
import coloredlogs
# from transit_services import TransitServices
from helpers import Utilities, Docker
from operations import Tailscale


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

        args = parser.parse_args()
        if args.lab == "tailscale":
            tailscale = Tailscale(
                org=args.tailscale_org,
                host=args.ssh_ip,
                username=args.ssh_username,
                authkey=args.tailscale_authkey,
                apikey=args.tailscale_apikey)
            if "connect" in args.operation:
                tailscale.connect()
            elif "disconnect" in args.operation:
                tailscale.disconnect()
            elif "status" in args.operation:
                tailscale.print_status()
    except Exception as err:
        logger.error("Oh shoot!")
        logger.error(err)
        # raise


if __name__ == '__main__':
    main()