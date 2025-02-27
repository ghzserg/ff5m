#!/bin/sh

set -x

MOD=/data/.mod/.zmod

ns_off()
{
    grep -q "$1" /etc/hosts && sed -i "/$1/d" /etc/hosts
}

restore_base()
{
    grep -q '^\[include mod.user.cfg' /opt/config/printer.cfg && sed -i '/include mod.user.cfg/d' /opt/config/printer.cfg
    grep -q '^\[include ./mod/mod.cfg' /opt/config/printer.cfg && sed -i '/mod.cfg/d' /opt/config/printer.cfg
    grep -q '^\[include ./mod_data/user.cfg' /opt/config/printer.cfg && sed -i '/user.cfg/d' /opt/config/printer.cfg
    grep -q '^\[include ./mod/switch_sensor.cfg' /opt/config/printer.cfg && sed -i '/switch_sensor.cfg/d' /opt/config/printer.cfg
    grep -q '^\[include ./mod/display_off.cfg' /opt/config/printer.cfg && sed -i '/display_off.cfg/d' /opt/config/printer.cfg

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

    grep -q _output_callback_gcode /opt/klipper/klippy/webhooks.py && cp /opt/config/mod/.shell/webhooks.py.orig /opt/klipper/klippy/webhooks.py
    grep -q ZLOAD_VARIABLE /opt/klipper/klippy/extras/save_variables.py && cp /opt/config/mod/.shell/save_variables.py.orig /opt/klipper/klippy/extras/save_variables.py
    grep -q zmod /opt/klipper/klippy/extras/spi_temperature.py && cp /opt/config/mod/.shell/spi_temperature.py.orig /opt/klipper/klippy/extras/spi_temperature.py
    grep -q receive_time /opt/klipper/klippy/extras/buttons.py && cp /opt/config/mod/.shell/buttons.py.orig /opt/klipper/klippy/extras/buttons.py

    F="/opt/klipper/klippy/toolhead.py"
    grep -q "LOOKAHEAD_FLUSH_TIME = 0.5" $F || sed -i 's|^LOOKAHEAD_FLUSH_TIME.*|LOOKAHEAD_FLUSH_TIME = 0.5|' $F

    F="/opt/klipper/klippy/mcu.py"
    grep -q "TRSYNC_TIMEOUT = 0.025" $F || sed -i 's|^TRSYNC_TIMEOUT = .*|TRSYNC_TIMEOUT = 0.025|' $F

    # Удаляем controller_fan driver_fan
    if grep -q '^\[controller_fan driver_fan' /opt/config/printer.base.cfg
        then
            cd /opt/config/
            sed -e '/^\[controller_fan driver_fan/,/^\[/d' printer.base.cfg >printer.base.tmp
            diff -u printer.base.cfg printer.base.tmp | grep -v "printer.base.cfg" |grep "^-" | cut -b 2- >heater_bed.txt
            sed -i '$d' heater_bed.txt
            num=$(wc -l heater_bed.txt|cut  -d " " -f1)
            num=$(($num-1))
            sed -e "/^\[controller_fan driver_fan/,+${num}d;" printer.base.cfg >printer.base.tmp
            mv printer.base.tmp printer.base.cfg
            rm -f heater_bed.txt
    fi

    # Возвращаем fan_generic pcb_fan
    if ! grep -q '^\[fan_generic pcb_fan' /opt/config/printer.base.cfg
        then
            echo '
[fan_generic pcb_fan]
pin:PB7
' >>/opt/config/printer.base.cfg
    fi

    # Возвращаем gcode_button check_level_pin
    if ! grep -q '^\[gcode_button check_level_pin' /opt/config/printer.base.cfg
        then
            echo '
[gcode_button check_level_pin]
pin: !PE0
press_gcode:
    M105
' >>/opt/config/printer.base.cfg
    fi

    # Возвращаем filament_switch_sensor e0_sensor
    if ! grep -q '\[filament_switch_sensor e0_sensor' /opt/config/printer.base.cfg
        then
            echo '
[filament_switch_sensor e0_sensor]
pause_on_runout: False
switch_pin: !PB14
event_delay: 1.0

' >>/opt/config/printer.base.cfg
    fi

    if [ -L /opt/klipper/klippy/extras/load_cell_tare.py ] || [ -f /opt/klipper/klippy/extras/load_cell_tare.py ]; then
        rm -f /opt/klipper/klippy/extras/load_cell_tare.py
    fi
    grep -q '^minimum_cruise_ratio' /opt/config/printer.base.cfg && sed -i 's|^minimum_cruise_ratio.*|max_accel_to_decel:5000|' /opt/config/printer.base.cfg

    rm -rf /data/.mod
    rm /etc/init.d/S00fix
    rm /etc/init.d/S99moon
    rm /etc/init.d/S98camera
    rm /etc/init.d/S98zssh
    rm /etc/init.d/K99moon
    rm -rf /opt/config/mod/
    # REMOVE SCRIPTS
    rm -rf /root/printer_data/scripts
    # REMOVE ENTWARE
    rm -rf /opt/bin
    rm -rf /opt/etc
    rm -rf /opt/home
    rm -rf /opt/lib
    rm -rf /opt/libexec
    rm -rf /opt/root
    rm -rf /opt/sbin
    rm -rf /opt/share
    rm -rf /opt/tmp
    rm -rf /opt/usr
    rm -rf /opt/var
}

start_moon()
{
    SWAP="/root/swap"
    if grep -q "use_swap = 2" /opt/config/mod_data/variables.cfg
        then
            for i in `seq 1 6`; do mount |grep /media && break; echo $i; sleep 10; done;

            if mount |grep /media
                then
                    FREE_SPACE=$(df /media 2>/dev/null|grep -v /dev/root|grep -v Filesystem| tail -1 | tr -s ' ' | cut -d' ' -f4)
                    MIN_SPACE=$((128*1024))
                    mount
                    df /media

                    if [ "$FREE_SPACE" != "" ] && [ "$FREE_SPACE" -ge "$MIN_SPACE" ]
                        then
                            SWAP="/media/swap"
                            if ! [ -f $SWAP ]; then dd if=/dev/zero of=$SWAP bs=1024 count=131072; mkswap $SWAP; fi;
                            swapon $SWAP
                    fi
            fi
    fi

    MACHINE="Неизвестная машина"
    grep -q '^MACHINE=Adventurer5MPro$' /opt/auto_run.sh && MACHINE=Adventurer5MPro
    grep -q '^MACHINE=Adventurer5M$' /opt/auto_run.sh && MACHINE=Adventurer5M
    VER=$(cat /root/version)
    chroot $MOD /opt/config/mod/.shell/root/start.sh "$SWAP" "$VER" "$MACHINE" &

    mkdir -p /data/lost+found
    sleep 10
    mount --bind /data/lost+found /data/.mod
    mount
    ps
    sleep 60
    umount /opt/klipper/start.sh
}

start_prepare()
{
    /opt/config/mod/.shell/znice.sh

    if [ -f /opt/config/mod/REMOVE ]
     then
      restore_base

      # Remove ROOT
      rm -rf /etc/init.d/S50sshd /etc/init.d/S55date /bin/dropbearmulti /bin/dropbear /bin/dropbearkey /bin/scp /etc/dropbear /etc/init.d/S60dropbear
      # Remove BEEP
      rm -f /usr/bin/audio.py /usr/bin/audio /usr/lib/python3.7/site-packages/audio.py /usr/bin/audio_midi.sh /opt/klipper/klippy/extras/gcode_shell_command.py
      rm -rf /usr/lib/python3.7/site-packages/mido/

      sync
      rm -f /etc/init.d/prepare.sh
      sync
      reboot
      exit
    fi

    if [ -f /opt/config/mod/FULL_REMOVE ]
     then
      restore_base

      # Remove ROOT
      rm -rf /etc/init.d/S50sshd /etc/init.d/S55date /bin/dropbearmulti /bin/dropbear /bin/dropbearkey /bin/scp /etc/dropbear /etc/init.d/S60dropbear
      # Remove BEEP
      rm -f /usr/bin/audio.py /usr/bin/audio /usr/lib/python3.7/site-packages/audio.py /usr/bin/audio_midi.sh /opt/klipper/klippy/extras/gcode_shell_command.py
      rm -rf /usr/lib/python3.7/site-packages/mido/

      sync
      rm -rf /opt/config/mod_data/
      rm -f /etc/init.d/prepare.sh
      sync
      reboot
      exit
    fi

    #/opt/config/mod/.shell/fix_config.sh
    [ -L /etc/init.d/S00fix ] || ln -s /opt/config/mod/.shell/fix_config.sh /etc/init.d/S00fix
    echo "System start" >/opt/config/mod_data/log/ssh.log
    mount -t proc /proc $MOD/proc
    mount --rbind /sys $MOD/sys
    mount --rbind /dev $MOD/dev

    mount --bind /tmp $MOD/tmp
    mount --bind /run $MOD/run

    mkdir -p $MOD/opt/config
    mount --bind /opt/config $MOD/opt/config

    mkdir -p $MOD/data
    mount --bind /data $MOD/data
#    mount --bind /mnt/usb $MOD/data/usb

#    mkdir -p $MOD/var/run/
#    mount --bind /var/run/ $MOD/var/run/

    mkdir -p $MOD/opt/PROGRAM/
    mount --bind /opt/PROGRAM/ $MOD/opt/PROGRAM/

    mkdir -p $MOD/root/printer_data/misc
    mkdir -p $MOD/root/printer_data/tmp
    mkdir -p $MOD/root/printer_data/comms
    mkdir -p $MOD/root/printer_data/certs

    if  ! [ -d $MOD/opt/klipper/docs ]
     then
        mkdir -p $MOD/opt/klipper/docs
        cp /opt/klipper/docs/* $MOD/opt/klipper/docs
    fi

    if ! [ -d $MOD/opt/klipper/config ]
     then
        mkdir -p $MOD/opt/klipper/config
        cp /opt/klipper/config/* $MOD/opt/klipper/config
    fi

    cat /etc/localtime >/tmp/localtime
    cp /opt/tslib-1.12/etc/pointercal /tmp/pointercal
    cp /opt/tslib-1.12/etc/ts.conf /tmp/ts.conf

    start_moon
}

if [ -f /opt/config/mod/SKIP_ZMOD ]
 then
    rm -f /opt/config/mod/SKIP_ZMOD
    mount --bind /data/lost+found /data/.mod
    exit 0
fi

while ! mount |grep /dev/mmcblk0p7; do sleep 10; done

mv /opt/config/mod_data/log/zmod.4.log /opt/config/mod_data/log/zmod.5.log
mv /opt/config/mod_data/log/zmod.3.log /opt/config/mod_data/log/zmod.4.log
mv /opt/config/mod_data/log/zmod.2.log /opt/config/mod_data/log/zmod.3.log
mv /opt/config/mod_data/log/zmod.1.log /opt/config/mod_data/log/zmod.2.log
mv /opt/config/mod_data/log/zmod.log /opt/config/mod_data/log/zmod.1.log
start_prepare &>/opt/config/mod_data/log/zmod.log
