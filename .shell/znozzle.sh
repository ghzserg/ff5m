#!/bin/sh

if [ "$1" == "0" ]; then
    echo "">/opt/config/mod_data/nozzle.cfg
else
    echo "[temperature_sensor weightValue]
max_temp: $1" >/opt/config/mod_data/nozzle.cfg
fi

sync
sleep 5
sync
reboot
