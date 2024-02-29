#!/bin/bash

# redis 설치 및 설정

UID=`id -u`
GID=`id -g`
PORT="6379"

echo "***********************************************************************"
echo "*                      Install Redis                          *"
echo "***********************************************************************"

# install docker compose
sudo apt update
sudo apt install -y docker-compose-plugin redis-tools

docker compose version

# 필요한 기본 디렉토리 생성
echo ">>> Do you want to reset redis directory?(!!contents could be deleted!!) (Y/n)"
read answer
if [[ ${answer} == 'y' ]];then
sudo rm -rf redis/{data,conf}
fi
mkdir -p redis/{data,conf}

rm -rf setup_redis
mkdir setup_redis; cd $_

tee docker-compose.yml<<EOF
version: "3.1"

services:
  redis_container:
    image: redis:latest
    container_name: redis
    environment:
      - PUID=${UID}
      - PGID=${GID}
    ports:
      - ${PORT}:6379
    volumes:
      - ${HOME}/redis/data:/data
      - ${HOME}/redis/conf/redis.conf:/usr/local/conf/redis.conf
    labels:
      - "name=redis"
      - "mode=standalone"
    restart: always
    command: redis-server /usr/local/conf/redis.conf
EOF

# 이전 이미지 삭제
docker stop redis

docker rm redis

# 이미지 다시 생성
docker pull redis:latest

docker compose up -d
cd ..
sudo chown -R ${UID}:${GID} ${HOME}/redis/data

# Open firewall
sudo ufw allow ${PORT}/tcp

bash ./tools/making_motd.sh redis \
  "redis working directory - ${HOME}/redis/data" \
  "port - ${PORT}"
