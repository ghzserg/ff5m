#!/bin/sh

sleep 5

for i in /opt/PROGRAM/control/*/; do 
    save_dir=$(pwd)
    if [ -d "$i" ]; then
        cd "$i"
        echo "">Update

        cp /opt/config/mod/.shell/root/mcu/Mainboard.bin Mainboard.bin
        sync
        cp /opt/config/mod/.shell/root/mcu/Eboard.hex Eboard.hex
        sync

        cp run.sh run.sh.save && sync
        rm -f run.sh.12

        if [ "$1" -eq 1 ] && [ -f /THIS_IS_NOT_YOUR_ROOT_FILESYSTEM ]; then
            killall python3.7 firmwareExe

            cp run.sh run.sh.12 && sync

            sed -i 's/^FIRMWARE_Board_M3=.*/FIRMWARE_Board_M3=Mainboard.bin/' run.sh.12
            sync
            sed -i 's/^FIRMWARE_Head_M3=.*/FIRMWARE_Head_M3=Eboard.hex.none/' run.sh.12
            sync

            ./run.sh.12 &>/opt/config/mod_data/log/mcu.log
            sync

            sed -i 's/^FIRMWARE_Board_M3=.*/FIRMWARE_Board_M3=Mainboard.bin.none/' run.sh.12
            sync
            sed -i 's/^FIRMWARE_Head_M3=.*/FIRMWARE_Head_M3=Eboard.hex/' run.sh.12
            sync
        fi
        cd $save_dir
    fi
done

sleep 5
audio_midi.sh For_Elise.mid
