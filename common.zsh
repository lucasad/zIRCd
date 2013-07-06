#!/bin/zsh
: <<EOF
Copyright 2013 Lucas A. Dohring

Licensed under the EUPL, Version 1.1 or – as soon they
will be approved by the European Commission - subsequent
versions of the EUPL (the "Licence");

You may not use this work except in compliance with the
Licence.

You may obtain a copy of the Licence at:
http://ec.europa.eu/idabc/eupl

Unless required by applicable law or agreed to in
writing, software distributed under the Licence is
distributed on an "AS IS" basis,

WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
express or implied.

See the Licence for the specific language governing
permissions and limitations under the Licence.
EOF

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
