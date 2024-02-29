#!/bin/bash

# 도커, portainer 설치 및 설정

USER="hj3415"
PORTAINER_PORT="9443"
MYIP=`hostname -I | cut -d ' ' -f1`

echo "***********************************************************************"
echo "*                        Install docker                               *"
echo "***********************************************************************"

echo "<<<<<<<<<<<<<<<<<<<< Install docker >>>>>>>>>>>>>>>>>>>>>"
sudo apt update
# https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-22-04
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-cache policy docker-ce
echo ">>> Is it right you are about to install from the Docker repo? (Y/n)"
read answer
if [[ ${answer} == 'n' ]];then
exit 0
fi
sudo apt-get install -y docker-ce docker-compose-plugin
sudo systemctl status docker
echo ">>> Is it right status on docker service? (Y/n)"
read answer
if [[ ${answer} == 'n' ]];then
exit 0
fi

echo "<<<<<<<<<<<<<<<<<<<< Add ${USER} to docker group >>>>>>>>>>>>>>>>>>>>>"
sudo usermod -aG docker ${USER}
echo "${USER}'s groups - `groups`"

# 새로 로그인하기 전까지는 그룹에 추가된것이 반영되지 않는다.
# sudo docker info

echo "<<<<<<<<<<<<<<<<<<<< Install Portainer >>>>>>>>>>>>>>>>>>>>>"
docker compose version

rm -rf setup_portainer
mkdir setup_portainer; cd $_

tee docker-compose.yml<<EOF
version: '3'

services:
  portainer:
    image: portainer/portainer-ce:alpine
    container_name: portainer
    restart: always
    ports:
      - ${PORTAINER_PORT}:9000
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ${HOME}/portainer_data:/data


volumes:
  portainer_data:
EOF

# 이전 이미지 삭제
docker stop portainer
docker rm portainer

# 이전에 존재한 설정파일들을 삭제하기 위해 볼륨을 삭제한다.(trusted domain 재설정)
echo ">>> Do you want to reset config ?(!!contents could be deleted!!) (y/N)"
read answer
if [[ ${answer} == 'y' ]];then
sudo rm -rf ${HOME}/portainer_data
fi

# 이미지 다시 생성
docker pull portainer/portainer-ce:alpine

docker compose up -d
cd ..

echo "<<<<<<<<<<<<<<<<<<<< Open firewall - Portainer port >>>>>>>>>>>>>>>>>>>>>>"
sudo ufw allow 8000
sudo ufw allow ${PORTAINER_PORT}

# /etc/motd에 설명 추가
bash ./tools/making_motd.sh docker \
  "${USER} added in docker group." \
  "So you don't neet to type 'sudo' for run docker from now on." \
  "" \
  "For connecting Portainer - http://${MYIP}:${PORTAINER_PORT}" \
  "You can set web id : admin pass : 123456qwerty"