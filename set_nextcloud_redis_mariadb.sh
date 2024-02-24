#!/bin/bash

# docker compose로 nextcloud-redis-mariadb 설치

echo "***********************************************************************"
echo "*                     Install nextcloud                               *"
echo "***********************************************************************"

# mariadb & redis 유저명과 비밀번호
# nextcloud 유저명과 비밀번호는 웹에 접속해서 설정한다.
MYIP=`hostname -I | cut -d ' ' -f1`
PORT="8080"

# install docker compose
sudo apt update
sudo apt-get install -y docker-compose-plugin

docker compose version

rm -rf setup_nextcloud-redis-mariadb
mkdir setup_nextcloud-redis-mariadb; cd $_

tee docker-compose.yml<<EOF
services:
  nc:
    image: nextcloud:apache
    container_name: nextcloud
    restart: always
    ports:
      - ${PORT}:80
    volumes:
      - nc_data:/var/www/html
    networks:
      - redisnet
      - dbnet
    environment:
      - REDIS_HOST=redis
      - MYSQL_HOST=db
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud
      - MYSQL_PASSWORD=nextcloud
  redis:
    image: redis:alpine
    container_name: redis
    restart: always
    networks:
      - redisnet
    expose:
      - 6379
  db:
    image: mariadb:10.5
    container_name: mariadb
    command: --transaction-isolation=READ-COMMITTED --binlog-format=ROW
    restart: always
    volumes:
      - db_data:/var/lib/mysql
    networks:
      - dbnet
    environment:
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud
      - MYSQL_ROOT_PASSWORD=nextcloud
      - MYSQL_PASSWORD=nextcloud
    expose:
      - 3306
volumes:
  db_data:
  nc_data:
networks:
  dbnet:
  redisnet:
EOF

# 이미지 최신버전으로 교체
docker stop nextcloud
docker pull nextcloud:apache
docker stop redis
docker pull redis:alpine
docker stop mariadb
docker pull mariadb:10.5

docker compose up -d
cd ..

# Open firewall
sudo ufw allow ${PORT}

bash ./tools/making_motd.sh nextcloud \
  "trusted domain - http://${MYIP}:${PORT}" \
  "처음 http://${MYIP}:${PORT} 에 접속하여 관리자를 생성한다."
