#!/bin/sh

cd /opt/config/mod_data/

sed 's/psd_x/psd_Y/' calibration_data_x_*.csv | sed 's/psd_y/psd_x/' | sed 's/psd_Y/psd_y/' | awk -F ',' '{print $1","$3","$2","$4","$5","$6","$7","$8","$9","$10}' >X
sed 's/psd_x/psd_Y/' calibration_data_y_*.csv | sed 's/psd_y/psd_x/' | sed 's/psd_Y/psd_y/' | awk -F ',' '{print $1","$3","$2","$4","$5","$6","$7","$8","$9","$10}' >Y

SCV="5.0"
grep -q '^square_corner_velocity' /opt/config/printer.base.cfg && SCV=$(grep '^square_corner_velocity' /opt/config/printer.base.cfg| cut -d ":" -f 2 | awk '{print $1}')

echo "SCV=$SCV"

echo "Подготовка изображения оси X. Ждите"
python3 /opt/config/mod/.shell/root/zshaper/calibrate_shaper.py X -s 1.0 --scv=$SCV -o calibration_data_X.png

echo "Подготовка изображения оси Y. Ждите"
python3 /opt/config/mod/.shell/root/zshaper/calibrate_shaper.py Y -s 1.0 --scv=$SCV -o calibration_data_Y.png

rm -f X Y
