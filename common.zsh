#!/bin/zsh

readonly NICKRE='^[[:alpha:]][[:alnum:]\-\[-\`_-}]{0,8}$'
readonly CHANRE='[#&][^\0\a\r\n ,:]{1,200}'

function sendMSG() {
    command=$1
    targets=$2
    if [ -z "$targets" ]; then
        echo ":$HOST 411 :No recipient given $command"
        return 255
    fi

    MESSAGE=$3
    if [ -z "$MESSAGE" ]; then
        echo ":$HOST 412 :No text to send"
        return 255
    fi
    IFS=, read -rA targets <<< "$targets"

    for target in $targets; do
        if [[ -h "target/$target" ]]; then
            echo ":$nick!$UPREFIX $command $target :$MESSAGE" > "target/$target"
        else
            echo ":$HOST 401 $target :No such nick/channel" >&$SOCKFD
        fi
    done
}
