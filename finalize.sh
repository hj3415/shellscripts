#!/bin/bash

sudo apt -y autoremove

echo "***********************************************************************"
echo "*                        Install fail2ban & rkhunter                               *"
echo "***********************************************************************"

echo "<<<<< Setting up fail2ban >>>>"

# Install fail2ban
sudo apt update
sudo apt -y upgrade
sudo apt install -y fail2ban

BANTIME=43200 #10시간
FINDTIME=600 #10분
MAXTRY=5

# change settings on fail2ban
# 인증실패시 12시간차단
sudo sed -i "s/^bantime\s*\=.*/bantime\=${BANTIME}/g" /etc/fail2ban/jail.conf

# findtime초 동안 maxtry회 로그인 실패시 차단
sudo sed -i "s/^findtime\s*\=.*/findtime\=${FINDTIME}/g" /etc/fail2ban/jail.conf
sudo sed -i "s/^maxretry\s*\=.*/maxretry\=${MAXTRY}/g" /etc/fail2ban/jail.conf

sudo systemctl enable fail2ban.service
sudo systemctl restart fail2ban.service

# 시스템종료시 빠르게
sudo sed -i 's/^#DefaultTimeoutStopSec\s*\=.*/DefaultTimeoutStopSec=5s/g' /etc/systemd/system.conf

# Install rkhunter
sudo apt install -y rkhunter

# change settings on rkrunter
sudo sed -i 's/^UPDATE_MIRRORS=[0-9]/UPDATE_MIRRORS=1/g' /etc/rkhunter.conf
sudo sed -i 's/^MIRRORS_MODE=[0-9]/MIRRORS_MODE=0/g' /etc/rkhunter.conf
sudo sed -i 's/^WEB_CMD="\/bin\/false"/WEB_CMD=""/g' /etc/rkhunter.conf

# set cron configuration
sudo sed -i 's/^CRON_DAILY_RUN=""/CRON_DAILY_RUN="true"/g' /etc/default/rkhunter
sudo sed -i 's/^CRON_DB_UPDATE=""/CRON_DB_UPDATE="true"/g' /etc/default/rkhunter
sudo sed -i 's/^APT_AUTOGEN="false"/APT_AUTOGEN="true"/g' /etc/default/rkhunter

sudo rkhunter --update

echo "<<<<<<<<<<<<<<<<<<<< Enable firewall >>>>>>>>>>>>>>>>>>>>>>"
sudo ufw enable
sudo ufw status

# /etc/motd에 설명 추가
bash ./tools/making_motd.sh finalize \
  "fail2ban log - /var/log/fail2ban.log" \
  "로그인 인증 실패시 $((${BANTIME} / 3600))시간 동안 차단" \
  "$((${FINDTIME} / 60))분 동안 ${MAXTRY} 회 로그인 실패시 차단" \
  "" \
  "rkhunter installed"
