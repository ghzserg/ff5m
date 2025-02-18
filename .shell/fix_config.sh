#!/bin/sh

set -x

# Разблокировка
china_razbl()
{
    grep -q "$1" /etc/hosts && sed -i "/$1/d" /etc/hosts
}

# Блокировка
china_block()
{
    grep -q "$1" /etc/hosts || sed -i "2 i\127.0.0.1 $1" /etc/hosts
}

check_link()
{
    a=$(readlink "$1" 2>/dev/null)
    if [ "$a" != "$2" ]; then
        echo -n "$1 - Ошибочная ссылка ($a!=$2): "
        rm -f "$1" 2>/dev/null
        ln -s "$2" "$1" 2>/dev/null && echo "Исправлено"  || echo "Ошибка исправления"
    fi
}

fix_config()
{
    echo "START fix_config"
    date
    fstrim /data -v
    fstrim / -v


    # Защита от самонадеянных, кто выклчюает SWAP при 128 мегабайтах оперативной памяти
    if grep -q "use_swap = 0" /opt/config/mod_data/variables.cfg; then
        MEM=$(cat /proc/meminfo | grep MemTotal| awk '{print $2}')
        MEM=$(($MEM/1024))
        [ "$MEM" -le 128 ] && sed -i "s/use_swap = 0/use_swap = 1/" /opt/config/mod_data/variables.cfg
    fi

    [ -f /opt/config/mod_data/nozzle.cfg ] || echo "">/opt/config/mod_data/nozzle.cfg

    [ -f /etc/init.d/S50sshd ] && rm -f /etc/init.d/S50sshd
    [ -f /etc/init.d/S55date ] && rm -f /etc/init.d/S55date
    [ -f /bin/dropbearmulti ] && rm -f /bin/dropbearmulti

    check_link /bin/dropbearkey /opt/config/mod/.shell/eabi/dropbear
    check_link /bin/dropbear /opt/config/mod/.shell/eabi/dropbear
    check_link /bin/dbclient /opt/config/mod/.shell/eabi/dropbear
    check_link /bin/scp /opt/config/mod/.shell/eabi/dropbear
    check_link /bin/ssh /opt/config/mod/.shell/eabi/dropbear
    check_link /etc/init.d/S60dropbear /opt/config/mod/.shell/S60dropbear
    check_link /etc/init.d/S00fix /opt/config/mod/.shell/fix_config.sh
    check_link /usr/bin/audio.py /opt/config/mod/.shell/root/audio/audio.py

    NEED_REBOOT=0
    PRINTER_BASE_ORIG="/opt/config/printer.base.cfg"
    PRINTER_CFG_ORIG="/opt/config/printer.cfg"
    PRINTER_BASE="/tmp/printer.base.cfg"
    PRINTER_CFG="/tmp/printer.cfg"

    cp ${PRINTER_BASE_ORIG} ${PRINTER_BASE}
    cp ${PRINTER_CFG_ORIG} ${PRINTER_CFG}
    cat ${PRINTER_BASE}
    cat ${PRINTER_CFG}

    if ! [ -f /opt/config/mod_data/power_off.sh ]; then
        echo "#!/bin/sh
unset LD_PRELOAD

#/opt/cloud/curl-7.55.1-https/bin/curl -k https://mail.ru
" >/opt/config/mod_data/power_off.sh
    chmod +x /opt/config/mod_data/power_off.sh
    fi

    # Rem стукач
    if grep -q "china_cloud = 1" /opt/config/mod_data/variables.cfg; then
        china_razbl api.cloud.flashforge.com
        china_razbl api.fdmcloud.flashforge.com
        china_razbl cloud.sz3dp.com
        china_razbl hz.sz3dp.com
        china_razbl printer2.polar3d.com
        china_razbl qvs.qiniuapi.com
        china_razbl update.cn.sz3dp.com
        china_razbl update.sz3dp.com
        china_razbl cloud.sz3dp.com
        china_razbl polar3d.com
    else
        china_block api.cloud.flashforge.com
        china_block api.fdmcloud.flashforge.com
        china_block cloud.sz3dp.com
        china_block hz.sz3dp.com
        china_block printer2.polar3d.com
        china_block qvs.qiniuapi.com
        china_block update.cn.sz3dp.com
        china_block update.sz3dp.com
        china_block cloud.sz3dp.com
        china_block polar3d.com
    fi

    grep -q ZLOAD_VARIABLE /opt/klipper/klippy/extras/save_variables.py || cp /opt/config/mod/.shell/save_variables.py /opt/klipper/klippy/extras/save_variables.py
    grep -q "Zcontrol 1.1" /opt/klipper/klippy/extras/spi_temperature.py || cp /opt/config/mod/.shell/spi_temperature.py /opt/klipper/klippy/extras/spi_temperature.py
    check_link /opt/klipper/klippy/extras/zmod.py /opt/config/mod/.shell/zmod.py

    # Fix possible ordering issue if a callback blocks in button handler#6440
    grep -q receive_time /opt/klipper/klippy/extras/buttons.py || cp /opt/config/mod/.shell/buttons.py /opt/klipper/klippy/extras/buttons.py

    grep -q zmod_1.0 /opt/klipper/klippy/extras/gcode_shell_command.py || cp /opt/config/mod/.shell/gcode_shell_command.py /opt/klipper/klippy/extras/gcode_shell_command.py
    if [ -L /opt/klipper/klippy/extras/load_cell_tare.py ] || [ -f /opt/klipper/klippy/extras/load_cell_tare.py ]; then
        rm -f /opt/klipper/klippy/extras/load_cell_tare.py
    fi

    grep -q '^\[include check_md5.cfg\]' ${PRINTER_CFG} && sed -i '/^\[include check_md5.cfg\]/d' ${PRINTER_CFG} && NEED_REBOOT=1

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

    # Возвращаем gcode_button check_level_pin
    if ! grep -q '^\[gcode_button check_level_pin' ${PRINTER_BASE}
        then
            NEED_REBOOT=1
            echo '
[gcode_button check_level_pin]
pin: !PE0
press_gcode:
    M105
' >>${PRINTER_BASE}
    fi

    # Удаляем filament_switch_sensor e0_sensor
    if grep -q '^\[filament_switch_sensor e0_sensor' ${PRINTER_BASE}
        then
            NEED_REBOOT=1

            ! grep -q "motion_sensor" /opt/config/mod_data/variables.cfg && sed -i '1 i\motion_sensor = 0' /opt/config/mod_data/variables.cfg
            sed -i "s/^motion_sensor.*/motion_sensor = 0/" /opt/config/mod_data/variables.cfg

            sed -e '/^\[filament_switch_sensor e0_sensor/,/^\[/d' ${PRINTER_BASE} >printer.base.tmp
            diff -u ${PRINTER_BASE} printer.base.tmp | grep -v "printer.base.cfg" |grep "^-" | cut -b 2- >heater_bed.txt
            sed -i '$d' heater_bed.txt
            num=$(wc -l heater_bed.txt|cut  -d " " -f1)
            num=$(($num-1))
            sed -e "/^\[filament_switch_sensor e0_sensor/,+${num}d;" ${PRINTER_BASE} >printer.base.tmp
            cat printer.base.tmp >${PRINTER_BASE}
            rm -f heater_bed.txt printer.base.tmp
    fi

    # Удаляем filament_motion_sensor e0_sensor
    if grep -q '^\[filament_motion_sensor e0_sensor' ${PRINTER_BASE}
        then
            NEED_REBOOT=1

            ! grep -q "motion_sensor" /opt/config/mod_data/variables.cfg && sed -i '1 i\motion_sensor = 1' /opt/config/mod_data/variables.cfg
            sed -i "s/^motion_sensor.*/motion_sensor = 1/" /opt/config/mod_data/variables.cfg

            sed -e '/^\[filament_motion_sensor e0_sensor/,/^\[/d' ${PRINTER_BASE} >printer.base.tmp
            diff -u ${PRINTER_BASE} printer.base.tmp | grep -v "printer.base.cfg" |grep "^-" | cut -b 2- >heater_bed.txt
            sed -i '$d' heater_bed.txt
            num=$(wc -l heater_bed.txt|cut  -d " " -f1)
            num=$(($num-1))
            sed -e "/^\[filament_motion_sensor e0_sensor/,+${num}d;" ${PRINTER_BASE} >printer.base.tmp
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


    ! grep -q "motion_sensor" /opt/config/mod_data/variables.cfg && sed -i '1 i\motion_sensor = 0' /opt/config/mod_data/variables.cfg

    # Режим с экраном
    if grep -q '^\[include ./mod/mod.cfg\]' ${PRINTER_CFG}; then
        grep -q '^\[include ./mod/switch_sensor_display_off.cfg\]' ${PRINTER_CFG} && sed -i '/^\[include .\/mod\/switch_sensor_display_off.cfg\]/d' ${PRINTER_CFG} && NEED_REBOOT=1
        if grep -q "motion_sensor = 1" /opt/config/mod_data/variables.cfg; then
            ! grep -q '^\[include ./mod/motion_sensor.cfg\]'       ${PRINTER_CFG} && sed -i '/^\[include \.\/mod\/mod\.cfg\]/a [include ./mod/motion_sensor.cfg]' ${PRINTER_CFG} && NEED_REBOOT=1
              grep -q '^\[include ./mod/switch_sensor.cfg\]'       ${PRINTER_CFG} && sed -i '/^\[include .\/mod\/switch_sensor.cfg\]/d' ${PRINTER_CFG} && NEED_REBOOT=1
        else
            ! grep -q '^\[include ./mod/switch_sensor.cfg\]'       ${PRINTER_CFG} && sed -i '/^\[include \.\/mod\/mod\.cfg\]/a [include ./mod/switch_sensor.cfg]' ${PRINTER_CFG} && NEED_REBOOT=1
              grep -q '^\[include ./mod/motion_sensor.cfg\]'       ${PRINTER_CFG} && sed -i '/^\[include .\/mod\/motion_sensor.cfg\]/d' ${PRINTER_CFG} && NEED_REBOOT=1
        fi
    fi

    # Режим без экрана
    if grep -q '^\[include ./mod/display_off.cfg\]' ${PRINTER_CFG}; then
        grep -q '^\[include ./mod/switch_sensor.cfg\]'                   ${PRINTER_CFG} && sed -i '/^\[include .\/mod\/switch_sensor.cfg\]/d' ${PRINTER_CFG} && NEED_REBOOT=1
        if grep -q "motion_sensor = 1" /opt/config/mod_data/variables.cfg; then
            ! grep -q '^\[include ./mod/motion_sensor.cfg\]' ${PRINTER_CFG} && sed -i '/^\[include \.\/mod\/diplay_off\.cfg\]/a [include ./mod/motion_sensor.cfg]' ${PRINTER_CFG} && NEED_REBOOT=1
              grep -q '^\[include ./mod/switch_sensor_display_off.cfg\]' ${PRINTER_CFG} && sed -i '/^\[include .\/mod\/switch_sensor_display_off.cfg\]/d' ${PRINTER_CFG} && NEED_REBOOT=1
        else
            ! grep -q '^\[include ./mod/switch_sensor_display_off.cfg\]' ${PRINTER_CFG} && sed -i '/^\[include \.\/mod\/diplay_off\.cfg\]/a [include ./mod/switch_sensor_display_off.cfg]' ${PRINTER_CFG} && NEED_REBOOT=1
              grep -q '^\[include ./mod/motion_sensor.cfg\]'             ${PRINTER_CFG} && sed -i '/^\[include .\/mod\/motion_sensor.cfg\]/d' ${PRINTER_CFG} && NEED_REBOOT=1
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
    fi
    diff -u ${PRINTER_BASE} ${PRINTER_BASE_ORIG}
    diff -u ${PRINTER_CFG} ${PRINTER_CFG_ORIG}
    echo "END fix_config"


    if [ "$1" == "start" ] && grep -q "klipper12 = 1" /opt/config/mod_data/variables.cfg; then
        cnt=$(find /opt/PROGRAM/control/ -name Update|wc -l)
        if [ "$cnt" -ne 0 ]; then
            # Если обновляем MCU
            find /opt/PROGRAM/control/ -name Update| sed 's/Update//'| while read a; do
                mount -o bind /opt/config/mod/.shell/update_mcu.sh ${a}run.sh
            done
        else
            # Если обновлений нет
            mount -o bind /opt/config/mod/.shell/klipper12.sh /opt/klipper/start.sh
            sync
        fi
    fi
    sync
}

if [ -f /opt/config/mod/REMOVE ] || [ -f /opt/config/mod/FULL_REMOVE ] || [ -f /opt/config/mod/SKIP_ZMOD ]; then
    exit 0
fi

mkdir -p /opt/config/mod_data/log/

mv /opt/config/mod_data/log/fix_config.4.log/opt/config/mod_data/log/fix_config.5.log
mv /opt/config/mod_data/log/fix_config.3.log /opt/config/mod_data/log/fix_config.4.log
mv /opt/config/mod_data/log/fix_config.2.log /opt/config/mod_data/log/fix_config.3.log
mv /opt/config/mod_data/log/fix_config.1.log /opt/config/mod_data/log/fix_config.2.log
mv /opt/config/mod_data/log/fix_config.log /opt/config/mod_data/log/fix_config.1.log

fix_config "$1" &>/opt/config/mod_data/log/fix_config.log

sync
