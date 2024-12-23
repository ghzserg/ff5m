#!/bin/bash

apt update 
apt upgrade -y
apt install docker.io docker-compose docker su -y
systemctl enable docker
systemctl restart docker
useradd vasya
usermod -a -G docker vasya
su - vasya
mkdir bot1
cd bot1
curl -o docker-compose.yml https://raw.githubusercontent.com/ghzserg/ff5m/refs/heads/main/telegram/docker-compose.yml
mkdir -p config log timelapse_finished timelapse 
curl -o config/telegram.conf https://github.com/ghzserg/ff5m/raw/refs/heads/main/telegram/telegram.conf
chmod 777 config log timelapse_finished timelapse

echo "1. Идете к https://t.me/BotFather
2. /newbot
3. Вводите любое имя, которое вам нравится
4. Вводите имя бота например ff5msuper_bot - обязательно _bot в конце.
5. Получаете длинный ID - его нужно будет прописать в настройках бота в параметр bot_token"
read bot_token -p "Введите bot_token":

sed -i "s|bot_token: 1111111111:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA|bot_token: ${bot_token}|" config/telegram.conf 
docker-compose up -d

echo "Заходите в своего бота, через телеграм
Он напишет. Unauthorized access detected with chat_id:
Впишите полученное числю в chat_id"

read chat_id -p "Введите chat_id":
docker-compose down
sed -i "s|chat_id: 111111111|chat_id: ${chat_id}|" config/telegram.conf 
docker-compose up -d