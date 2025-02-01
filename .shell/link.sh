#!/bin/bash

if [ $2 == 'file' ]; then
    stat -c "check_mod '%n' '%a'" "$1"
else
    cp -a "$1" "../stock/$1"
    a=$(readlink "$1")
    echo "check_link '$1' '$a'"
fi
