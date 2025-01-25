#!/bin/sh
# Author:		chenhe
# Date:			2022-01-21

set -x

WORK_DIR=`dirname $0`

cp /opt/config/mod/.shell/root/mcu/Mainboard.bin $WORK_DIR

FIRMWARE_Board_M3=Mainboard.bin
FIRMWARE_Head_M3=/opt/config/mod/.shell/root/mcu/Eboard.hex

CHECH_ARCH=`uname -m`
if [ "${CHECH_ARCH}" != "armv7l" ];then
    echo "Machine architecture error."
    echo ${CHECH_ARCH}
    exit 1
fi

cat $WORK_DIR/mcu.img > /dev/fb0

update_mcu()
{
    if [ -f $WORK_DIR/NationsCommand ];then
	chmod a+x $WORK_DIR/NationsCommand
	if [ -f $FIRMWARE_Board_M3 ];then
		echo "burn M3 firmware..."
		$WORK_DIR/NationsCommand -c -d --fn $FIRMWARE_Board_M3 --v -r
	fi
    fi

    if [ -f $WORK_DIR/IAPCommand ];then
	chmod a+x $WORK_DIR/IAPCommand
	if [ -f $FIRMWARE_Head_M3 ];then
		echo "burn M3 firmware..."
		$WORK_DIR/IAPCommand $FIRMWARE_Head_M3 /dev/ttyS1
		sync
	fi
    fi
}

mkdir -p /opt/config/mod_data/log/

mv /opt/config/mod_data/log/update_mcu.log.4 /opt/config/mod_data/log/update_mcu.log.5
mv /opt/config/mod_data/log/update_mcu.log.3 /opt/config/mod_data/log/update_mcu.log.4
mv /opt/config/mod_data/log/update_mcu.log.2 /opt/config/mod_data/log/update_mcu.log.3
mv /opt/config/mod_data/log/update_mcu.log.1 /opt/config/mod_data/log/update_mcu.log.2
mv /opt/config/mod_data/log/update_mcu.log /opt/config/mod_data/log/update_mcu.log.1

update_mcu &>/opt/config/mod_data/log/update_mcu.log

exit 0
