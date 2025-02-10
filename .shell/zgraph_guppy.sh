#!/bin/sh

MOD=/data/.mod/.zmod

unset LD_PRELOAD

if ! [ -f /THIS_IS_NOT_YOUR_ROOT_FILESYSTEM ]; then
    /opt/config/mod/.shell/root/.shell/zshaper/graph_belts.py $@
else
    umount /data/.mod/
    chroot $MOD /opt/config/mod/.shell/root/.shell/zshaper/graph_belts.py $@
    mount --bind /data/lost+found /data/.mod
fi
