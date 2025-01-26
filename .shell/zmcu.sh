#!/bin/sh

set -x

sleep 5

for i in /opt/PROGRAM/control/*/; do 
    save_dir=$(pwd)
    if [ -d "$i" ]; then
        cd "$i"
        echo "">Update

        if [ "$1" -eq 1 ] && [ -f /THIS_IS_NOT_YOUR_ROOT_FILESYSTEM ]; then
            killall python3.7 firmwareExe
            /opt/config/mod/.shell/update_mcu.sh mainboard
            sync
        fi
        cd $save_dir
    fi
done

sleep 5
sync
audio_midi.sh For_Elise.mid
sync
