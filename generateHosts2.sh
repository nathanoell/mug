#!/bin/bash

help() {
	echo """Obtain host list from https://raw.githubusercontent.com/PeterDaveHello/url-shorteners/master/list and check for every website if it's online, if so the program print the url
Much simpler than ./generateHosts.sh, needs no manual preconfigured files. Actually, this script will create a host list that only contains the hosts that would be added by option '-a' of ./generateHosts.sh.
Nevertheless, it represent more than 90% of hosts.

Basic Usage : ./generateHosts2.sh > file
No options/arguments possible for this script."""
	exit 0
}

for domain in $(curl https://raw.githubusercontent.com/PeterDaveHello/url-shorteners/master/list --silent | tail -n +12); do 
    url="https://$domain/"
    if [[ $(curl -I -o /dev/null -s -w '%{http_code}\n' "$url" --connect-timeout 5) -ne 000 ]]; then
        echo "$url"
    fi
done