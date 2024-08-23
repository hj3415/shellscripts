#!/bin/bash

# docker compose로 nextcloud-redis-mariadb 설치

# mariadb & redis 유저명과 비밀번호
# nextcloud 유저명과 비밀번호는 웹에 접속해서 설정한다.
PORT="8080"
MYIP=`hostname -I | cut -d ' ' -f1`

echo "***********************************************************************"
echo "*                     Install nextcloud                               *"
echo "***********************************************************************"

echo ">>> Do you want to add trusted host address? (default:${MYIP})"
read TRUSTED_DOMAIN

# install docker compose
sudo apt update
sudo apt-get install -y docker-compose-plugin

docker compose version

rm -rf ${HOME}/setup_nextcloud-redis-mariadb
mkdir ${HOME}/setup_nextcloud-redis-mariadb; cd $_

tee ${HOME}/setup_nextcloud-redis-mariadb/docker-compose.yml<<EOF
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
      - NEXTCLOUD_TRUSTED_DOMAINS=${TRUSTED_DOMAIN}
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

# 이전 이미지 삭제
docker stop nextcloud
docker stop redis
docker stop mariadb

docker rm nextcloud
docker rm redis
docker rm mariadb

# 이전에 존재한 설정파일들을 삭제하기 위해 볼륨을 삭제한다.(trusted domain 재설정)
echo ">>> Do you want to reset config and db?(!!contents could be deleted!!) (y/N)"
read answer
if [[ ${answer} == 'y' ]];then
docker volume rm setup_nextcloud-redis-mariadb_nc_data
docker volume rm setup_nextcloud-redis-mariadb_db_data
fi

# 이미지 다시 생성
docker pull nextcloud:apache
docker pull redis:alpine
docker pull mariadb:10.5

docker compose up -d
cd ..

# Open firewall
sudo ufw allow ${PORT}

bash ${HOME}/tools/making_motd.sh nextcloud \
  "trusted domain - ${TRUSTED_DOMAIN}" \
  "처음 http://${TRUSTED_DOMAIN}:<<port>>에 접속하여 관리자를 생성한다."
