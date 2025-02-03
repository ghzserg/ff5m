#!/bin/bash

if [ $# -ne 1 ]; then echo "Используйте $0 FILE"; exit 1; fi

if ! [ -f "/data/$1" ]; then
    echo "RESPOND TYPE=error MSG=\"Файл $1 не найден.\"" >/tmp/printer
    echo "CANCEL_PRINT" >/tmp/printer
    exit 1
fi

head -1000 "/data/$1" | grep ^EXCLUDE_OBJECT_DEFINE >/root/printer.txt
cnt=$(cat /root/printer.txt| wc -l)

if [ "$cnt" -ne 0 ]; then
# Igor Polunovskiy code
#    awk -F= '{print $4}' /root/printer.txt |sed 's/\],/\n/g;s/,/=/g;s/\[//g;s/\]//g'|awk -F= 'BEGIN{maxy = -1000; maxx = -1000; miny = 1000; minx = 1000}{if (maxx<$1) maxx = $1; if (minx>$1) minx = $1;if (maxy<$2) maxy = $2; if (miny>$2) miny = $2}END{printf "EXCLUDE_OBJECT_DEFINE NAME=border CENTER=%.4f,%.4f POLYGON=[[%.4f,%.4f],[%.4f,%.4f],[%.4f,%.4f],[%.4f,%.4f]]\n",(minx+maxx)/2,(miny+maxy)/2,minx,miny,minx,maxy,maxx, maxy, maxx, miny}' >/tmp/printer
    sed -n '1,/;LAYER_CHANGE/s/;LAYER_CHANGE/;FIRST_LAYER_CHANGE/;1,/;LAYER_CHANGE/s/;LAYER_CHANGE/;SECOND_LAYER_CHANGE/;/;FIRST_LAYER_CHANGE/,/;SECOND_LAYER_CHANGE/p' "/data/$1" | \
        awk 'BEGIN{maxy = -1000; maxx = -1000; miny = 1000; minx = 1000} $1~/G[123]/ {for (i = 2; i<=NF; i++) {if ("X" == substr($i,1,1)) {x=0+substr($i,2); if (maxx<x) maxx = x; if (minx>x) minx = x} else if  ("Y" == substr($i,1,1)) {y=0+substr($i,2); if (maxy<y) maxy = y; if (miny>y) miny = y}}}END{printf "EXCLUDE_OBJECT_DEFINE NAME=border CENTER=%.4f,%.4f POLYGON=[[%.4f,%.4f],[%.4f,%.4f],[%.4f,%.4f],[%.4f,%.4f]]\n",(minx+maxx)/2,(miny+maxy)/2,minx,miny,minx,maxy,maxx, maxy, maxx, miny}' >/tmp/printer
fi

rm -f /root/printer.txt
exit 0
