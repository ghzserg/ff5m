#!/bin/sh

echo "RESPOND TYPE=error MSG=\"Дождитесь музыкальной композиции и выключите питание принетра.\"" >/tmp/printer
echo "RESPOND TYPE=error MSG=\"Подождите 10 секунд и включите обратно. Начнется обновление MCU.\"" >/tmp/printer

sleep 5

for i in /opt/PROGRAM/control/*/; do 
    pushd $i

        echo "">Update;

        cp /opt/config/mod/.shell/root/mcu/Mainboard.bin Mainboard.bin
        sync
        cp /opt/config/mod/.shell/root/mcu/Eboard.hex Eboard.hex
        sync

        cp run.sh run.sh.save && sync
        cp run.sh run.sh.12 &&   sync
        sed -i 's/^FIRMWARE_Board_M3=.*/FIRMWARE_Board_M3=Mainboard.bin/' run.sh.12
        sync
        sed -i 's/^FIRMWARE_Head_M3=.*/FIRMWARE_Head_M3=Eboard.hex/' run.sh.12
        sync

#        if [ "$1" -eq 1 ] && [ -f /THIS_IS_NOT_YOUR_ROOT_FILESYSTEM ]; then
#            killall python3.7 firmwareExe
#
#            ./run.sh.12
#            sync
#
#            sed -i 's/^FIRMWARE_Board_M3=.*/FIRMWARE_Board_M3=Mainboard.bin.none/' run.sh.12
#            sync
#            sed -i 's/^FIRMWARE_Head_M3=.*/FIRMWARE_Head_M3=Eboard.hex/' run.sh.12
#            sync
#        fi

        sleep 5
        audio_midi.sh For_Elise.mid

    popd
done
