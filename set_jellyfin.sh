#!/bin/bash

# jellyfin 설치 및 설정

UID=`id -u`
GID=`id -g`
PORT="8096"
MYIP=`hostname -I | cut -d ' ' -f1`

echo "***********************************************************************"
echo "*                      Install Jellyfin                          *"
echo "***********************************************************************"

# install docker compose
sudo apt update
sudo apt install -y docker-compose-plugin

docker compose version

# 필요한 기본 디렉토리 생성
echo ">>> Do you want to reset jellyfin directory?(!!contents could be deleted!!) (y/N)"
read answer
if [[ ${answer} == 'y' ]];then
sudo rm -rf ${HOME}/jellyfin/{library,data}
fi
mkdir -p ${HOME}/jellyfin/{library,data}

rm -rf ${HOME}/setup_jellyfin
mkdir ${HOME}/setup_jellyfin; cd $_

tee ${HOME}/setup_jellyfin/docker-compose.yml<<EOF
version: "2.1"
services:
  jellyfin:
    image: lscr.io/linuxserver/jellyfin:latest
    container_name: jellyfin
    environment:
      - PUID=${UID}
      - PGID=${GID}
      - TZ=Asia/Seoul
    volumes:
      - ${HOME}/jellyfin/library:/config
      - ${HOME}/jellyfin/data:/data
    ports:
      - ${PORT}:${PORT}
      - 8920:8920 #optional
      - 7359:7359/udp #optional
      - 1900:1900/udp #optional
    restart: unless-stopped
EOF

# 이전 이미지 삭제
docker stop jellyfin

docker rm jellyfin

# 이미지 다시 생성
docker pull lscr.io/linuxserver/jellyfin:latest

docker compose up -d
cd ..
sudo chown -R ${UID}:${GID} ${HOME}/jellyfin/data

# Open firewall
sudo ufw allow ${PORT}/tcp
sudo ufw allow 8920/tcp
sudo ufw allow 7359/udp
sudo ufw allow 1900/udp

bash ${HOME}/tools/making_motd.sh jellyfin \
  "jellyfin path - ${HOME}/jellyfin" \
  "For connecting jellyfin - http://${MYIP}:${PORT}"
