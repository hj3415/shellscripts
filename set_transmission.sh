#!/bin/bash

# transmission 설치 및 설정

echo "***********************************************************************"
echo "*                      Install Transmission                          *"
echo "***********************************************************************"

ID="hj3415"
PASS="piyrw421"
PORT="9091"
MYIP=`hostname -I | cut -d ' ' -f1`

UID=`id -u`
GID=`id -g`

# install docker compose
sudo apt update
sudo apt install -y docker-compose-plugin

docker compose version

# 필요한 기본 디렉토리 생성
echo ">>> Do you want to reset transmission directory?(!!contents could be deleted!!) (y/N)"
read answer
if [[ ${answer} == 'y' ]];then
sudo rm -rf transmission/{config,downloads,watch}
fi
mkdir -p transmission/{config,downloads,watch}

rm -rf setup_transmission
mkdir setup_transmission; cd $_

tee docker-compose.yml<<EOF
services:
  transmission:
    image: lscr.io/linuxserver/transmission:latest
    container_name: transmission
    environment:
      - PUID=${UID}
      - PGID=${GID}
      - TZ=Asia/Seoul
      - USER=${ID}
      - PASS=${PASS}
    volumes:
      - ${HOME}/transmission/config:/config
      - ${HOME}/transmission/downloads:/downloads
      - ${HOME}/transmission/watch:/watch
    ports:
      - ${PORT}:9091
      - 51413:51413
      - 51413:51413/udp
    restart: unless-stopped
EOF

# 이미지 최신버전으로 교체
docker stop transmission
docker pull lscr.io/linuxserver/transmission:latest

docker compose up -d
cd ..

# Open firewall
sudo ufw allow ${PORT}
sudo ufw allow 51413

bash ./tools/making_motd.sh transmission \
  "transmission path - ${HOME}/transmission" \
  "For connecting Transmission - http://${MYIP}:${PORT}" \
  "Web id : ${ID} pass : ${PASS}"