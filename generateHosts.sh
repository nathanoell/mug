#!/bin/bash

help() {
	echo """Take a file like shortenerConfig.json and a file holding online urls and outputs json files holding only the config of online urls, website are sorted in files based on alphabet they use.
Usage: $0 <configFile> [OPTIONS...] 
or 
Usage: cat <configFile> | $0 [OPTIONS...]
Options:
-f <Urlsfile> : if used the script won't select site based on if they're online or not but if their urls is in the file given
-a or --add-others : add website using this repo : https://github.com/PeterDaveHello/url-shorteners (strongly recommended but takes a bit more time)
--help or -h : shows this help and exit
"""
	exit 0
}

parse_args() {
	if [[ -p /dev/stdin ]] ; then
	 	configFile=$(mktemp)
		cat > $configFile
	else
		configFile=$1
		shift
	fi

    while [[ $# -gt 0 ]]; do 
        case $1 in
            -h|--help) help;;
			-f) urlsFile=$2; shift 2;;
			-a|--add-others) addOthers=1; shift ;;
            *) echo "Unknown options $1, please see --help"; exit 1 ;;
        esac
    done
}

inputVerification() {
	if ! [[ -f $configFile ]]; then
		if [[ -z $configFile ]]; then
			echo "Please give a config file, see --help for usage"
			exit 2
		else
			echo "$configFile isn't a file or don't exist"
			exit 2
		fi
	fi
	if [[ ( ! -z $urlsFile ) && ( ! -f $urlsFile ) ]]; then
		echo "$urlsFile isn't a file or don't exist"
		exit 2
	fi
}

urlsFile=""
addOthers=0
parse_args "$@"
inputVerification

newConfig='['

for iWebsite in $(seq 0 $(($(jq 'length' $configFile)- 1))); do
	url=$(jq -r ".[$iWebsite].url_template" $configFile)

	# choose of the sort url
	addWebsite=0
	if [[ -z $urlsFile ]]; then # check online
	    if [[  $(curl -I -o /dev/null -s -w '%{http_code}\n' "$url" -L --connect-timeout 5) -ne 000 ]]; then
			addWebsite=1
		fi
	else
		if grep -q $url $urlsFile; then
			addWebsite=1
		fi
	fi

	if (( $addWebsite )); then
		echo $url
		urlConfig=$(jq -r ".[$iWebsite]" $configFile)
		if [[ $newConfig = '[' ]]; then 
			newConfig="$newConfig$urlConfig"
		else
			newConfig="$newConfig,$urlConfig"
		fi
	fi
done

if [[ $addOthers -eq 1 ]]; then 
	for domain in $(curl https://raw.githubusercontent.com/PeterDaveHello/url-shorteners/master/list --silent | tail -n +12); do 
		url="https://$domain/"
		if [[ $(curl -I -o /dev/null -s -w '%{http_code}\n' "$url" --connect-timeout 5) -ne 000 ]]; then
			echo "$url"
		fi
	done
	echo "Please consider using 'sort -u' on the hosts generated to avoid duplicates" >&2
	echo "For instance : cat hosts.txt | sort -u > uniqueHosts.txt"
fi

newConfig="$newConfig]"

jq -n "$newConfig" > configOnline.json