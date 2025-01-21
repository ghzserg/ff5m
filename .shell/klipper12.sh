#!/bin/sh

exit 0
unset LD_LIBRARY_PATH
unset LD_PRELOAD

klipper12()
{
    mount
    ps
    MOD=/data/.mod/.zmod
    if mount|grep " /data/.mod "; then
        umount /data/.mod
        /usr/sbin/chroot $MOD /opt/config/mod/.shell/root/S60klipper start
        sleep 10
        mount --bind /data/lost+found /data/.mod
    else
        /usr/sbin/chroot $MOD /opt/config/mod/.shell/root/S60klipper start
    fi
    mount
    ps
}

mv /opt/config/mod_data/log/klipper12.log.4 /opt/config/mod_data/log/klipper12.log.5
mv /opt/config/mod_data/log/klipper12.log.3 /opt/config/mod_data/log/klipper12.log.4
mv /opt/config/mod_data/log/klipper12.log.2 /opt/config/mod_data/log/klipper12.log.3
mv /opt/config/mod_data/log/klipper12.log.1 /opt/config/mod_data/log/klipper12.log.2
mv /opt/config/mod_data/log/klipper12.log /opt/config/mod_data/log/klipper12.log.1

klipper12 "$1" &>/opt/config/mod_data/log/klipper12.log
