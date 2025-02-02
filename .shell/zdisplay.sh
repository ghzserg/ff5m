#!/bin/sh

if ! [ $# -eq 1 ]; then echo "Use $0 on|off|test"; exit 1; fi

[ $1 = "test" ] && grep -q display_off.cfg /opt/config/printer.cfg && killall firmwareExe && xzcat /opt/config/mod/.shell/screen_off.raw.xz > /dev/fb0
[ $1 = "on" ]   && sed -i 's|\[include ./mod/display_off.cfg\]|\[include ./mod/mod.cfg\]|' /opt/config/printer.cfg && sync && reboot
[ $1 = "off" ]  && sed -i 's|\[include ./mod/mod.cfg\]|\[include ./mod/display_off.cfg\]|' /opt/config/printer.cfg && sync && killall firmwareExe && xzcat /opt/config/mod/.shell/screen_off.raw.xz > /dev/fb0

sync
echo 3 > /proc/sys/vm/drop_caches
