#!/bin/sh

echo "Началась проверка. Она может занять много времени...."
cd /
find . -name md5sum.list | while read a; do b=$(pwd); c=$(echo $a|sed 's/md5sum.list//'); echo "$c"; md5sum -c md5sum.list --quiet; cd "$b"; done
md5sum -c /opt/config/mod/.shell/md5sum.list --quiet || echo "Найдены ошибки. Оригиналы файлов можно найти по ссылке https://github.com/ghzserg/zmod/tree/main/stock"
