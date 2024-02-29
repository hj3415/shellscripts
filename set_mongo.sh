#!/bin/bash

# mongodb 설치 및 설정

echo "***********************************************************************"
echo "*                      Install MongoDB                          *"
echo "***********************************************************************"

ID="hj3415"
PASS="piyrw421"
PORT="27017"
EXPRESS_PORT="8081"
DATA_PATH="${HOME}/mongo_data"

MYIP=`hostname -I | cut -d ' ' -f1`

# install docker compose
sudo apt update
sudo apt install -y docker-compose-plugin

docker compose version

# 필요한 기본 디렉토리 생성
echo ">>> Do you want to reset mongodb directory?(${DATA_PATH}) (y/N)"
read answer
if [[ ${answer} == 'y' ]];then
sudo rm -rf ${DATA_PATH}
fi
mkdir -p ${DATA_PATH}

rm -rf setup_mongo
mkdir setup_mongo; cd $_

tee docker-compose.yml<<EOF
# Use root/example as user/password credentials
version: '3'

services:

  mongo:
    image: mongo
    container_name: mongo
    ports:
      - ${PORT}:27107
    volumes:
      - ${DATA_PATH}:/data
    restart: always
    environment:
      MONGO_INITDB_ROOT_USERNAME: ${ID}
      MONGO_INITDB_ROOT_PASSWORD: ${PASS}

  mongo-express:
    image: mongo-express
    container_name: mongo-express
    restart: always
    ports:
      - ${EXPRESS_PORT}:8081
    environment:
      ME_CONFIG_BASICAUTH_USERNAME: ${ID}
      ME_CONFIG_BASICAUTH_PASSWORD: ${PASS}
      ME_CONFIG_MONGODB_ADMINUSERNAME: ${ID}
      ME_CONFIG_MONGODB_ADMINPASSWORD: ${PASS}
      ME_CONFIG_MONGODB_URL: mongodb://${ID}:${PASS}@mongo:${PORT}/
networks:
  default:
    name: mongodb_network
EOF

# 이미지 최신버전으로 교체
docker stop mongo
docker stop mongo-express

docker rm mongo
docker rm mongo-express

# 이미지 다시 생성
docker pull mongo
docker pull mongo-express

docker compose up -d
cd ..

# Open firewall
sudo ufw allow ${PORT}
sudo ufw allow ${EXPRESS_PORT}

bash ./tools/making_motd.sh mongo \
  "web access by mongo_express - http://${MYIP}:${EXPRESS_PORT}" \
  "ID - ${ID}, PASS - ${PASS}" \
  "원격 접속은 불가능함." \
  "data - ${DATA_PATH}"
