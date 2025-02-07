#!/bin/sh

if ! [ $# -eq 1 ]; then echo "Use $0 on|off|test"; exit 1; fi

if [ $1 = "test" ] && grep -q display_off.cfg /opt/config/printer.cfg; then
    killall firmwareExe
    grep -q "guppi = 1" /opt/config/mod_data/variables.cfg && /opt/config/.shell/zguppi.sh start || xzcat /opt/config/mod/.shell/screen_off.raw.xz > /dev/fb0
fi

[ $1 = "on" ]   && sed -i 's|\[include ./mod/display_off.cfg\]|\[include ./mod/mod.cfg\]|' /opt/config/printer.cfg && sync && reboot
[ $1 = "off" ]  && sed -i 's|\[include ./mod/mod.cfg\]|\[include ./mod/display_off.cfg\]|' /opt/config/printer.cfg && sync && killall firmwareExe && xzcat /opt/config/mod/.shell/screen_off.raw.xz > /dev/fb0
[ $1 = "guppi" ]  && sed -i 's|\[include ./mod/mod.cfg\]|\[include ./mod/display_off.cfg\]|' /opt/config/printer.cfg && sync && killall firmwareExe && /opt/config/.shell/zguppi.sh start

sync
echo 3 > /proc/sys/vm/drop_caches
