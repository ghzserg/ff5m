#!/bin/bash

# Более точный замер времени - Alexander
if [ $# -ne 2 ] && [ $# -ne 3 ] && [ $# -ne 4 ]; then echo "Используйте $0 SIZE [SYNC] [FLASH] [RANDOM]\nhttps://github.com/ghzserg/zmod/wiki/Macros#test_emmc"; exit 1; fi

SIZE=$1
FILE="/data"
INFILE="/dev/zero"
t3=0

[ "$3" == "1" ] && FILE="/media" && echo "Тестирование USB FLASH"
[ "$3" == "2" ] && FILE="/tmp" && echo "Тестирование RAM"

if [ "$FILE" == "/data" ]; then
    life=$(cat /sys/block/mmcblk0/device/life_time | awk '{print $1}'| while read a; do printf "%d0" $a; done;)
    echo "Износ EMMC: $life%"
fi

if [ "$4" == "1" ]; then
    INFILE="/dev/urandom"
    echo "Тестирование случайными данными"
    read up rest </proc/uptime; t1="${up%.*}${up#*.}"
    dd if=$INFILE of=/dev/null bs=1M count=${SIZE} status=none
    read up rest </proc/uptime; t2="${up%.*}${up#*.}"
    dd if=/dev/zero of=/dev/null bs=1M count=${SIZE} status=none
    read up rest </proc/uptime; t0="${up%.*}${up#*.}"
    t3=$(( (2*t2-t1-t0) ))
fi

FREE_SPACE=$(df $FILE 2>/dev/null|grep -v /dev/root|grep -v Filesystem| tail -1 | tr -s ' ' | cut -d' ' -f4)
MIN_SPACE=$(($SIZE*1024))
if [ "$FREE_SPACE" == "" ] || [ "$FREE_SPACE" -lt "$MIN_SPACE" ]; then
    echo "Не хватает свободного места на запись $SIZE MB";
    exit 0
fi

FILE="$FILE/test.img"

if [ "$2" == "0" ]; then
    echo "В фоне будет записано ${SIZE} MB"
    dd if=$INFILE of=$FILE bs=1M count=${SIZE} conv=fsync status=none 2>/dev/null &
else
    echo "Идет тестирование записи/чтения ${SIZE} MB данных. Ждите..."

    read up rest </proc/uptime; t1="${up%.*}${up#*.}"
    dd if=$INFILE of=$FILE bs=1M count=${SIZE} conv=fsync status=none 2>/dev/null
    read up rest </proc/uptime; t2="${up%.*}${up#*.}"
    TIME_W=$(( 10*(t2-t1-t3) ))

    read up rest </proc/uptime; t1="${up%.*}${up#*.}"
    dd if=$FILE of=/dev/null bs=1M count=${SIZE} conv=fsync status=none 2>/dev/null
    read up rest </proc/uptime; t2="${up%.*}${up#*.}"
    TIME_R=$(( 10*(t2-t1) ))

    rm -f $FILE

    awk "BEGIN {print \"Записано $SIZE MB. Запись: \" ($SIZE * 1000 / $TIME_W) \" MB/s. Чтение: \" ($SIZE * 1000 / $TIME_R) \" MB/s.\"}"
fi
