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

zmodload zsh/system zsh/net/socket zsh/mapfile zsh/sched
IFS=" "
SOCKFD=$1
readonly CDIR=clients/$$/

readonly VERSION=$VERSION
readonly CREATED=$CREATED

user=
nick=
realname=
hostname=
mode=

integer fd
integer uOP=1  uNOT=2 uWOPS=4 uINVI=8

. ./common.zsh

function parse() {
    read command rest
    IFS=: read params last <<< "$rest"

    params=(${=params})
    if [ -n "$last" ]; then
	params+=$last
    fi

    command=$command:u
    doCommand $command $params
}

function doCommand() {
    case $command in
	USER)
	    setUser $params
	    ;;
	NICK)
	    changeNick $params
	    ;;
	PRIVMSG)
	    sendMSG PRIVMSG $params
	    ;;
	NOTICE)
	    sendMSG NOTICE $params
	    ;;
	WHOIS)
	    doWhois $params
	    ;;
	MODE)
	    mode $params
	    ;;
	TOPIC|PART|KICK|JOIN|NAMES)
	    ./channel.zsh $command $nick $params
	    ;;
	PONG)
	    resetWD
	    ;;
	PING)
	    echo :$HOST PONG :$params
	    ;;
	QUIT)
	    quit $params
	    ;;
	*)
	    echo :$HOST 421 $command :Unknown command $command
	    ;;
    esac
}

function doInit() {
    mkdir "clients/$$"
    mkfifo "clients/$$/sock"

    exec {fd}<>"clients/$$/sock"
    while read line; do echo $line >&$SOCKFD; done <&$fd &
}

function resetWD() {
    sched -${#zsh_scheduled_events}
    sched +300 echo :$HOST PING :$RANDOM
    sched +600 quit "Ping timeout"
}

function doWhois() {
    _nick=$1

    if [ -z "$_nick" ]; then
        echo :$HOST 431 :No nickname given
        return 1
    fi

    if [ ! "$_nick" '=~' '^[[:alpha:]][[:alnum:]\-\[-\`_-}]{0,8}$' ]; then
        echo :$HOST 432 $_nick :Erroneous nickname
        return 1
    fi

    _realname=$mapfile["nicks/$_nick/realname"]
    _user=$mapfile["nicks/$_nick/user"]
    _hostname=$mapfile["nicks/$_nick/hostname"]
    #realname=mapfile["nicks/$_nick/realname"]

    echo :$HOST 311 $nick $_nick $_user $_hostname :$realname
    echo :$HOST 318 $nick :End of WHOIS list
}

function setUser() {
    _user=$1
    _mode=$2
    _hostname=$3
    _realname=$4

    if [[ -z "$_mode" || -z "$_realname" ]]; then
	echo :$HOST 461 USER :Not enough parameters
    fi


    if [ -n "$user" ]; then
	echo ":$HOST 462 :Unauthorized command (already registered)"
	return 255
    fi

    user=$_user
    mode=$_mode
    hostname=$_hostname
    realname=$_realname

    mapfile["$CDIR/user"]=$user
    mapfile["$CDIR/realname"]=$realname
    mapfile["$CDIR/mode"]=$mode
    mapfile["$CDIR/hostname"]=$hostname

    if [ -n "$nick" ]; then
      welcome
    fi
}

function changeNick() {
    _nick=$1

    if [ -z "$_nick" ]; then
	echo :$HOST 431 :No nickname given
	return 1
    fi

    if [ ! "$_nick" '=~' '^[[:alpha:]][[:alnum:]\-\[-\`_-}]{0,8}$' ]; then
	echo :$HOST 432 $_nick :Erroneous nickname
	return 1
    fi

    if [ -d "nicks/$_nick" ]; then
	echo :$HOST 433 $_nick :Nickname is already in use
	return
    fi

    touch "lock/nicks/$_nick"
    if zsystem flock -t 1 "lock/nicks/$_nick"; then
	:
    else
	echo :$HOST 433 $nick :Nickname is already in use
    fi

    if [ -n "$nick" ]; then
	rm "lock/nicks/$nick"
    fi

    ln -s "../clients/$$" "nicks/$_nick"
    ln -s "../clients/$$/sock" "target/$_nick"


    if [ -n "$nick" ]; then
#	echo :$nick!$UPREFIX NICK $nick > nicks/$nick/channels/*
	echo :$nick!$user NICK $_nick

	rm target/$nick
	rm nicks/$nick
	rm lock/nicks/$nick
    fi

    nick=$_nick

    if [ -n "$user" ]; then
	welcome
    fi
}

function doMode() {
    if [[ "$1" =~ $CHANRE ]]; then
	./channel.zsh MODE $nick $@
    else
	mode $@
    fi
}

function mode() {
    if [[ ! "$1" == "$nick" ]]; then
	echo :$HOST 502 $nick :Cannot change mode for other users
	return
    fi

    pmode=+
    if [ -z $2 ]; then
        if (( $mode&4 )); then
	    pmode=${pmode}w
	fi
	if (( $mode&8 )); then
	    pmode=${pmode}i
	fi
	echo :$nick MODE $nick $pmode
    else
	:
    fi
}

function welcome() {
    echo :$HOST 001 $nick :Welcome to the Internet Relay Network $nick!$UPREFIX
    echo :$HOST 002 $nick :Your host is $HOST, running version $VERSION
    echo :$HOST 003 $nick :This server was created $CREATED
    echo :$HOST 004 $nick :$HOST $VERSION

    echo :$HOST PING :$RANDOM
    sched +300 quit "Ping timeout"
}

function sendALL() {
    if channels=(/nicks/$nick/channels/*/sock); then
	for channel in $channels; do
	    echo $@ > $channel
	done
    fi
}

function quit() {
    sendALL :$nick!$UPREFIX QUIT :$1
    echo :$nick!$UPREFIX QUIT :$1
    exec {SOCKFD}>&-
    exit
}

doInit

while read -u$1 line
do sed 's/^:\S* //' <<< "$line" | tr -d '\r' | parse >& $1; done

quit "Client Quit"
