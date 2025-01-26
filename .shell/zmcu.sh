#!/bin/sh

sleep 5

for i in /opt/PROGRAM/control/*/; do 
    save_dir=$(pwd)
    if [ -d "$i" ]; then
        cd "$i"
        echo "">Update

        if [ "$1" -eq 1 ] && [ -f /THIS_IS_NOT_YOUR_ROOT_FILESYSTEM ]; then
            /opt/config/mod/.shell/update_mcu.sh mainboard &
        fi
        cd $save_dir
    fi
done
