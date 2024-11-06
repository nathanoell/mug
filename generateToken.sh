#!/bin/bash

help() {
    echo """Generate token that will be used as 'paths' in meg's vocabulary. In a nutshell, it create every possibilities of token of length tokenLength from a given alphabet.
Obviously, the number of token generated is (alphabet size)^(tokenLength), but in some case it could be very (very) large. That's why the script includes a mechanism called 'scatterRate'.
To 'scatter' cut the final big token file in smaller ones (but the space taken on disk stays the same). It cut the token by the beginning letter.
The best way to understand this mechanism is to test it, you can try :
`./generateToken.sh -a abc -l 3 -s 1` and it will be scattered only using file
`./generateToken.sh -a a1b2 -l 4 -s 2` and it will be scattered using file and folders (because scatterRate > 1)

Options :
-h or --help : shows this help
-a or --alphabet : used to give an alphabet (necessary)
-l or --tokenLength : used to give the tokenLength wanted (necessary)
-s or --scatterRate : used to set the scatterRate. Needs to be strictly lower than tokenLength.
-o or --outputD : used to give the outputDirectory, if scatterRate > 0"""
    exit 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do 
        case $1 in
            -h|--help) help;;
            -a|--alphabet) alphabet="$2"; shift 2 ;;
            -l|--tokenLength) tokenLength="$2"; shift 2 ;;
            -o|--ouputD) outputDirectory="$2"; shift 2 ;;
            -s|--scatterRate) scatterRate="$2"; shift 2 ;;
            *) echo "Unknown arguments $1, please see --help"; exit 1 ;;
        esac
    done
}

inputVerification() {
    if [[ -z "$alphabet" ]]; then
        echo '[ ! ] The given alphabet is empty or not given'
        exit 6
    else
        # Check if duplicate in the given alphabet
        for i in $(seq 1 $alphabetLength) ; do
            charI=$(echo "$alphabet" | cut -c $i)
            for j in $(seq $(($i+1)) $alphabetLength); do
                charJ=$(echo "$alphabet" | cut -c $j)
                if [[ "$charI" == "$charJ" ]]; then
                    echo '[ ! ] There are duplicate characters in the alphabet given, please check it'
                    exit 2
                fi
            done
        done
    fi
    
    if [[ $tokenLength -lt 1 || -z $tokenLength ]]; then
        echo '[ ! ] tokenLength given is lower than 1 or is not given'
        exit 3
    fi

    if ! [[ -z $scatterRate ]]; then # $scatterRate is defined
        if [[ $scatterRate -ge $tokenLength ]]; then
            echo '[ ! ] scatterRate is greater or equal to tokenLength'
            exit 4
        fi
    fi

    #if ! [[ -z $outputDirectory ]]; then
    #    if ! [[ -d $outputDirectory ]]; then
    #        echo '[ ! ] outputDirectory needs to be a directory/folder !'
    #        exit 5
    #    fi
    #fi
}

generateToken() {
    local todoLength=$1
    local todoScatterRate=$2
    local currentString=$3
    local filePath=$4

    for i in $(seq 1 $alphabetLength); do
        char=$(echo $alphabet | cut -c $i)
        nextString="$currentString$char" 

        if [[ $todoScatterRate -gt 1 ]]; then
            mkdir "$char" && cd "$char"
            generateToken $(($todoLength - 1)) $(($todoScatterRate - 1)) $nextString $filePath
            cd ".."
        elif [[ $todoScatterRate -eq 1 ]]; then
            filePath="$char.txt"
            # TODO si -f $filePath alors ....
            touch $filePath
            generateToken $(($todoLength - 1)) $(($todoScatterRate - 1)) $nextString $filePath
        else # means that $todoScatterRate = 0
            if [[ $todoLength -gt 1 ]]; then # we need to call again the function
                generateToken $(($todoLength - 1)) $todoScatterRate $nextString $filePath
            elif [[ $todoLength -eq 1 ]]; then # we can write into $filePath
                if [[ -z $filePath ]]; then
                    echo "$nextString"
                else
                    echo "$nextString" >> "$filePath"
                fi
            fi
        fi
    done
}

# TODO faire le `read /dev/stdin`
# TODO Faire le system de parsing des arguments

parse_args "$@"

alphabetLength=${#alphabet}

inputVerification

# outputDirectory processing
if ! [[ -z $outputDirectory ]]; then
    if [[ -d $outputDirectory ]]; then # directory already exist
        if ! [[ -z $(ls -A $outputDirectory) ]]; then # directory isn't empty
            echo "[ ! ] output directory given isn't empty"
            exit 7
        else    
            cd $outputDirectory
        fi
    else  
        mkdir $outputDirectory && cd $outputDirectory
    fi
fi

if [[ -z scatterRate ]]; then
    scatterRate=0
fi

generateToken $tokenLength $scatterRate