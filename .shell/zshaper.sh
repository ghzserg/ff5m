#!/bin/sh

MOD=/data/.mod/.zmod

unset LD_PRELOAD

if grep -q "klipper12 = 1" /opt/config/mod_data/variables.cfg; then
    /opt/config/mod/.shell/root/zshaper.sh
else
    umount /data/.mod/
    chroot $MOD /opt/config/mod/.shell/root/zshaper.sh
    mount --bind /data/lost+found /data/.mod
fi
