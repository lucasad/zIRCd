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

zmodload zsh/mapfile zsh/system
readonly NICK=$1 CHANNEL=$2
readonly CHANDIR="channels/$CHANNEL"

names=($NICK)

mkdir $CHANDIR || true

touch $CHANDIR/lock
zsystem flock -t 1 $CHANDIR/lock || exit

mkfifo $CHANDIR/sock
ln -s ../$CHANDIR/sock target/$channel

