#!/bin/zsh
zmodload zsh/mapfile zsh/system
readonly NICK=$1 CHANNEL=$2
readonly CHANDIR="channels/$CHANNEL"

mkdir $CHANDIR || true

touch $CHANDIR/lock
zsystem flock -t 1 $CHANDIR/lock || exit

mkfifo $CHANDIR/sock
ln -s ../$CHANDIR/sock targets/$channel

