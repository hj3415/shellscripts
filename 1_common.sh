#!/bin/bash

# Ubuntu 22.04
# 모든 서버에 공통적인 요소를 세팅한다.
# 기본 유저명 hj3415 | ljgda6421~

# root의 id가 0이기 때문에 sudo로 실행했으면 종료한다.
if [ $(id -u) -eq 0 ]; then
  echo "You should not run root."
  exit
fi

# 네임서버를 찾지 못해 인터넷을 못하는 현상을 고쳐준다.
chmod +x ./1_1_fix_resolvconf.sh
bash ./1_1_fix_resolvconf.sh

# 도커, Portainer 설치
chmod +x ./1_2_docker.sh
bash ./1_2_docker.sh

# 파이썬 가상환경생성
chmod +x ./1_3_python.sh
bash ./1_3_python.sh

echo "<<<<<<<<<<<<<<<<<<<< Setting up prerequisites >>>>>>>>>>>>>>>>>>>>>>"
sudo apt update
sudo apt -y upgrade
sudo apt install -y net-tools openssh-server tree curl hwinfo tasksel rdate mc links wget htop snapd build-essential dpkg nautilus-admin exfat-fuse
sudo apt autoremove

echo "<<<<<<<<<<<<<<<<<<<< Make a root crontab >>>>>>>>>>>>>>>>>>>>>>"
sudo tee /var/spool/cron/crontabs/root<<EOF
MAILTO=""
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin

# m h  dom mon dow   command

# reboot every 3am
#0 3 * * 0 /sbin/shutdown -r +5
10 3 * * 0 /usr/sbin/rdate -s time.bora.net
11 3 * * 0 /usr/bin/apt update
15 3 * * 0 /usr/bin/apt -y upgrade
EOF
sudo chown -v root:crontab /var/spool/cron/crontabs/root
sudo chmod -v 600 /var/spool/cron/crontabs/root

echo "<<<<<<<<<<<<<<<<<<<< Open firewall - ssh port >>>>>>>>>>>>>>>>>>>>>>"
sudo ufw allow openssh

echo "<<<<<<<<<<<<<<<<<<<< Correct Reboot Freezing >>>>>>>>>>>>>>>>>>>>>"
sudo sed -i "s/\#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=5s/" /etc/systemd/system.conf
