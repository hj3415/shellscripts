#!/bin/bash

# www 빼고 실제 도메인만
MYDOMAIN="melange-studio.co.kr"

echo "<<<<<<<<<<<<<<<<<<<<< Install ssl with certbot >>>>>>>>>>>>>>>>>>>>>>>>>"
echo "PLEASE CHECK YOUR DOMAIN AGAIN - ${MYDOMAIN}"

# ubutu 20.04 에 nginx설치가 전제

sudo snap install core; sudo snap refresh core
sudo apt remove certbot -y
sudo apt autoremove -y
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot

echo "<<<<<< certbot 설정 방법 - 이메일 입력, ,y ,y , blank 입력 >>>>>>"
sudo certbot --nginx -d ${MYDOMAIN} -d www.${MYDOMAIN}
