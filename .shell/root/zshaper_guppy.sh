#!/bin/sh

SCV="5.0"
if grep -q "fix_scv = 1" /opt/config/mod_data/variables.cfg; then
    if grep -q '^square_corner_velocity' /opt/config/mod_data/user.cfg; then
        SCV=$(grep '^square_corner_velocity' /opt/config/mod_data/user.cfg| cut -d ":" -f 2 | awk '{print $1}')
        echo "Используется SCV (square_corner_velocity) = $SCV из mod_data/user.cfg"
    else if grep -q '^square_corner_velocity' /opt/config/printer.base.cfg; then
        SCV=$(grep '^square_corner_velocity' /opt/config/printer.base.cfg| cut -d ":" -f 2 | awk '{print $1}')
        echo "Используется SCV (square_corner_velocity) = $SCV из printer.base.cfg"
    else
        echo "Используется стандартный SCV (square_corner_velocity) = $SCV"
    fi
    fi
fi

if [ "$1"  == "/tmp/resonances_x_X.csv" ]; then
    sed 's/psd_x/psd_Y/' /tmp/resonances_x_X.csv | sed 's/psd_y/psd_x/' | sed 's/psd_Y/psd_y/' | awk -F ',' '{print $1","$3","$2","$4","$5}' >X
    mv X /tmp/resonances_x_X.csv
fi
if [ "$1"  == "/tmp/resonances_y_Y.csv" ]; then
    sed 's/psd_x/psd_Y/' /tmp/resonances_x_X.csv | sed 's/psd_y/psd_x/' | sed 's/psd_Y/psd_y/' | awk -F ',' '{print $1","$3","$2","$4","$5}' >Y
    mv Y /tmp/resonances_y_Y.csv
fi

python3 /opt/config/mod/.shell/root/zshaper/calibrate_shaper.py $@ --scv=$SCV -r 1
