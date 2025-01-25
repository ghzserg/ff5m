#!/bin/sh

for i in /opt/PROGRAM/control/*/; do 
    pushd $1
        echo "">"$i/Update";
        cp /opt/config/mod/.shell/root/mcu/Mainboard.bin Mainboard.bin
        sync
        cp /opt/config/mod/.shell/root/mcu/Eboard.hex Eboard.hex
        sync
    popd
done

echo "RESPOND TYPE=error MSG=\"Выключите питание принтера. Подождите 10 секунд и включите обратно. Начнется обновление MCU.\"" >/tmp/printer
