#!/bin/sh

sed 's/psd_x/psd_Y/' "$1" | sed 's/psd_y/psd_x/' | sed 's/psd_Y/psd_y/' | awk -F ',' '{print $1","$3","$2","$4","$5","$6","$7","$8","$9","$10}' >/tmp/1.txt
mv /tmp/1.txt "$1"

SCV="5.0"
if grep -q "fix_scv = 1" /opt/config/mod_data/variables.cfg; then
    echo "Ускорения выводимые дальше расчитаны корректнее, чем ускорения которые были выведены ранее."
    if grep -q '^square_corner_velocity' /opt/config/mod_data/user.cfg; then
        SCV=$(grep '^square_corner_velocity' /opt/config/mod_data/user.cfg| cut -d ":" -f 2 | awk '{print $1}')
        echo "Используется SCV из mod_data/user.cfg"
    else if grep -q '^square_corner_velocity' /opt/config/printer.base.cfg; then
        SCV=$(grep '^square_corner_velocity' /opt/config/printer.base.cfg| cut -d ":" -f 2 | awk '{print $1}')
        echo "Используется SCV из printer.base.cfg"
    else
        echo "Используется стандартный SCV"
    fi
    fi
fi

echo "SCV (square_corner_velocity) = $SCV"

python3 /opt/config/mod/.shell/root/zshaper/calibrate_shaper.py "$@" --scv=$SCV
