#!/bin/bash

# Install aws ubuntu20 with username ubuntu
MYIP=`hostname -I`
# www 빼고 실제 도메인만
MYDOMAIN="melange-studio.co.kr"
PROJECT_NAME="melange"

MEDIA_ROOT=${HOME}/${PROJECT_NAME}/media
STATIC_ROOT=${HOME}/${PROJECT_NAME}/staticfiles
SOCKET_PATH=${HOME}/${PROJECT_NAME}/gunicorn_socket

PORT=80

if [ -z "$MYIP" -o -z "$MYDOMAIN" ]; then
  echo "IP or Domain does not set."
  exit
fi

# change hostname to MYDOMAIN
sudo hostnamectl set-hostname ${MYDOMAIN}


echo "<<<<<<<<<<<<<<<<<<<< Append nginx gunicorn django motd >>>>>>>>>>>>>>>>>>>>>>"
# Make motd file
sudo tee -a /etc/motd<<EOF
********************************************************************
django project dir - ${HOME}/${PROJECT_NAME}

nginx and django static dir - ${STATIC_ROOT}
nginx conf file - /etc/nginx/sites-enabled/${PROJECT_NAME}

gunicorn service name - gunicorn_${PROJECT_NAME}.service
gunicorn socket file - ${SOCKET_PATH}/${PROJECT_NAME}.sock

access port = ${PORT}

EOF

echo "<<<<<<<<<<<<<<<<<< Create sample django project >>>>>>>>>>>>>>>>>>>>>>>>"
pip3 install django
cd ${HOME}
django-admin startproject ${PROJECT_NAME}

# change django setting(add aloowed host)
sed -i "s/ALLOWED_HOSTS\ \=\ \[\]/ALLOWED_HOSTS\ \=\ \[\'localhost\'\,\'${MYIP}\'\,\'www\.${MYDOMAIN}\'\,\'${MYDOMAIN}\'\]/" ${HOME}/${PROJECT_NAME}/${PROJECT_NAME}/settings.py

echo "<<<<<<<<<<<<<<<<<<<<< Setting up the nginx >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
sudo apt install -y nginx
sudo systemctl enable nginx

# set static dir
mkdir -pv ${STATIC_ROOT}
chmod -Rv 755 ${STATIC_ROOT}

# set media dir
mkdir -pv ${MEDIA_ROOT}
chmod -Rv 755 ${MEDIA_ROOT}
chown -R ${USER}:www-data ${MEDIA_ROOT}

echo "<<<<<<<<<<<<<<<<<<<<< Setting up the gunicorn >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
# install gunicron from system package
pip3 install gunicorn

# 이전 gunicorn 서비스 파일이 있으면 지운다.
# sudo rm -rf /etc/systemd/system/gunicorn*.service

# make service file
sudo tee /etc/systemd/system/gunicorn_${PROJECT_NAME}.service<<EOF
[Unit]
Description=gunicorn daemon
After=network.target

[Service]
User=${USER}
Group=www-data
WorkingDirectory=${HOME}/${PROJECT_NAME}
ExecStart=${VIRTUAL_ENV}/bin/gunicorn --access-logfile - --workers 1 --bind unix:${SOCKET_PATH}/${PROJECT_NAME}.sock ${PROJECT_NAME}.wsgi:application

[Install]
WantedBy=multi-user.target
EOF

# execute service
sudo systemctl daemon-reload
sudo systemctl start gunicorn_${PROJECT_NAME}.service
sudo systemctl enable gunicorn_${PROJECT_NAME}.service

echo "<<<<<<<<<<<<<<<<<<<<< Make nginx reverse proxy setting >>>>>>>>>>>>>>>>>>>>>>>>>"

# make socket folder
mkdir ${SOCKET_PATH}

# 이전 nginx config파일을 지운다.
#sudo rm -rf /etc/nginx/sites-available/*
#sudo rm -rf /etc/nginx/sites-enabled/*

# Setting up server blocks
# static 폴더끝에 /을 꼭 붙여주어야 한다. root 지시자와 alias지시자의 차이를 알아야한다.
sudo tee /etc/nginx/sites-available/${PROJECT_NAME}<<EOF
server {
    listen ${PORT};
    server_name ${MYIP} ${MYDOMAIN} www.${MYDOMAIN};
    # 이미지파일 업로드 용량 확장
    client_max_body_size 64M;

    location = /favicon.ico { access_log off; log_not_found off; }
    location  /static/ {
        alias ${STATIC_ROOT}/;
    }
    location  /media/ {
        alias ${MEDIA_ROOT}/;
    }
    location / {
        include proxy_params;
        proxy_pass http://unix:${SOCKET_PATH}/${PROJECT_NAME}.sock;
    }
}
EOF

sudo ln -sv /etc/nginx/sites-available/${PROJECT_NAME} /etc/nginx/sites-enabled/
sudo rm -rf /etc/nginx/sites-enabled/default

sudo nginx -t
sudo systemctl restart nginx

sudo ufw enable
sudo ufw allow 'Nginx Full'

echo "*** Installation was done. You can install django app in ${HOME}/${PROJECT_NAME} ***"
hostnamectl
