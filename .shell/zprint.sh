#!/bin/bash

# "lanCode"
# "printerSerialNumber"
# Adventurer5M.json

if [ $# -ne 2 ] && [ $# -ne 3 ]; then echo "Используйте $0 PRINT|CLOSE FILE [PRECLEAR]"; exit 1; fi

if ! [ -f /THIS_IS_NOT_YOUR_ROOT_FILESYSTEM ]; then
    CURL="/usr/bin/curl"
else
    CURL="/opt/cloud/curl-7.55.1-https/bin/curl"
fi

ip=$(ip addr | grep inet | grep wlan0 | awk -F" " '{print $2}'| sed -e 's/\/.*$//')
if [ "$ip" == "" ]; then ip=$(ip addr | grep inet | grep eth0 | awk -F" " '{print $2}'| sed -e 's/\/.*$//'); fi

serialNumber=$(cat /opt/config/Adventurer5M.json | grep "printerSerialNumber"| cut  -d ":" -f2| awk '{print $1}' | sed 's|[",]||g')
checkCode=$(cat /opt/config/Adventurer5M.json | grep "lanCode"| cut  -d ":" -f2| awk '{print $1}' | sed 's|[",]||g')

if [ "$1" == "CLOSE" ]
    then
        $CURL -m 60 -s \
        http://$ip:8898/control \
        -H 'Content-Type: application/json' \
        -d "{\"serialNumber\":\"$serialNumber\",\"checkCode\":\"$checkCode\",\"payload\":{\"cmd\":\"stateCtrl_cmd\",\"args\":{\"action\":\"setClearPlatform\"}}}" || \
        echo "Нет ответа от принтера с IP $ip. Необходимо настроить принтер. На экране принтера: \"Настройки\" -> \"Иконка WiFi\" -> \"Сетевой режим\" -> включить ползунок \"Только локальные сети\""
else
    if [ "$1" == "PRINT" ]
        then
            M109=$(head -1000 "/data/$2" | grep "^M109" | head -1)
            [ "$M109" == "" ] && M109=$(head -1000 "/data/$2" | grep "^M104" | head -1 | sed 's|M104|M109|')
            M190=$(head -1000 "/data/$2" | grep "^M190" | head -1)
            [ "$M190" == "" ] && M190=$(head -1000 "/data/$2" | grep "^M140" | head -1 | sed 's|M140|M190|')

            if [ "$M190" == "" ] || [ "$M109" == "" ]
                then
                    echo "RESPOND TYPE=error MSG=\"В файле $2 не найдены команды нагрева стола(M140/M190) или сопла(M104/M109).\"" >/tmp/printer
                    exit 1
            fi

            if [ "$3" == "PRECLEAR" ]
                then
                    echo "$M190" >/tmp/printer
                    echo "$M109" >/tmp/printer
                    echo "_START_PRECLEAR" >/tmp/printer
                    echo "RUN_SHELL_COMMAND CMD=zprint PARAMS=\"PRINT '$2'\"">/tmp/printer
                else
                    echo "EXCLUDE_OBJECT_DEFINE RESET=1" >/tmp/printer 2>/dev/null
                    head -1000 "/data/$2" | grep ^EXCLUDE_OBJECT_DEFINE >/tmp/printer 2>/dev/null

                    $CURL -m 60 -s \
                        http://$ip:8898/printGcode \
                        -H 'Content-Type: application/json' \
                        -d "{\"serialNumber\":\"$serialNumber\",\"checkCode\":\"$checkCode\",\"fileName\":\"$2\",\"levelingBeforePrint\":true}'" || \
                        echo "Нет ответа от принтера с IP $ip. Необходимо настроить принтер. На экране принтера: \"Настройки\" -> \"Иконка WiFi\" -> \"Сетевой режим\" -> включить ползунок \"Только локальные сети\""
            fi
        else
            echo "Используйте $0 PRINT|CLOSE FILE [PRECLEAR]"
            exit 1
    fi
fi
