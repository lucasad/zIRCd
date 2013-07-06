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

zmodload zsh/net/tcp zsh/zselect

readonly PORT=6667
ztcp -l $PORT || exit 255
FD=$REPLY

readonly VERSION="zIRCd 0.0.1~zsh-$ZSH_VERSION"
readonly CREATED="$(date)"

TRAPWINCH() {
    echo winch
}

TRAPINT() {
    for fd in $clients; do
	ztcp -c $fd
    done
    pkill client.zsh
    ztcp -c $FD
    exit 255
}

echo Listening on port $PORT fd $FD

./logic.zsh&

while true
do
    if ztcp -a $FD; then
	env -i CREATED="$CREATED" ./client.zsh $REPLY&
    fi
done
