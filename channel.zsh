#!/bin/zsh

readonly COMMAND=$1 NICK=$2
shift 2
case $COMMAND in
    JOIN)
	join $@
	;;
    PART)
	part $@
	;;
    KICK)
	kick $@
	;;
    TOPIC)
	topic $@
	;;
    NAMES)
	names $@
	;;
    MODE)
	mode $@
	;;
esac

function validateChannel() {
    readonly channel=$1
    if [[ ! "$channel" =~ $CHANRE ]]; then
	echo ":$HOST 478 $NICK $channel :No such channel"
	exit
    fi
}
function join() {
    readonly channel=$1
    validateChannel $channel

    [[ -e "target/$channel" ]] || ./spawnChannel $NICK $channel &
    echo "JOIN $NICK" > "target/$channel"
}

function part() {
    readonly channel=$1
    validateChannel $channel
    chanExist $channel

    echo "PART $NICK" > "target/$channel"
}

function kick() {
    readonly channel=$1
    validateChannel $channel
    chanExist $channel

    echo "KICK $NICK" > "target/$channel"
}

function mode() {
    readonly channel=$1
    shift
    validateChannel $channel
    chanExist $channel

    echo "MODE $NICK $@" > "target/$channel"
}

function topic() {
    readonly channel=$1
    validateChannel $channel
    if read topic < "channels/$channel/topic"; then
	if [ -n "$topic" ]; then
	    echo ":$HOST 332 $NICK $CHANNEL :$topic"
	else
	    echo ":$HOST 331 $NICK $CHANNEL :No topic set"
	fi
    else
	echo :$HOST 403 $NICK $CHANNEL :No such channel
    fi
}

function names() {
    readonly channel=$1
    shift
    validateChannel $channel
    chanExist $channel

    echo "NAMES $NICK $@" > "target/$channel"
}

function chanExist () {
    readonly CHANNEL=$1
    if [[ ! -e "target/$channel" ]]; then
	echo :$HOST 403 $NICK $CHANNEL :No such channel
    fi
}
