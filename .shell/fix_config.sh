#!/bin/sh

set -x

ns_off()
{
    grep -q "$1" /etc/hosts && sed -i "|$1|d" /etc/hosts
}

ns_on()
{
    grep -q "$1" /etc/hosts || sed -i "2 i\127.0.0.1 $1" /etc/hosts
}

fix_config()
{
    echo "START fix_config"
    date

    NEED_REBOOT=0
    PRINTER_BASE_ORIG="/opt/config/printer.base.cfg"
    PRINTER_CFG_ORIG="/opt/config/printer.cfg"
    PRINTER_BASE="/tmp/printer.base.cfg"
    PRINTER_CFG="/tmp/printer.cfg"

    cp ${PRINTER_BASE_ORIG} ${PRINTER_BASE}
    cp ${PRINTER_CFG_ORIG} ${PRINTER_CFG}
    cat ${PRINTER_BASE}
    cat ${PRINTER_CFG}

    # Rem стукач
    if grep -q "china_cloud = 1" /opt/config/mod_data/variables.cfg; then
        ns_off api.cloud.flashforge.com
        ns_off api.fdmcloud.flashforge.com
        ns_off cloud.sz3dp.com
        ns_off hz.sz3dp.com
        ns_off printer2.polar3d.com
        ns_off qvs.qiniuapi.com
        ns_off update.cn.sz3dp.com
        ns_off update.sz3dp.com
        ns_off cloud.sz3dp.com
        ns_off polar3d.com
    else
        ns_on api.cloud.flashforge.com
        ns_on api.fdmcloud.flashforge.com
        ns_on cloud.sz3dp.com
        ns_on hz.sz3dp.com
        ns_on printer2.polar3d.com
        ns_on qvs.qiniuapi.com
        ns_on update.cn.sz3dp.com
        ns_on update.sz3dp.com
        ns_on cloud.sz3dp.com
        ns_on polar3d.com
    fi

    grep -q ZLOAD_VARIABLE /opt/klipper/klippy/extras/save_variables.py || cp /opt/config/mod/.shell/save_variables.py /opt/klipper/klippy/extras/save_variables.py

    grep -q zmod_1.0 /opt/klipper/klippy/extras/gcode_shell_command.py || cp /opt/config/mod/.shell/gcode_shell_command.py /opt/klipper/klippy/extras/gcode_shell_command.py

    grep -q '^\[include check_md5.cfg\]' ${PRINTER_CFG} && sed -i '|^\[include check_md5.cfg\]|d' ${PRINTER_CFG} && NEED_REBOOT=1

    grep -q '^\[include ./mod/mod.cfg\]' ${PRINTER_CFG} && grep -q '^\[include ./mod/display_off.cfg\]' ${PRINTER_CFG} && sed -i '/^\[include .\/mod\/display_off.cfg\]/d' ${PRINTER_CFG} && NEED_REBOOT=1

    #sed -i 's|\[include ./mod/display_off.cfg\]|\[include ./mod/mod.cfg\]|' ${PRINTER_CFG}

    cnt=$(grep '^\[include ./mod_data/user.cfg\]' ${PRINTER_CFG} |wc -l)
    [ "$cnt" -gt 1 ] && sed -i '/^\[include .\/mod_data\/user.cfg\]/d' ${PRINTER_CFG} && NEED_REBOOT=1

    cnt=$(grep '^\[include ./mod/mod.cfg\]' ${PRINTER_CFG} |wc -l)
    [ "$cnt" -gt 1 ] && sed -i '/^\[include .\/mod\/mod.cfg\]/d' ${PRINTER_CFG} && NEED_REBOOT=1

    ! grep -q '^\[include ./mod/mod.cfg\]' ${PRINTER_CFG} && ! grep -q '^\[include ./mod/display_off.cfg\]' ${PRINTER_CFG} && sed -i '2 i\[include ./mod/mod.cfg]' ${PRINTER_CFG} && NEED_REBOOT=1

    grep -q '^\[include mod.user.cfg\]' ${PRINTER_CFG} && sed -i 's|^\[include mod.user.cfg\]|\[include ./mod_data/user.cfg\]|' ${PRINTER_CFG} && NEED_REBOOT=1

    ! grep -q '^\[include ./mod_data/user.cfg\]'  ${PRINTER_CFG} && sed -i '3 i\[include ./mod_data/user.cfg]' ${PRINTER_CFG} && NEED_REBOOT=1

    if ! grep -q '^\[heater_bed' ${PRINTER_CFG}
        then
            NEED_REBOOT=1

            # Copy and remove from printer.base.cfg
            if grep -q '^\[heater_bed' ${PRINTER_BASE}
                then
                    sed -e '/^\[heater_bed/,/^\[/d' ${PRINTER_BASE} >printer.base.tmp
                    diff -u ${PRINTER_BASE} printer.base.tmp | grep -v "printer.base.cfg" |grep "^-" | cut -b 2- >heater_bed.txt
                    sed -i '$d' heater_bed.txt
                    num=$(wc -l heater_bed.txt|cut  -d " " -f1)
                    num=$(($num-1))
                    sed -e "/^\[heater_bed/,+${num}d;" ${PRINTER_BASE} >printer.base.tmp
                    cat printer.base.tmp >${PRINTER_BASE}
                    rm -f printer.base.tmp
                else
                    echo "[heater_bed]
heater_pin: PB9
sensor_type: Generic 3950
sensor_pin: PC3
pullup_resistor: 4700
control: pid
pid_Kp: 32.79
pid_Ki: 4.970
pid_Kd: 54.118
#control: watermark
#max_power: 1.0
min_temp: -100
max_temp: 130

" >heater_bed.txt
            fi

            num=$(cat -n ${PRINTER_CFG} |grep ./mod_data/user.cfg| awk '{print $1}')
            head -n $num ${PRINTER_CFG} >printer.tmp
            echo "" >>printer.tmp
            cat heater_bed.txt >>printer.tmp
            num=$(($num+1))
            tail -n +$num ${PRINTER_CFG} >>printer.tmp
            cat printer.tmp >${PRINTER_CFG}
            rm heater_bed.txt || echo "Not heater_bed.txt"
    fi

    if grep -q '^\[heater_bed' ${PRINTER_BASE}
        then
            NEED_REBOOT=1

            sed -e '/^\[heater_bed/,/^\[/d' ${PRINTER_BASE} >printer.base.tmp
            diff -u ${PRINTER_BASE} printer.base.tmp | grep -v "printer.base.cfg" |grep "^-" | cut -b 2- >heater_bed.txt
            sed -i '$d' heater_bed.txt
            num=$(wc -l heater_bed.txt|cut  -d " " -f1)
            num=$(($num-1))
            sed -e "/^\[heater_bed/,+${num}d;" ${PRINTER_BASE} >printer.base.tmp
            cat printer.base.tmp >${PRINTER_BASE}
            rm -f heater_bed.txt printer.base.tmp
    fi

    # Удаляем fan_generic pcb_fan
    if grep -q '^\[fan_generic pcb_fan' ${PRINTER_BASE}
        then
            NEED_REBOOT=1

            sed -e '/^\[fan_generic pcb_fan/,/^\[/d' ${PRINTER_BASE} >printer.base.tmp
            diff -u ${PRINTER_BASE} printer.base.tmp | grep -v "printer.base.cfg" |grep "^-" | cut -b 2- >heater_bed.txt
            sed -i '$d' heater_bed.txt
            num=$(wc -l heater_bed.txt|cut  -d " " -f1)
            num=$(($num-1))
            sed -e "/^\[fan_generic pcb_fan/,+${num}d;" ${PRINTER_BASE} >printer.base.tmp
            cat printer.base.tmp >${PRINTER_BASE}
            rm -f heater_bed.txt printer.base.tmp
    fi

    # Удаляем controller_fan pcb_fan
    if grep -q '^\[controller_fan pcb_fan' ${PRINTER_BASE}
        then
            NEED_REBOOT=1

            sed -e '/^\[controller_fan pcb_fan/,/^\[/d' ${PRINTER_BASE} >printer.base.tmp
            diff -u ${PRINTER_BASE} printer.base.tmp | grep -v "printer.base.cfg" |grep "^-" | cut -b 2- >heater_bed.txt
            sed -i '$d' heater_bed.txt
            num=$(wc -l heater_bed.txt|cut  -d " " -f1)
            num=$(($num-1))
            sed -e "/^\[controller_fan pcb_fan/,+${num}d;" ${PRINTER_BASE} >printer.base.tmp
            cat printer.base.tmp >${PRINTER_BASE}
            rm -f heater_bed.txt printer.base.tmp
    fi

    # Удаляем filament_switch_sensor e0_sensor
    if grep -q '^\[gcode_button check_level_pin' ${PRINTER_BASE}
        then
            NEED_REBOOT=1

            sed -e '/^\[filament_switch_sensor e0_sensor/,/^\[/d' ${PRINTER_BASE} >printer.base.tmp
            diff -u ${PRINTER_BASE} printer.base.tmp | grep -v "printer.base.cfg" |grep "^-" | cut -b 2- >heater_bed.txt
            sed -i '$d' heater_bed.txt
            num=$(wc -l heater_bed.txt|cut  -d " " -f1)
            num=$(($num-1))
            sed -e "/^\[filament_switch_sensor e0_sensor/,+${num}d;" ${PRINTER_BASE} >printer.base.tmp
            cat printer.base.tmp >${PRINTER_BASE}
            rm -f heater_bed.txt printer.base.tmp
    fi

    # Удаляем gcode_button check_level_pin
    if grep -q '^\[gcode_button check_level_pin' ${PRINTER_BASE}
        then
            NEED_REBOOT=1

            sed -e '/^\[gcode_button check_level_pin/,/^\[/d' ${PRINTER_BASE} >printer.base.tmp
            diff -u ${PRINTER_BASE} printer.base.tmp | grep -v "printer.base.cfg" |grep "^-" | cut -b 2- >heater_bed.txt
            sed -i '$d' heater_bed.txt
            num=$(wc -l heater_bed.txt|cut  -d " " -f1)
            num=$(($num-1))
            sed -e "/^\[gcode_button check_level_pin/,+${num}d;" ${PRINTER_BASE} >printer.base.tmp
            cat printer.base.tmp >${PRINTER_BASE}
            rm -f heater_bed.txt printer.base.tmp
    fi

    # Добавляем controller_fan driver_fan
    if ! grep -q '^\[controller_fan driver_fan' ${PRINTER_BASE}
        then
            NEED_REBOOT=1
            echo '
[controller_fan driver_fan]
pin:PB7
fan_speed: 1.0
idle_timeout: 30
stepper: stepper_x, stepper_y, stepper_z
' >>${PRINTER_BASE}
    fi

    # Klipper12 FIX
    if grep -q "klipper12 = 1" /opt/config/mod_data/variables.cfg; then
        if grep -q '^max_accel_to_decel' ${PRINTER_BASE}
            then
                NEED_REBOOT=1
                sed -i 's|^max_accel_to_decel.*|minimum_cruise_ratio: 0.5|' ${PRINTER_BASE}
        fi
    else
        if grep -q '^minimum_cruise_ratio' ${PRINTER_BASE}
            then
                NEED_REBOOT=1
                sed -i 's|^minimum_cruise_ratio.*|max_accel_to_decel:5000|' ${PRINTER_BASE}
        fi
    fi

    if [ ${NEED_REBOOT} -eq 1 ]
        then
            echo "Kill firmwareExe"
            sync
            killall firmwareExe
            sync
            sync
            diff -u ${PRINTER_BASE} ${PRINTER_BASE_ORIG}
            diff -u ${PRINTER_CFG} ${PRINTER_CFG_ORIG}
            cat ${PRINTER_BASE} >${PRINTER_BASE_ORIG}
            sync
            cat ${PRINTER_CFG} >${PRINTER_CFG_ORIG}
#            if [ "$1" == "start" ]; then
#                echo "Reboot"
#                sync
#                reboot
#            fi
    fi
    diff -u ${PRINTER_BASE} ${PRINTER_BASE_ORIG}
    diff -u ${PRINTER_CFG} ${PRINTER_CFG_ORIG}
    echo "END fix_config"

    if [ "$1" == "start" ]; then
        if grep -q "klipper12 = 1" /opt/config/mod_data/variables.cfg; then
            if [ ! "`mount | grep "mmcblk0p7"`" ]; then
                echo "mmcblk0p7 not mounted and will fsck";
                fsck -y /dev/mmcblk0p7 && mount /dev/mmcblk0p7 /data;
            fi
            mount -o bind /opt/config/mod/.shell/klipper12.sh /opt/klipper/start.sh
        fi
        sync
    fi
}

mkdir -p /opt/config/mod_data/log/

[ -L /etc/init.d/S00fix ] || ln -s /opt/config/mod/.shell/fix_config.sh /etc/init.d/S00fix

mv /opt/config/mod_data/log/fix_config.log.4 /opt/config/mod_data/log/fix_config.log.5
mv /opt/config/mod_data/log/fix_config.log.3 /opt/config/mod_data/log/fix_config.log.4
mv /opt/config/mod_data/log/fix_config.log.2 /opt/config/mod_data/log/fix_config.log.3
mv /opt/config/mod_data/log/fix_config.log.1 /opt/config/mod_data/log/fix_config.log.2
mv /opt/config/mod_data/log/fix_config.log /opt/config/mod_data/log/fix_config.log.1

fix_config "$1" &>/opt/config/mod_data/log/fix_config.log

sync
