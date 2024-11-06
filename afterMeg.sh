#!/bin/bash

help() {
    echo """Takes meg output folder and retrieve important inforations, which are the redirect links and HTTP codes.
Then it process them to delete the 'false redirect codes' which are the HTTP code showing up when the redirect url is a bad one, most of the time these redirect urls point to the home or index webpages of the specific host.
This script is called by mug but can be also used alone.
Basic Usage :
./afterMeg.sh [meg's output directory] [OPTIONS]

Options :
-h or --help : shows this help
-o or --outputD : used to specify the directory used to store ./afterMeg result and processed files. Default outputDirectory is 'mugOutput'."""
    exit 0
}

parse_args() {
    megOutput=$1
    shift
    while [[ $# -gt 0 ]]; do 
        case $1 in 
            -h|--help) help;;
            -o|--outputD) outputDirectory=$2; shift 2;;
        esac
    done
}

inputVerification() {
    if [[ -z $megOutput ]]; then
        echo "[ ! ] Please enter a directory, see --help"
        exit 1
    fi

    if [[ ! -d "$megOutput" ]]; then # check if {megOutput} is present and is a directory
        echo "[ ! ] First argument needs to be the directory of meg's output"
        exit 2
    elif [[ ! -f "$megOutput/index" ]]; then # check if {megOutput}/index is present
        echo "[ ! ] The directory holding meg's output doesn't contain 'index' !"
        exit 3
    fi

    if [[ -f $outputDirectory ]]; then
        echo "[ ! ] outputDirectory isn't a directory"
        exit 4
    fi
}

getHeader() {
    local fileName=$1
    locationLine=$(grep --text "Location:" "$fileName")
    location=$(echo "$locationLine" | cut -c 13-)
    echo "$location"
}

getHTTPCode() {
    local fileName=$1
    codeLine=$(grep --text "< HTTP/" "$fileName")
    code=$(echo "$codeLine" | cut -d " " -f 3)
    echo $code
}

afterMeg() {
    # give permissions to file 
    # default permission is -rw-r----- which is not useful
    chmod -R o+r $megOutput
    mkdir "$outputDirectory"
    cd $megOutput
    for website in $(find . -maxdepth 1 -mindepth 1 -type d); do
        if [[ ! -d  "../$outputDirectory/$website" ]]; then
            mkdir "../$outputDirectory/$website"
        fi
        > "../$outputDirectory/$website/index.txt"
        > "../$outputDirectory/$website/uniqueIndex.txt"
        cd $website

        # create intermediate index (index.txt)
        for fileName in $(find . -maxdepth 1 -mindepth 1 -type f ); do
            url=$(head -n 1 "$fileName")
            code=$(getHTTPCode "$fileName")
            if grep --text -q "Location:" $fileName; then # verify if response has a location header
                locationHeader=$(getHeader "$fileName") #redirect url
                echo "$code | $url | $locationHeader" >> "../../$outputDirectory/$website/index.txt"
            fi
        done 
        cd "../../$outputDirectory/$website/"

        uniqueUrls=$(sort -u index.txt -t '|' -k 3)
        # try to delete false-redirect
        for code in $(cut -d '|' -f 1 "index.txt" | sort -u); do
            lineConteningCode=$(grep "$code" index.txt)

            #number of times code appears
            codeNumber=$(echo -e "$lineConteningCode" | wc -l | cut -d "|" -f 1)
            
            if [[ $codeNumber -gt 1 ]]; then # we continue only if the code appears more than 2 times
                #take the first url that appears with this code and check if it's always the same url
                falseRedirectUrl=$(echo -e "$lineConteningCode" | head -n 1 | cut -d "|" -f 3)
                # remove first character (which is a space)
                falseRedirectUrl=$(echo "${falseRedirectUrl# }") 

                #number of times falseRedirectUrl and code are appearing in the same line
                urlAndCodeNumber=$(echo -e "$lineConteningCode" | cut -d '|' -f 3 | grep "$falseRedirectUrl" | wc -l | cut -d "|" -f 1)

                if [[ $codeNumber -eq $urlAndCodeNumber ]]; then
                    echo "[*] $website : false redirect code appears to be $code, redirecting to $falseRedirectUrl"
                    uniqueUrls=$(echo -e "$uniqueUrls" | grep -v "$code")
                fi
            fi
        done
        echo -e "$uniqueUrls" | cut -d '|' -f 2,3 | cut -c 2- > uniqueIndex.txt
        cd "../../$megOutput"
    done

    cd ..
    # ask if user want to unite all valuable outputs (ie all uniqueIndex.txt)
    finalOutputFileName="$outputDirectory/finalOutput.txt"
    loop=1
    finalOuputCreated=0
    while [[ $loop -eq 1 ]]; do
        read -p "[?] Create $finalOutputFileName holding the content of every uniqueIndex.txt file ? (y/N) " yn
        case $yn in
            y) ./uniteUnique.sh $outputDirectory > "$finalOutputFileName" ; loop=0 ; finalOuputCreated=1 ; break ;;
            N) loop=0 ; break ;;
        esac
    done

    # ask if user want to sort final output 
    if [[ finalOuputCreated -eq "1" ]]; then
        loop=1
        while [[ $loop -eq 1 ]]; do
            read -p "[?] Sort $finalOutputFileName ? (y/N) " yn
            case $yn in
                y) 
                tmpFile=$(mktemp)
                sort -u $finalOutputFileName > "$tmpFile"
                cat "$tmpFile" > $finalOutputFileName
                rm "$tmpFile"
                loop=0
                break ;;
                N) loop=0 ; break ;;
            esac
        done
    fi
}


outputDirectory="mugOutput"
parse_args "$@"
inputVerification
afterMeg
