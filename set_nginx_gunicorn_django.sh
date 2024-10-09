#!/bin/bash

# docker로 nginx 설치하면 ssl 적용이 복잡해서 사용하지 않기로함.
# 국내 접속만 허용하기 위한 설정함

MYIP=`hostname -I | cut -d ' ' -f1`

echo ">>> The prerequisite is the making of python virtual environment. Did you do that?(y/N)"
read answer
if [[ ${answer} != 'y' ]];then
exit 0
fi

echo ">>> Input your domain(default: hyungjin.kr) : "
read domain
if [[ ${domain} == '' ]];then
MYDOMAIN='hyungjin.kr'
else
MYDOMAIN=${domain}
fi

echo ">>> Input your django project name(default: hyungjin) : "
read project_name
if [[ ${project_name} == '' ]];then
PROJECT_NAME='hyungjin'
else
PROJECT_NAME=${project_name}
fi

echo ">>> Input your http port(default: 80) : "
read port
if [[ ${port} == '' ]];then
PORT='80'
else
PORT=${port}
fi

echo ">>> Domain : ${MYDOMAIN} / Project : ${PROJECT_NAME} / Port : ${PORT}. Is it right?(y/N)"
read answer
if [[ ${answer} != 'y' ]];then
exit 0
fi

# change hostname to MYDOMAIN
sudo hostnamectl set-hostname ${MYDOMAIN}

MEDIA_ROOT=${HOME}/${PROJECT_NAME}/media
STATIC_ROOT=${HOME}/${PROJECT_NAME}/staticfiles
SOCKET_PATH=${HOME}/${PROJECT_NAME}/gunicorn_socket

echo "<<<<<<<<<<<<<<<<<< Create sample django project >>>>>>>>>>>>>>>>>>>>>>>>"
rm -rf ${PROJECT_NAME}
pip3 install django
cd ${HOME}
django-admin startproject ${PROJECT_NAME}

# settings.py 백업
cp ${HOME}/${PROJECT_NAME}/${PROJECT_NAME}/settings.py ${HOME}/${PROJECT_NAME}/${PROJECT_NAME}/settings.py.orig
# allowed_hosts 에 현재 아이피, 도메인 추가
sed -i "s|ALLOWED_HOSTS\s*=\s*\[|&'localhost','${MYIP}','www.${MYDOMAIN}','${MYDOMAIN}'|" ${HOME}/${PROJECT_NAME}/${PROJECT_NAME}/settings.py

# static, media 사용 가능하게 하는 설정
sed -i "1 i\import os" ${HOME}/${PROJECT_NAME}/${PROJECT_NAME}/settings.py
tee -a ${HOME}/${PROJECT_NAME}/${PROJECT_NAME}/settings.py<<EOF
STATICFILES_DIRS = [
    os.path.join(BASE_DIR, '_static/'),
]

MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media/')
X_FRAME_OPTIONS = 'SAMEORIGIN'

STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')
EOF

# 필요한 폴더 생성
mkdir -pv ${HOME}/${PROJECT_NAME}/{_data,_static,media}


echo "<<<<<<<<<<<<<<<<<<<<< Setting up the nginx >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
sudo apt install -y nginx
sudo systemctl enable nginx

# set static dir
mkdir -pv ${STATIC_ROOT}
chmod -Rv 755 ${STATIC_ROOT}

# set media dir
mkdir -pv ${MEDIA_ROOT}
chmod -Rv 755 ${MEDIA_ROOT}
sudo chown -R ${USER}:www-data ${MEDIA_ROOT}


echo "<<<<<<<<<<<<<<<<<<<<< Setting up the gunicorn >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
# install gunicron from system package
pip3 install gunicorn

# 이전 gunicorn 서비스 파일이 있으면 지운다.
sudo rm -rf /etc/systemd/system/gunicorn_${PROJECT_NAME}.service

# make service file
sudo tee /etc/systemd/system/gunicorn_${PROJECT_NAME}.service<<EOF
[Unit]
Description=gunicorn daemon
After=network.target

[Service]
User=${USER}
Group=www-data
WorkingDirectory=${HOME}/${PROJECT_NAME}
ExecStart=${VIRTUAL_ENV}/bin/gunicorn --bind unix:${SOCKET_PATH}/${PROJECT_NAME}.sock ${PROJECT_NAME}.wsgi:application

[Install]
WantedBy=multi-user.target
EOF

# execute service
sudo systemctl daemon-reload
sudo systemctl start gunicorn_${PROJECT_NAME}.service
sudo systemctl enable gunicorn_${PROJECT_NAME}.service

echo "<<<<<<<<<<<<<<< 국내 아이피만 접속허용시키기 >>>>>>>>>>>>>>>>>>>>"
LICENSE_KEY=
sudo mkdir -p /usr/share/GeoIP/
cd /usr/share/GeoIP/
sudo wget "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country&license_key=${LICENSE_KEY}&suffix=tar.gz" -O GeoLite2-Country.tar.gz
sudo tar -xzf GeoLite2-Country.tar.gz
sudo mv GeoLite2-Country_*/GeoLite2-Country.mmdb .
sudo rm -rf GeoLite2-Country_*
sudo rm GeoLite2-Country.tar.gz

# nginx 에 geoip 모듈이 이미 설치되어 있다면 생략
sudo apt update
sudo apt install libnginx-mod-http-geoip2

sudo tee /etc/nginx/conf.d/geoip2.conf<<EOF
# GeoIP2 데이터베이스 설정
geoip2 /usr/share/GeoIP/GeoLite2-Country.mmdb {
    auto_reload 5m;  # 데이터베이스를 5분마다 자동으로 다시 로드
    \$geoip2_metadata_country_build metadata build_epoch;
    \$geoip2_data_country_code country iso_code;
    \$geoip2_data_country_name country names en;
}
EOF

echo "<<<<<<<<<<<<<<<<<<<<< Make nginx reverse proxy setting >>>>>>>>>>>>>>>>>>>>>>>>>"

# make socket folder and 권한설정
mkdir ${SOCKET_PATH}
sudo chmod 755 ${HOME}

# 이전 nginx config파일을 지운다.
sudo rm -rf /etc/nginx/sites-available/*
sudo rm -rf /etc/nginx/sites-enabled/*

# Setting up server blocks
# static 폴더끝에 /을 꼭 붙여주어야 한다. root 지시자와 alias지시자의 차이를 알아야한다.
sudo tee /etc/nginx/sites-available/${PROJECT_NAME}<<EOF
server {
    listen ${PORT};
    server_name ${MYIP} ${MYDOMAIN} www.${MYDOMAIN};
    # 이미지파일 업로드 용량 확장
    client_max_body_size 64M;

    # 인도 차단
    if ($geoip2_data_country_code = "IN") {
        return 403;
    }

    # 방글라데시 차단
    if ($geoip2_data_country_code = "BD") {
        return 403;
    }

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
# sudo rm -rf /etc/nginx/sites-enabled/default

sudo nginx -t
sudo systemctl restart nginx

echo "<<<<<<<<<<<<<<<< geolite2 자동 없데이트>>>>>>>>>>>>>>>>>>>>>>>"
sudo tee ${HOME}/autoupdate_geoip2.sh<<EOF
#!/bin/bash

LICENSE_KEY=

# 데이터베이스 다운로드
cd /usr/share/GeoIP/
wget -q "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country&license_key=${LICENSE_KEY}&suffix=tar.gz" -O GeoLite2-Country.tar.gz

# 데이터베이스 압축 해제 및 설치
tar -xzf GeoLite2-Country.tar.gz
mv GeoLite2-Country_*/GeoLite2-Country.mmdb .
rm -rf GeoLite2-Country_*
rm GeoLite2-Country.tar.gz

# Nginx 재시작
sudo systemctl reload nginx
EOF

sudo chmod +x ${HOME}/autoupdate_geoip2.sh
(sudo crontab -l 2>/dev/null; echo "0 5 * * 3 ${HOME}/autoupdate_geoip2.sh") | sudo crontab -

echo "<<<<<<<<<<<<<<<<<<<< Open firewall >>>>>>>>>>>>>>>>>>>>>>"
sudo ufw allow ${PORT}
sudo ufw allow 'Nginx Full'

echo "*** Installation was done. You can install django app in ${HOME}/${PROJECT_NAME} ***"
hostnamectl


# /etc/motd에 설명 추가
bash ${HOME}/tools/making_motd.sh django_nginx \
  "Django - Nginx - Gunicorn complex installed" \
  "Domain : ${MYDOMAIN} / Project : ${PROJECT_NAME} / Port : ${PORT}" \
  "" \
  "django project dir - ${HOME}/${PROJECT_NAME}" \
  "nginx conf file - /etc/nginx/sites-enabled/${PROJECT_NAME}" \
  "gunicorn service name - gunicorn_${PROJECT_NAME}"
