#!/bin/bash

# 도커, portainer 설치 및 설정
# $1 - 도커 사용자, $2 - portainer 접속 포트(default:9443)

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

echo "<<<<<<<<<<<<<<<<<<<< Add $1 to docker group >>>>>>>>>>>>>>>>>>>>>"
sudo usermod -aG docker $1
echo "$1's groups - `groups`"

# 새로 로그인하기 전까지는 그룹에 추가된것이 반영되지 않는다.
# sudo docker info

echo "<<<<<<<<<<<<<<<<<<<< Install Portainer >>>>>>>>>>>>>>>>>>>>>"
# https://docs.portainer.io/start/install/server/docker/linux
sudo docker volume create portainer_data
sudo docker run -d -p 8000:8000 -p ${2:="9443"}:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
# sudo docker ps

echo "<<<<<<<<<<<<<<<<<<<< Open firewall - Portainer port >>>>>>>>>>>>>>>>>>>>>>"
sudo ufw allow 8000
sudo ufw allow $2

# /etc/motd에 설명 추가
./tools/making_motd docker \
  "Docker installed." \
  "$1 added in docker group." \
  "So you don't neet to type 'sudo' for run docker from now on." \
  "" \
  "For connecting Portainer - https://${MYIP}:$2"
