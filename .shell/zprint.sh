#!/bin/bash

# "lanCode"
# "printerSerialNumber"
# Adventurer5M.json

if [ $# -ne 2 ]; then echo "Используйте $0 PRINT|CLOSE FILE"; exit 1; fi

if ! [ -f /THIS_IS_NOT_YOUR_ROOT_FILESYSTEM ]; then
    CURL="/usr/bin/curl"
else
    CURL="/opt/cloud/curl-7.55.1-https/bin/curl"
fi

ip=$(ip addr | grep inet | grep wlan0 | awk -F" " '{print $2}'| sed -e 's/\/.*$//')
if [ "$ip" == "" ]; then ip=$(ip addr | grep inet | grep eth0 | awk -F" " '{print $2}'| sed -e 's/\/.*$//'); fi

serialNumber=$(cat /opt/config/Adventurer5M.json | grep "printerSerialNumber"| cut  -d ":" -f2| awk '{print $1}' | sed 's|[",]||g')
checkCode=$(cat /opt/config/Adventurer5M.json | grep "lanCode"| cut  -d ":" -f2| awk '{print $1}' | sed 's|[",]||g')

if [ "$1" == "CLOSE" ]; then
    $CURL -m 60 -s \
        http://$ip:8898/control \
        -H 'Content-Type: application/json' \
        -d "{\"serialNumber\":\"$serialNumber\",\"checkCode\":\"$checkCode\",\"payload\":{\"cmd\":\"stateCtrl_cmd\",\"args\":{\"action\":\"setClearPlatform\"}}}" || \
    echo "Нет ответа от принтера с IP $ip. Необходимо настроить принтер. На экране принтера: \"Настройки\" -> \"Иконка WiFi\" -> \"Сетевой режим\" -> включить ползунок \"Только локальные сети\""
else
    if [ "$1" == "PRINT" ]; then
        if ! [ -f "/data/$2" ]; then
            echo "RESPOND TYPE=error MSG=\"Файл $2 не найден.\"" >/tmp/printer
            echo "CANCEL_PRINT" >/tmp/printer
            exit 1
        fi

        $CURL -m 60 -s \
            http://$ip:8898/printGcode \
            -H 'Content-Type: application/json' \
            -d "{\"serialNumber\":\"$serialNumber\",\"checkCode\":\"$checkCode\",\"fileName\":\"$2\",\"levelingBeforePrint\":true}'" || \
            echo "Нет ответа от принтера с IP $ip. Необходимо настроить принтер. На экране принтера: \"Настройки\" -> \"Иконка WiFi\" -> \"Сетевой режим\" -> включить ползунок \"Только локальные сети\""
    else
        echo "Используйте $0 PRINT|CLOSE FILE [PRECLEAR]"
        exit 1
    fi
fi
