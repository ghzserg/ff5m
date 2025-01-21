#!/bin/sh

set -x

MOD=/data/.mod/.zmod

ns_off()
{
    grep -q "$1" /etc/hosts && sed -i "|$1|d" /etc/hosts
}

restore_base()
{
    grep -q '^\[include mod.user.cfg' /opt/config/printer.cfg && sed -i '|include mod.user.cfg|d' /opt/config/printer.cfg
    grep -q '^\[include ./mod/mod.cfg' /opt/config/printer.cfg && sed -i '|include mod.cfg|d' /opt/config/printer.cfg
    grep -q '^\[include ./mod/display_off.cfg' /opt/config/printer.cfg && sed -i '|display_off.cfg|d' /opt/config/printer.cfg

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

    grep -q ZLOAD_VARIABLE /opt/klipper/klippy/extras/save_variables.py && cp /opt/config/mod/.shell/save_variables.py.orig /opt/klipper/klippy/extras/save_variables.py

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
pause_on_runout: False
switch_pin: !PB14
event_delay: 1.0
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
pin:PB7
' >>/opt/config/printer.base.cfg
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

    VER=$(cat /root/version)
    chroot $MOD /opt/config/mod/.shell/root/start.sh "$SWAP" "$VER" &

    mkdir -p /data/lost+found
    sleep 10
    mount --bind /data/lost+found /data/.mod
    mount
    ps
}

start_prepare()
{
    if [ -f /opt/config/mod/REMOVE ]
     then
      restore_base

      # Remove ROOT
      rm -rf /etc/init.d/S50sshd /etc/init.d/S55date /bin/dropbearmulti /bin/dropbear /bin/dropbearkey /bin/scp /etc/dropbear /etc/init.d/S60dropbear
      # Remove BEEP
      rm -f /usr/bin/audio /usr/lib/python3.7/site-packages/audio.py /usr/bin/audio_midi.sh /opt/klipper/klippy/extras/gcode_shell_command.py
      rm -rf /usr/lib/python3.7/site-packages/mido/

      sync
      rm -f /etc/init.d/prepare.sh
      sync
      reboot
      exit
    fi

    if [ -f /opt/config/mod/SOFT_REMOVE ]
     then
      restore_base

      sync
      rm -f /etc/init.d/prepare.sh
      sync
      reboot
      exit
    fi

    #/opt/config/mod/.shell/fix_config.sh
    [ -L /etc/init.d/S00fix ] || ln -s /opt/config/mod/.shell/fix_config.sh /etc/init.d/S00fix
    echo "System start" >/data/logFiles/ssh.log
    mount -t proc /proc $MOD/proc
    mount --rbind /sys $MOD/sys
    mount --rbind /dev $MOD/dev

    mount --bind /tmp $MOD/tmp
    mount --bind /run $MOD/run

    mkdir -p $MOD/opt/config
    mount --bind /opt/config $MOD/opt/config

    mkdir -p $MOD/data
    mount --bind /data $MOD/data

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

    if [ "$1" == "moon" ]; then
        start_moon
    fi
}

start_program()
{
    if grep -q "klipper12 = 1" /opt/config/mod_data/variables.cfg; then
        echo "Работа в режиме Klipper 12"
        if [ "$1" == "moon" ]; then
            echo "Запуск moonraker"
            renice -18 $(ps |grep klippy.py| grep -v grep| awk '{print $1}')
            start_moon
        else
            echo "Подготовка к запуску Klipper 12"
            start_prepare klipper
        fi
    else
        echo "Работа в режиме родного Klipper"
        echo "Запуск moonraker"
        start_prepare moon
    fi
}

if [ -f /opt/config/mod/SKIP_ZMOD ]
 then
    rm -f /opt/config/mod/SKIP_ZMOD
    mount --bind /data/lost+found /data/.mod
    exit 0
fi

while ! mount |grep /dev/mmcblk0p7; do sleep 10; done

mv /data/logFiles/zmod.log.4 /data/logFiles/zmod.log.5
mv /data/logFiles/zmod.log.3 /data/logFiles/zmod.log.4
mv /data/logFiles/zmod.log.2 /data/logFiles/zmod.log.3
mv /data/logFiles/zmod.log.1 /data/logFiles/zmod.log.2
mv /data/logFiles/zmod.log /data/logFiles/zmod.log.1
start_program $1 &>/data/logFiles/zmod.log
