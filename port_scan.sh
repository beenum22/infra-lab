#!/usr/bin/env bash

# Check if at least one argument is provided
if [ "$#" -eq 0 ]; then
    echo "Usage: $0 [<user>@]<remote_host1> [[<user>@]<remote_host2> ...]"
    exit 1
fi

# Loop over each provided user@remote_host
for ARG in "$@"; do
    # Split the argument into user and host
    USER=""
    HOST=""

    if [[ "$ARG" == *@* ]]; then
        USER=$(echo "$ARG" | cut -d'@' -f1)
        HOST=$(echo "$ARG" | cut -d'@' -f2)
    else
        HOST="$ARG"
    fi

    # Determine if the host is IPv4 or IPv6
    if [[ "$HOST" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        ADDRESS_TYPE="IPv4"
    elif [[ "$HOST" =~ ^[0-9a-fA-F:]+$ ]]; then
        ADDRESS_TYPE="IPv6"
    else
        ADDRESS_TYPE="Unknown"
    fi

    echo "Processing host: $HOST, User: $USER"

    if [ $ADDRESS_TYPE == "IPv4" ]; then
      TCP_PORTs=$(ssh $USER@$HOST "netstat -tuln" | awk '/^tcp / {print $4}' | awk -F: '{print $NF}')
      UDP_PORTs=$(ssh $USER@$HOST "netstat -tuln" | awk '/^udp / {print $4}' | awk -F: '{print $NF}')
    elif [ $ADDRESS_TYPE == "IPv6" ]; then
      TCP_PORTs=$(ssh $USER@$HOST "netstat -tuln" | awk '/^tcp6/ {print $4}' | awk -F: '{print $NF}')
      UDP_PORTs=$(ssh $USER@$HOST "netstat -tuln" | awk '/^udp6/ {print $4}' | awk -F: '{print $NF}')
    fi

    echo "Scanning the TCP ports..."
    for port in $TCP_PORTs; do
      if [ $ADDRESS_TYPE == "IPv4" ]; then
        echo "  $(nmap -Pn -sV -p$port $HOST | awk '/^[0-9]/ {print $1, "-", $2}')"
      elif [ $ADDRESS_TYPE == "IPv6" ]; then
        echo "  $(nmap -Pn -sV -p$port -6 $HOST | awk '/^[0-9]/ {print $1, "-", $2}')"
      fi
    done

    echo "Scanning the UDP ports..."
    for port in $UDP_PORTs; do
      if [ $ADDRESS_TYPE == "IPv4" ]; then
        echo "  $(sudo nmap -Pn -sU -p$port $HOST | awk '/^[0-9]/ {print $1, "-", $2}')"
      elif [ $ADDRESS_TYPE == "IPv6" ]; then
        echo "  $(sudo nmap -Pn -sU -p$port -6 $HOST | awk '/^[0-9]/ {print $1, "-", $2}')"
      fi
    done
    echo "----"
done