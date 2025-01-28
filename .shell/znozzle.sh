#!/bin/sh

echo "[temperature_sensor weightValue]
max_temp: $1" >/opt/config/mod_data/nozzle.cfg
sync
sleep 5
sync
reboot
