#!/bin/sh

unset LD_LIBRARY_PATH
unset LD_PRELOAD

MOD=/data/.mod/.zmod

chroot $MOD /opt/config/mod/.shell/root/S60klipper start
