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

function validateChannel() {
    readonly channel=$1
    if [[ ! "$channel" =~ $CHANRE ]]; then
	echo ":$HOST 478 $NICK $channel :No such channel"
	exit
    fi
}
function JOIN() {
    readonly channel=$1
    validateChannel $channel

    [[ -e "target/$channel" ]] || ./spawnChannel.zsh $NICK $channel &
    echo "JOIN $NICK" > "target/$channel"
}

function PART() {
    readonly channel=$1
    validateChannel $channel
    chanExist $channel

    echo "PART $NICK" > "target/$channel"
}

function KICK() {
    readonly channel=$1
    validateChannel $channel
    chanExist $channel

    echo "KICK $NICK" > "target/$channel"
}

function MODE() {
    readonly channel=$1
    shift
    validateChannel $channel
    chanExist $channel

    echo "MODE $NICK $@" > "target/$channel"
}

function TOPIC() {
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

function NAMES() {
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

readonly COMMAND=$1 NICK=$2
shift 2
$COMMAND $@
