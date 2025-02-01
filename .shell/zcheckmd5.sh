#!/bin/sh

echo "Началась проверка. Она может занять много времени...."

find /opt/PROGRAM/ -name md5sum.list | while read a;
    do
        b=$(pwd)
        c=$(echo $a|sed 's/md5sum.list//')
        echo "$c"
        cd "$c"
        if echo $c | grep -q control; then
            touch Update
        fi
        md5sum -c md5sum.list 2>/dev/null | grep -v -e "OK$"
        if echo $c | grep -q control; then
            rm -f Update
        fi
        cd "$b"
    done

echo "/"
cd /
FF_VERSION="$(cat /root/version)"
MIN_VERSION="3.1.3"
if [ "${FF_VERSION//./}" -lt "${MIN_VERSION//./}" ]; then
    sed '/\/nim\//d' /opt/config/mod/.shell/md5sum.list >/opt/config/mod/.shell/md5sum_nim.list
    md5sum -c /opt/config/mod/.shell/md5sum_nim.list 2>/dev/null | grep -v -e "OK$"
    rm -f /opt/config/mod/.shell/md5sum_nim.list
else
    md5sum -c /opt/config/mod/.shell/md5sum.list 2>/dev/null | grep -v -e "OK$"
fi

echo "Проверка символических ссылок"
/opt/config/mod/.shell/list.link 2>/dev/null

echo "Оригиналы файлов можно найти по ссылке https://github.com/ghzserg/zmod/tree/main/stock"
