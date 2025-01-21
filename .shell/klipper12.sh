#!/bin/sh

unset LD_LIBRARY_PATH
unset LD_PRELOAD

klipper12()
{
    MOD=/data/.mod/.zmod
    /usr/sbin/chroot $MOD /opt/config/mod/.shell/root/S60klipper start
}

mv /opt/config/mod_data/log/klipper12.log.4 /opt/config/mod_data/log/klipper12.log.5
mv /opt/config/mod_data/log/klipper12.log.3 /opt/config/mod_data/log/klipper12.log.4
mv /opt/config/mod_data/log/klipper12.log.2 /opt/config/mod_data/log/klipper12.log.3
mv /opt/config/mod_data/log/klipper12.log.1 /opt/config/mod_data/log/klipper12.log.2
mv /opt/config/mod_data/log/klipper12.log /opt/config/mod_data/log/klipper12.log.1

klipper12 "$1" &>/opt/config/mod_data/log/klipper12.log
