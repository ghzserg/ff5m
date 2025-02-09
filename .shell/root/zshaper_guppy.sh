#!/bin/sh

SCV="5.0"
if grep -q "fix_scv = 1" /opt/config/mod_data/variables.cfg; then
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


python3 /opt/config/mod/.shell/root/zshaper/calibrate_shaper.py $@ --scv=$SCV -r 1
