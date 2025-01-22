#!/bin/bash

if [ $# -ne 2 ]; then echo "Используйте $0 FILE NONE|TEST"; exit 1; fi

mkdir -p /data/tmp/

if ! [ -f "/data/$1" ]; then
    echo "RESPOND TYPE=error MSG=\"Файл $1 не найден.\"" >/tmp/printer
    echo "CANCEL_PRINT" >/tmp/printer
    exit 1
fi

M109=$(head -1000 "/data/$1" | grep "^M109" | head -1)
[ "$M109" == "" ] && M109=$(head -1000 "/data/$1" | grep "^M104" | head -1 | sed 's|M104|M109|')
M190=$(head -1000 "/data/$1" | grep "^M190" | head -1)
[ "$M190" == "" ] && M190=$(head -1000 "/data/$1" | grep "^M140" | head -1 | sed 's|M140|M190|')

if [ "$M190" == "" ] || [ "$M109" == "" ]; then
    echo "RESPOND TYPE=error MSG=\"В файле $1 не найдены команды нагрева стола(M140/M190) или сопла(M104/M109).\"" >/tmp/printer
    echo "CANCEL_PRINT" >/tmp/printer
    exit 1
fi

if [ "$2" == "TEST" ]; then
    echo "$M190" >>/data/tmp/exlude.gcode
    echo "$M109" >>/data/tmp/exlude.gcode
    echo "_START_PRECLEAR" >>/data/tmp/exlude.gcode
fi
exit 0
