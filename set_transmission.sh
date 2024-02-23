#!/bin/bash

# transmission 설치 및 설정
# $1 - transmission 접속아이디(default:hj3415)
# $2 - transmission 접속비밀번호(default:piyrw421)
# $3 - transmission 접속포트(default:9091)

echo "***********************************************************************"
echo "*                      Install Transmission                          *"
echo "***********************************************************************"

UID=`id -u`
GID=`id -g`

# install docker compose
sudo apt update
sudo apt install -y docker-compose-plugin

docker compose version

# 필요한 기본 디렉토리 생성
mkdir -p transmission/{config,downloads,watch}
mkdir setup_transmission; cd $_

tee docker-compose.yml<<EOF
version: "2.1"
services:
  transmission:
    image: lscr.io/linuxserver/transmission:latest
    container_name: transmission
    environment:
      - PUID=${UID}
      - PGID=${GID}
      - TZ=Asiz/Seoul
      - TRANSMISSION_WEB_HOME=/combustion-release/
      - USER=${1:-hj3415}
      - PASS=${2:-piyrw421}
    volumes:
      - ${HOME}/transmission/config:/config
      - ${HOME}/transmission/downloads:/downloads
      - ${HOME}/transmission/watch:/watch
    ports:
      - ${3:-9091}:9091
      - 51413:51413
      - 51413:51413/udp
    restart: unless-stopped
EOF

docker compose up -d

# Open firewall
sudo ufw allow ${PORT}
sudo ufw allow 51413

./tools/making_motd.sh transmission \
  "transmission path - ${HOME}/transmission" \
  "port - ${PORT}"