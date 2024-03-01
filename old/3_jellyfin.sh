#!/bin/bash

sudo docker pull jellyfin/jellyfin
sudo docker volume create jellyfin-config
sudo docker volume create jellyfin-cache

#docker run or compose
#docker ps
#docker start












IP_BACKUP_SRV="192.168.0.171"
JELLYFIN_MEDIA_PATH="/jellyfin"

echo "<<<<<<<<<<<<<<<<<<<< Append jellyfin motd >>>>>>>>>>>>>>>>>>>>>>"
sudo tee -a /etc/motd<<EOF
********************************************************************
Jellyfin
working directory - ${JELLYFIN_MEDIA_PATH}
port - 8096
만약 jellyfin을 사용중에 서버를 재설치하는 경우는 fstab으로 마운팅하는것이 필요하다
${JELLYFIN_MEDIA_PATH} 디바이스 - /dev/sda2(1.6T)
EOF

echo "<<<<<<<<<<<<<<<<<<<<< Setting up jellyfin >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
sudo rm /etc/apt/sources.list.d/jellyfin.list

# set ubuntu repository
sudo apt -y install apt-transport-https
sudo add-apt-repository universe
curl -fsSL https://repo.jellyfin.org/ubuntu/jellyfin_team.gpg.key | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/debian-jellyfin.gpg
echo "deb [arch=$( dpkg --print-architecture )] https://repo.jellyfin.org/ubuntu $( lsb_release -c -s ) main" | sudo tee /etc/apt/sources.list.d/jellyfin.list

sudo apt update
sudo apt -y install jellyfin

sudo systemctl status jellyfin
sudo systemctl stop jellyfin

# Open firewall
sudo ufw allow 8096

# Add read and execute permission to media library (jellyfin user)
mkdir -p ${JELLYFIN_MEDIA_PATH}
cd ${JELLYFIN_MEDIA_PATH}
mkdir movies music tv_shows books photos etc
chown -R jellyfin:jellyfin ${JELLYFIN_MEDIA_PATH}
sudo setfacl -R -m u:hj3415:rwx ${JELLYFIN_MEDIA_PATH}

sudo systemctl restart jellyfin


echo "<<<<<<<<<<<<<<<<<<<<< Making a restoring script >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
# maeke a restoring script
tee -a ./restore_jellyfin.sh<<EOF
rsync -arvz -e "ssh -p 22" --progress --delete hj3415@${IP_BACKUP_SRV}:/home/hj3415/jellyfin_bak/* ${JELLYFIN_MEDIA_PATH}
EOF
chmod +x ./restore_jellyfin.sh
