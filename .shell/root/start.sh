#!/bin/sh

prepare_chroot()
{
    mv /tmp/localtime /etc/localtime

    mv /tmp/pointercal /etc/pointercal
    mv /tmp/ts.conf /etc/ts.conf

    [ -f /root/guppyscreen/guppyscreen ] || ln /bin/guppyscreen /root/guppyscreen/guppyscreen

    [ -L /root/printer_data/scripts ] || ln -s /opt/config/mod/.shell /root/printer_data/scripts

    [ -L /root/klipper-env/lib/python3.11/site-packages/numpy ] || ln -s /usr/lib/python3.11/site-packages/numpy /root/klipper-env/lib/python3.11/site-packages/

    [ -d /etc/init.d/ ] || mkdir -p /etc/init.d/

    [ -L /etc/init.d/S98zssh ] || ln -s /opt/config/mod/.shell/S98zssh /etc/init.d/
    [ -L /etc/init.d/S98camera ] || ln -s /opt/config/mod/.shell/S98camera /etc/init.d/

    [ -L /etc/init.d/S35tslib ] || ln -s /opt/config/mod/.shell/root/S35tslib /etc/init.d/
    [ -L /etc/init.d/S80guppyscreen ] || ln -s /opt/config/mod/.shell/root/S80guppyscreen /etc/init.d/

    [ -L /etc/init.d/S60klipper ] || ln -s /opt/config/mod/.shell/root/S60klipper /etc/init.d/
    [ -L /etc/init.d/S65moonraker ] || ln -s /opt/config/mod/.shell/root/S65moonraker /etc/init.d/
    [ -L /etc/init.d/S70httpd ] || ln -s /opt/config/mod/.shell/root/S70httpd /etc/init.d/

    [ -L /usr/lib/python3.11/site-packages/mido ] || ln -s /opt/config/mod/.shell/root/mido/ /usr/lib/python3.11/site-packages/
    [ -L /usr/lib/python3.11/site-packages/mido-1.3.3.dist-info ] || ln -s /opt/config/mod/.shell/root/mido-1.3.3.dist-info/ /usr/lib/python3.11/site-packages/

    [ -L /usr/bin/audio ] || ln -s /opt/config/mod/.shell/root/audio/audio /usr/bin/audio
    [ -L /usr/bin/audio_midi.sh ] || ln -s /opt/config/mod/.shell/root/audio/audio_midi.sh /usr/bin/audio_midi.sh
    [ -L /usr/bin/audio.py ] || ln -s /opt/config/mod/.shell/root/audio/audio.py /usr/bin/audio.py

    [ -L /bin/boot_eboard_mcu] || ln -s /opt/config/mod/.shell/root/mcu/boot_eboard_mcu /bin/boot_eboard_mcu
}

SWAP="$1"
echo "SWAP=$SWAP"

if ! [ -f /root/swap ]; then dd if=/dev/zero of=/root/swap bs=1024 count=131072; mkswap /root/swap; fi;

if [ "$SWAP" == "/root/swap" ]
    then
        grep -q "use_swap = 0" /opt/config/mod_data/variables.cfg || swapon $SWAP
fi

prepare_chroot

rm -f /root/guppyscreen/guppyconfig.json
ln -s /opt/config/mod_data/guppyconfig.json /root/guppyscreen/guppyconfig.json

if [ "$3" == "Adventurer5M" ]; then
    [ -f /opt/config/mod_data/guppyconfig.json ] || cp /opt/config/mod/guppyconfig.json /opt/config/mod_data/guppyconfig.json
fi
if [ "$3" == "Adventurer5MPro" ]; then
    [ -f /opt/config/mod_data/guppyconfig.json ] || cp /opt/config/mod/guppyconfig_pro.json /opt/config/mod_data/guppyconfig.json
fi

VER="$3 $2"
grep -q VERSION_CODENAME /etc/os-release || echo "VERSION_CODENAME=\"${VER}\"" >>/etc/os-release
grep -q "VERSION_CODENAME=\"${VER}\"" /etc/os-release || sed -i "s|VERSION_CODENAME=.*|VERSION_CODENAME=\"${VER}\"|" /etc/os-release

V1=$(cat /etc/os-release|grep PRETTY_NAME| cut  -d '"' -f2| awk '{print $1" "$2}')
V2=$(cat /opt/config/mod/version.txt)

grep -q PRETTY_NAME /etc/os-release || echo "VERSION_CODENAME=\"${V1} -> ${V2}\"" >>/etc/os-release
grep -q "PRETTY_NAME=\"${V1} -> ${V2}\"" /etc/os-release || sed -i "s|PRETTY_NAME=.*|PRETTY_NAME=\"${V1} -> ${V2}\"|" /etc/os-release

mkdir -p /data/tmp

mount --bind /data/lost+found /data/.mod

if grep -q "klipper12 = 1" /opt/config/mod_data/variables.cfg; then
    /opt/config/mod/.shell/root/S60klipper start
fi

date 2024.01.01-00:00:00

# Пробуем синхронизировать время
ntpd -dd -n -q -p ru.pool.ntp.org || \
ntpd -dd -n -q -p 1.ru.pool.ntp.org || \
ntpd -dd -n -q -p 2.ru.pool.ntp.org || \
ntpd -dd -n -q -p 3.ru.pool.ntp.org || \
ntpd -dd -n -q -p 4.ru.pool.ntp.org || \
ntpd -dd -n -q -p ntp1.vniiftri.ru || \
ntpd -dd -n -q -p ntp2.vniiftri.ru || \
ntpd -dd -n -q -p ntp3.vniiftri.ru || \
ntpd -dd -n -q -p ntp4.vniiftri.ru || \
ntpd -dd -n -q -p ntp5.vniiftri.ru || \
ntpd -dd -n -q -p ntp.sstf.nsk.ru || \
ntpd -dd -n -q -p timesstf.sstf.nsk.ru || \
ntpd -dd -n -q -p ntp.kam.vniiftri.net

/opt/config/mod/.shell/root/S65moonraker start
/opt/config/mod/.shell/root/S70httpd start

test_file()
{
    DIR="/opt/config/mod_data/save"
    DT=$(date '+%Y%m%d_%H%M')

    mkdir -p $DIR

    if ! [ -f "$DIR/$1" ] || ! diff -q /opt/config/$1 "$DIR/$1"; then
        cp /opt/config/$1 "$DIR/$1"
        cp /opt/config/$1 "$DIR/$1.$DT.cfg"
    fi
}

test_file printer.base.cfg
test_file printer.cfg

sleep 15
cd /opt/config/mod/
git log | head -3|grep Date >/opt/config/mod_data/date.txt
echo "ZSSH_RELOAD" >/tmp/printer

# 10 минут пробуем получить время
for i in `seq 0 50`
    do 
        ntpd -dd -n -q -p ru.pool.ntp.org && break
        ntpd -dd -n -q -p 1.ru.pool.ntp.org && break
        ntpd -dd -n -q -p 2.ru.pool.ntp.org && break
        ntpd -dd -n -q -p 3.ru.pool.ntp.org && break
        ntpd -dd -n -q -p 4.ru.pool.ntp.org && break
        ntpd -dd -n -q -p ntp1.vniiftri.ru && break
        ntpd -dd -n -q -p ntp2.vniiftri.ru && break
        ntpd -dd -n -q -p ntp3.vniiftri.ru && break
        ntpd -dd -n -q -p ntp4.vniiftri.ru && break
        ntpd -dd -n -q -p ntp5.vniiftri.ru && break
        ntpd -dd -n -q -p ntp.sstf.nsk.ru && break
        ntpd -dd -n -q -p timesstf.sstf.nsk.ru && break
        ntpd -dd -n -q -p ntp.kam.vniiftri.net && break
        sleep 5
done
date
echo "Start END"
