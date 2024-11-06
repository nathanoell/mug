#!/bin/bash

help() {
    echo "$0 unites all uniqueIndex.txt files from the output directory of mug. It is called by afterMeg.sh";
    exit 0
}

parse_args() {
    if [[ "$1" = '--help' || "$1" = '-h' ]]; then
        help
    fi
    outputDirectory=$1
}

inputVerification() {
    if [[ ! -d $outputDirectory ]]; then
        echo "$outputDirectory isn't a directory !"
        exit 1
    fi
}

parse_args "$@"
inputVerification

for folder in $(find $outputDirectory -mindepth 1 -type d); do 
    grep -i . "$folder/uniqueIndex.txt" | cut -d "|" -f 2 | cut -d " " -f 2 # grep is used instead of cat to remove possible blank line
    #grep -i . "$folder/uniqueIndex.txt" # if the usern wants to keep the original url.
done