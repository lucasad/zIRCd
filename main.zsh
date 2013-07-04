#!/bin/zsh

zmodload zsh/net/tcp zsh/zselect

PORT=6667
ztcp -l $PORT || exit 255

FD=$REPLY

TRAPWINCH() {
    echo winch
}

TRAPINT() {
    ztcp -c $FD
    for fd in $clients; do
	ztcp -c $fd
    done
    pkill client.zsh
    exit 255
}

echo Listening on port $PORT fd $FD

./logic.zsh&

while true
do
    if ztcp -a $FD; then
	env -i ./client.zsh $REPLY&
    fi
done
