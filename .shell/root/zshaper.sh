#!/bin/sh

cd /opt/config/mod_data/

DT=$(date '+%Y%m%d_%H%M')

sed 's/psd_x/psd_Y/' calibration_data_x_*.csv | sed 's/psd_y/psd_x/' | sed 's/psd_Y/psd_y/' | awk -F ',' '{print $1","$3","$2","$4","$5","$6","$7","$8","$9","$10}' >X_$DT.csv
sed 's/psd_x/psd_Y/' calibration_data_y_*.csv | sed 's/psd_y/psd_x/' | sed 's/psd_Y/psd_y/' | awk -F ',' '{print $1","$3","$2","$4","$5","$6","$7","$8","$9","$10}' >Y_$DT.csv

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

echo "Подготовка изображения оси X. Ждите"
python3 /opt/config/mod/.shell/root/zshaper/calibrate_shaper.py X_$DT.csv --scv=$SCV -o calibration_data_X_$DT.png

echo "Подготовка изображения оси Y. Ждите"
python3 /opt/config/mod/.shell/root/zshaper/calibrate_shaper.py Y_$DT.csv --scv=$SCV -o calibration_data_Y_$DT.png

echo "Изображения лежат во вкладке Конфигурация -> mod_data. calibration_data_X_$DT.png и calibration_data_Y_$DT.png."
