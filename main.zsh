#!/bin/zsh

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
