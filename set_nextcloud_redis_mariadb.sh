#!/bin/bash

# docker compose로 nextcloud-redis-mariadb 설치
# $1 - nextcloud 접속포트(default:8080)
echo "***********************************************************************"
echo "*                     Install nextcloud                               *"
echo "***********************************************************************"

# mariadb & redis 유저명과 비밀번호
# nextcloud 유저명과 비밀번호는 웹에 접속해서 설정한다.
USER="hj3415"
PASS="ljgda6421~"
MYIP=`hostname -I | cut -d ' ' -f1`

# install docker compose
sudo apt update
sudo apt-get install -y docker-compose-plugin

docker compose version

mkdir setup_nextcloud-redis-mariadb; cd $_
tee docker-compose.yml<<EOF
version: '3'

volumes:
  nextcloud:
  db:

services:
  db:
    image: mariadb
    restart: always
    command: --transaction-isolation=READ-COMMITTED --binlog-format=ROW --innodb-file-per-table=1 --skip-innodb-read-only-compressed
    volumes:
      - db:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=${PASS}
      - MYSQL_PASSWORD=${PASS}
      - MYSQL_DATABASE=db
      - MYSQL_USER=${USER}
  redis:
    image: redis
    restart: always
    command: redis-server --requirepass ${PASS}
  app:
    image: nextcloud
    restart: always
    ports:
      - ${1:=8080}:80
    links:
      - db
      - redis
    volumes:
      - nextcloud:/var/www/html
    environment:
      - MYSQL_PASSWORD=${PASS}
      - MYSQL_DATABASE=db
      - MYSQL_USER=${USER}
      - MYSQL_HOST=db
      - REDIS_HOST_PASSWORD=${PASS}
    depends_on:
      - db
EOF

docker compose up -d
cd ..

# Open firewall
sudo ufw allow $1

bash ./tools/making_motd.sh nextcloud \
  "trusted domain - http://${MYIP}:$1" \
  "처음 http://${MYIP}:$1 에 접속하여 관리자를 생성한다."
