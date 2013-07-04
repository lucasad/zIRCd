#!/bin/zsh

for dir in lock/nicks lock/channels clients nicks channels target; do
    [ -e "$dir" ] && rm -r "$dir"
    mkdir -p "$dir"
done
