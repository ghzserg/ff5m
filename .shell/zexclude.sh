#!/bin/bash

if [ $# -ne 1 ]; then echo "Используйте $0 FILE"; exit 1; fi

if ! [ -f "/data/$1" ]; then
    echo "RESPOND TYPE=error MSG=\"Файл $1 не найден.\"" >/tmp/printer
    echo "CANCEL_PRINT" >/tmp/printer
    exit 1
fi

head -1000 "/data/$1" | grep ^EXCLUDE_OBJECT_DEFINE >/tmp/printer 2>/dev/null
exit 0
