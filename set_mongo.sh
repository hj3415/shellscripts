#!/bin/bash

# mongodb 설치 및 설정

ID="hj3415"
PASS="piyrw421"
PORT="27017"
MYIP=`hostname -I | cut -d ' ' -f1`

echo "***********************************************************************"
echo "*                      Install MongoDB                          *"
echo "***********************************************************************"

# install docker compose
sudo apt update
sudo apt install -y docker-compose-plugin

docker compose version

# 필요한 기본 디렉토리 생성
rm -rf ${HOME}/setup_mongo
mkdir ${HOME}/setup_mongo; cd $_

tee ${HOME}/setup_mongo/mongod.conf<<EOF
storage:
  dbPath: /data/db

systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log


net:
  bindIp: 0.0.0.0
  port: ${PORT}

processManagement:
  timeZoneInfo: /usr/share/zoneinfo

security:
  authorization: enabled
EOF

tee ${HOME}/setup_mongo/docker-compose.yml<<EOF
# Use root/example as user/password credentials
services:
  mongo:
    image: mongo:latest
    container_name: mongodb
    ports:
      - "${PORT}:27107"
    volumes:
      - mongo-data:/data/db
      - ${HOME}/setup_mongo/mongod.conf:/etc/mongod.conf
    restart: always
    environment:
      MONGO_INITDB_ROOT_USERNAME: ${ID}
      MONGO_INITDB_ROOT_PASSWORD: ${PASS}
    command: ["mongod", "--config", "/etc/mongod.conf"]
    network_mode: host

volumes:
  mongo-data:
    external: true
EOF

# 이미지 최신버전으로 교체
docker stop mongo
docker rm mongo
docker pull mongo

docker volume create mongo-data
docker compose up -d
cd ..

# Open firewall
sudo ufw allow ${PORT}

bash ${HOME}/tools/making_motd.sh mongo \
  "addr - mongodb://${ID}:${PASS}@${MYIP}:${PORT}/"
  
