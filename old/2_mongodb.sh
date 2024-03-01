#!/bin/bash

# https://computingforgeeks.com/how-to-install-mongodb-database-on-ubuntu/ 참고하여 작성함.


BINDIP="192.168.0.173"

echo "<<<<<<<<<<<<<<<<<<<< Append mongodb motd >>>>>>>>>>>>>>>>>>>>>>"
sudo tee -a /etc/motd<<EOF
********************************************************************
devel 서버의 데이터를 저장하기 위한 mongodb 서버

<< mongodb 5.0 installed >>
configure file /etc/mongod.conf
data directory /var/lib/mongodb
log directory /var/log/mongodb

ex) mongodb://${BINDIP}:27017

EOF

echo "<<<<<<<<<< Step 1: Import MongoDB GPG Key >>>>>>>>>>>>>>>"
sudo apt update
sudo apt install -y wget curl gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release


curl -fsSL https://www.mongodb.org/static/pgp/server-5.0.asc|sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/mongodb.gpg

echo "<<<<<<<<<< Step 2: Add MongoDB Repository on Ubuntu >>>>>>>>>>>>>>>"
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list

echo "<<<<<<<<<< Step 3: Install MongoDB 5.0 on Ubuntu >>>>>>>>>>>>>>>"
sudo apt update
sudo apt install -y mongodb-org


# 방화벽 설정
sudo ufw allow 27017
# bindIp의 의미는 접속을 원하는 클라이언트 주소가 아닌 서버의 아이피주소를 설정하는 것이다.
# 따라서 웹에서 설정하는 다수의 멀티플설정법은 에러가 발생한다.
sudo sed -i "s/bindIp: 127.0.0.1/bindIp: ${BINDIP}/" /etc/mongod.conf

sudo systemctl start mongod
sudo systemctl enable mongod
sudo systemctl status mongod

echo '**Set up bindIp in /etc/mongod.conf and ufw for remote access.'
