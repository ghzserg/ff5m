#!/bin/bash

cp -a "$1" "../stock/$1"
a=$(readlink "$1")
echo "if [ \"\$(readlink '$1')\" != \"$a\" ]; then echo -n \"$1 - Ошибочная ссылка: \"; rm -f \"$1\"; ln -s \"$a\" \"$1\" && echo \"Исправлено\"; fi"
