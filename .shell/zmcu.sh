#!/bin/sh

for i in /opt/PROGRAM/control/*/; do echo "">"$i/Update"; done

echo "RESPOND TYPE=error MSG=\"Выключите питание принтера. Подождите 10 секунд и включите обратно. Начнется обновление MCU.\"" >/tmp/printer
