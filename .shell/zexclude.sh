#!/bin/bash

if [ $# -ne 1 ]; then echo "Используйте $0 FILE"; exit 1; fi

mkdir -p /data/tmp/
> /data/tmp/exlude.gcode

if ! [ -f "/data/$1" ]; then
    echo "RESPOND TYPE=error MSG=\"Файл $1 не найден.\"" >/tmp/printer
    echo "CANCEL_PRINT" >/tmp/printer
    exit 1
fi

head -1000 "/data/$1" | grep ^EXCLUDE_OBJECT_DEFINE >/data/tmp/exlude.gcode
exit 0
