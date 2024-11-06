#!/bin/bash

help() {
    echo """See README.md for more informations and explanations.
Usage ./mug.sh [OPTIONS...]

Options :
    -h or --help : shows this help
    -a or --alphabet : used to give a special alphabet to use, default is 'abcdefghijklmnopqrstuvwxyzABDCEFGHIJKLMNOPQRSTUVWXYZ1234567890'
    -s or --scatterRateMax : used to set the maximum scatterRate to use for each tokenLength when possible, default is 0
    -m or --tokenMinLength : used to set the minimum tokenLength. Mug will create and then iterate on tokens of length tokenMinLength to tokenMaxLength
    -M or --tokenMinLength : used to set the maximum tokenLength. See --tokenMinLength for more explanation
    -H or --host-file : used to give mug a special host file already created by the user. Can be used to spare time.
""";
    exit 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do 
        case $1 in 
            -h|--help) help;;
            -a|--alphabet) alphabet="$2"; alphabetLength=${#alphabet}; shift 2 ;;
            -s|--scatterRateMax) scatterRateMax="$2"; shift 2 ;;
            -m|--tokenMinLength) tokenMinLength="$2"; shift 2 ;;
            -M|--tokenMinLength) tokenMaxLength="$2"; shift 2 ;;
            -H|--host-file)
            tmpFilePath="$2" 
            hostUserPath="$(readlink -f $tmpFilePath)"
            shift 2;;
            *) echo "Unknown arguments $1, please see --help"; exit 1 ;;
        esac
    done
}

inputVerification() {
    # test if $hostUserPath is a file
    if [[ ! -f "$hostUserPath" ]]; then
        echo "$hostUserPath isn't a file, please use -H properly"
        exit 1
    fi
}

launchMegRecurisve() {
    local todoScatterRate=$1

    # define them local in order to do not disturb recursion (otherwise they would be global and it would be chaos)
    local i=0
    local char=''

    if [[ $todoScatterRate -eq 0 || -z $todoScatterRate ]]; then # pwd is one of the final folder containing token files
        # token file look like : letter.txt , with $letter a letter from $alphabet
        for i in $(seq 1 $alphabetLength); do
            char=$(echo $alphabet | cut -c $i)
            meg -s 301 -s 302 -s 307 -s 308 --delay 10000 -X HEAD "$char.txt" "$hostsPath" "$outPath" #save only real redirect
            #echo "meg [...] paths:$char.txt hosts:$hostsPath out:$outPath (directory:$(pwd))"
        done 
    else # we're still in folders.
        for i in $(seq 1 $alphabetLength); do
            char=$(echo $alphabet | cut -c $i)
            cd "$char"
            launchMegRecurisve $(($todoScatterRate - 1))
            cd ..
        done 
    fi
}

alphabet='abcdefghijklmnopqrstuvwxyzABDCEFGHIJKLMNOPQRSTUVWXYZ1234567890'
alphabetLength=${#alphabet}
tokenMinLength=1 #default
tokenMaxLength=4 #default
scatterRateMax='0'

chmod +x afterMeg.sh generateTokens.sh generateHosts.sh generateHosts2.sh
parse_args "$@"

# 1. Preparation of file for meg
if [[ ! -d "meg" ]]; then
    mkdir meg
fi

# 1.a Path/tokens
forLoopTokenSize=$(seq $tokenMinLength $tokenMaxLength)
for i in $forLoopTokenSize; do
    if [[ -z $scatterRateMax || $scatterRateMax -eq 0 || $i -eq 1 ]]; then # if scatter=0 or $i = 1
        if [[ -f "meg/paths$i.txt" ]]; then
            echo "[!] meg/paths$i.txt already exists, it will be used in order to save time. If you want to create it again (for example the alphabet has been changed), please delete it and run $0 again"
        else
        ./generateTokens.sh -a "$alphabet" -l $i -s 0 > "meg/paths$i.txt"
        fi
    else 
        if [[ -d "meg/paths$i" ]]; then 
            echo "[!] meg/paths$i already exists, it will be used in order to save time. If you want to create it again (for example the alphabet has been changed), please delete it and run $0 again"
        else
            # Get max between $scatterRateMax and $i because we can't launch generateTokens.sh with $scatterRate > $tokenLength
            specificScatterRate=$(($i-1))
            if (( $specificScatterRate > $scatterRateMax )) ; then
                specificScatterRate=$scatterRateMax
            fi
            ./generateTokens.sh -a "$alphabet" -l $i -s $specificScatterRate -o "meg/paths$i/"
        fi
    fi
done

# 1.b Hosts
if [[ -z $hostUserPath ]] ; then # test if hosts have been already created by the user
    hostsPath="$(pwd)/meg/hosts.txt"
    if [[ -f $hostsPath ]]; then
        echo "[!] meg/hosts.txt already exists, it will be used in order to save time. If you want to create it again (for example the alphabet has been changed), please delete it and run $0 again"
    else
        ./generateHosts2.sh > $hostsPath
    fi
else
    hostsPath=$hostUserPath
fi
echo '[+] Paths and hosts have been created. Launching meg ...'

# 2. To repeat
# 2.a Launch meg with suitable arguments
outPath="$(pwd)/out/"
for i in $forLoopTokenSize; do
    specificScatterRate=$(($i-1))
    if (( $specificScatterRate > $scatterRateMax )) ; then
        specificScatterRate=$scatterRateMax
    fi
    if [[ $specificScatterRate -eq 0 ]]; then
        meg -s 301 -s 302 -s 307 -s 308 -X HEAD "meg/paths$i.txt" $hostsPath $outPath  #save only real redirect
        #echo "meg [...] paths:meg/paths$i.txt host:$hostsPath out:$outPath (directory:$(pwd))" 
    else
        cd "meg/paths$i"
        launchMegRecurisve $(($specificScatterRate-1))
        cd '../..'
    fi
    echo "[+] Paths of length $i have been run by meg"
done

# 3. Use output
./afterMeg.sh $outPath -o "mugOut" # you can change 'mugOut' if you want a different output directory