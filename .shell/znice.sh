#!/bin/sh

NICE=20
grep -q "^nice = " /opt/config/mod_data/variables.cfg && NICE=$(grep "^nice = " /opt/config/mod_data/variables.cfg | cut -d "=" -f2| awk '{print $1}')
NICE=$((20-$NICE))
[ $NICE -ge 20 ]  && NICE=19
[ $NICE -lt -20 ] && NICE=-20
renice $NICE $(ps |grep klippy.py| grep -v grep| awk '{print $1}')
