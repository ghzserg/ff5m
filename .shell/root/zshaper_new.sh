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

DT=$(date '+%Y%m%d_%H%M')

cd /opt/config/mod_data/

sed 's/psd_x/psd_Y/' /tmp/resonances_x_X.csv | sed 's/psd_y/psd_x/' | sed 's/psd_Y/psd_y/' | awk -F ',' '{print $1","$3","$2","$4","$5"}' >X
sed 's/psd_x/psd_Y/' /tmp/resonances_y_Y.csv | sed 's/psd_y/psd_x/' | sed 's/psd_Y/psd_y/' | awk -F ',' '{print $1","$3","$2","$4","$5"}' >Y

echo "Подготовка изображения оси X. Ждите..."
python3 /opt/config/mod/.shell/root/zshaper/calibrate_shaper.py X --scv=$SCV -o calibration_data_X_$DT.png -w 8 -l 4.8 --send X
cp calibration_data_X_$DT.png resonances_x.png

echo "Подготовка изображения оси Y. Ждите..."
python3 /opt/config/mod/.shell/root/zshaper/calibrate_shaper.py Y --scv=$SCV -o calibration_data_Y_$DT.png -w 8 -l 4.8 --send Y
cp calibration_data_Y_$DT.png resonances_y.png

mkdir -p shapers
mv X_$DT shapers/X_$DT.csv
mv Y_$DT shapers/Y_$DT.csv
mv calibration_data_X_$DT.png shapers/
mv calibration_data_Y_$DT.png shapers/

echo "Изображения лежат во вкладке Конфигурация -> mod_data. resonances_x.png и resonances_y.png."
