#!/bin/sh

/root/printer_data/scripts/ps_mem.py -S >/tmp/list.txt
sed 's/python3.7/Klipper/' /tmp/list.txt | sed 's/python3.11/Moonraker/' | sed 's/firmwareExe/Экран/' | sed 's/mjpg_streamer/Камера/'
rm -f /tmp/list.txt
free -m
#echo "Процессы в SWAP:"
#for file in /proc/*/status ; do awk '/VmSwap|Name/{printf $2 " " $3}END{ print ""}' $file; done |sort -k 2 -n -r|head -8| sed 's/python3.7/Klipper/' | sed 's/python3/Moonraker/' | sed 's/firmwareExe/Экран/' | sed 's/mjpg_streamer/Камера/'
