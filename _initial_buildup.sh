#!/bin/bash

# Ubuntu 22.04
# 모든 서버에 공통적인 요소를 세팅한다.

# root의 id가 0이기 때문에 sudo로 실행했으면 종료한다.
if [ $(id -u) -eq 0 ]; then
  echo "You should not run root."
  exit
fi

echo "<<<<<<<<<<<<<<<<<<<< Setting up prerequisites >>>>>>>>>>>>>>>>>>>>>>"
sudo apt update
sudo apt -y upgrade
sudo apt-get install -y ufw net-tools openssh-server tree curl hwinfo tasksel rdate mc links wget htop snapd build-essential dpkg nautilus-admin exfat-fuse
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

# 네임서버를 찾지 못해 인터넷을 못하는 현상을 고쳐준다.
echo "***********************************************************************"
echo "*                        fix resolvconf                               *"
echo "***********************************************************************"
# https://musaamin.web.id/set-permanent-resolv-conf-ubuntu/
echo "<<<<<<<<<<<<<<<<<<<< Overwrite /etc/resolv.conf temporarily >>>>>>>>>>>>>>>>>>>>>"
sudo tee /etc/resolv.conf<<EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
nameserver 127.0.0.53
EOF

echo "<<<<<<<<<<<<<<<<<<<< Install resolvconf service >>>>>>>>>>>>>>>>>>>>>"
sudo apt-get install -y resolvconf

sudo systemctl enable resolvconf
sudo systemctl start resolvconf
sudo systemctl status resolvconf

sudo tee -a /etc/resolvconf/resolv.conf.d/head<<EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF

sudo resolvconf --enable-updates
sudo resolvconf -u

echo "You should reboot for checking to set /etc/resolv.conf correctly."
