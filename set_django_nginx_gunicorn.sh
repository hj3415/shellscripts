#!/bin/bash

# docker compose로 django nginx gunicorn 설치

# home - myapp - project_name(django compose 파일) - project_name
#              - setup_nginx(nginx compose 파일)
#              - docker-compose.yml

MYIP=`hostname -I | cut -d ' ' -f1`

echo ">>> The prerequisite is the making of python virtual environment. Did you do that?(y/N)"
read answer
if [[ ${answer} != 'y' ]];then
exit 0
fi

echo ">>> Input your domain(default: hj3415.iptime.org) : "
read domain
if [[ ${domain} == '' ]];then
MYDOMAIN='hj3415.iptime.org'
else
MYDOMAIN=${domain}
fi

echo ">>> Input your django project name(default: gsden) : "
read project_name
if [[ ${project_name} == '' ]];then
PROJECT_NAME='gsden'
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


pip install django gunicorn

rm -rf ${HOME}/myapp
mkdir ${HOME}/myapp
cd ${HOME}/myapp

# https://adiramadhan17.medium.com/django-gunicorn-with-nginx-in-docker-21d32488ab98
echo "***********************************************************************"
echo "*                     Making django skeleton                            *"
echo "***********************************************************************"

django-admin startproject ${PROJECT_NAME}
cd ${PROJECT_NAME}
python manage.py migrate

pip freeze>requirements.txt
# tee requirements.txt<<EOF
# Django
# gunicorn
# EOF

tee Dockerfile<<EOF
# syntax=docker/dockerfile:1
FROM python:3.8

# set environment variables
ENV APP_HOME=/app
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# set work directory
WORKDIR \$APP_HOME

# update pip, install dependencies
RUN pip install --upgrade pip
COPY ./requirements.txt \$APP_HOME
RUN pip install -r requirements.txt

# copy app folder
COPY . \$APP_HOME

# run python command
RUN python manage.py makemigrations
RUN python manage.py migrate
RUN python manage.py collectstatic --noinput --clear
EOF


echo "***********************************************************************"
echo "*                     Making nginx docker                            *"
echo "***********************************************************************"

mkdir ${HOME}/myapp/setup_nginx

tee ${HOME}/myapp/setup_nginx/nginx.conf<<EOF
client_max_body_size 8M;

upstream django_app {
    server django_${PROJECT_NAME}:8000;
}

server {

    listen 80;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    client_max_body_size 50M;

    location / {
        proxy_pass http://django_app;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Host \$host;
        proxy_redirect off;
    }

    location /static/ {
        alias /app/staticfiles/;
    }

    location /media/ {
        alias /app/mediafiles/;
    }
}
EOF

tee ${HOME}/myapp/setup_nginx/Dockerfile<<EOF
# Fetching the latest nginx image
FROM nginx

# Removing default nginx.conf
RUN rm /etc/nginx/conf.d/default.conf

# Copying new conf.d into conf.d nginx image
COPY nginx.conf /etc/nginx/conf.d
EOF


echo "***********************************************************************"
echo "*                     Making docker-compose.yml                        *"
echo "***********************************************************************"

tee ${HOME}/myapp/docker-compose.yml<<EOF
# Defining the compose version
services:

 nginx:
  build: ./setup_nginx
  container_name: nginx
  ports:
    - ${PORT}:80
  volumes:
    - static_volume:/app/staticfiles
    - media_volume:/app/mediafiles
  depends_on:
    - django_${PROJECT_NAME}
  restart: "always"

 django_${PROJECT_NAME}:
  build: ./${PROJECT_NAME}
  container_name: django_${PROJECT_NAME}
  command: sh -c "gunicorn ${PROJECT_NAME}.wsgi:application --bind 0.0.0.0:8000"
  volumes:
    - static_volume:/app/staticfiles
    - media_volume:/app/mediafiles
  expose:
   - 8000
  restart: "always"

volumes:
 static_volume:
 media_volume:
EOF

echo "***********************************************************************"
echo "*               Modifying default settings in django                  *"
echo "***********************************************************************"

# settings.py 백업
cp ${HOME}/myapp/${PROJECT_NAME}/${PROJECT_NAME}/settings.py ${HOME}/myapp/${PROJECT_NAME}/${PROJECT_NAME}/settings.py.orig
# allowed_hosts 에 현재 아이피, 도메인 추가
sed -i "s|ALLOWED_HOSTS\s*=\s*\[|&'localhost','${MYIP}','${MYDOMAIN}'|" ${HOME}/myapp/${PROJECT_NAME}/${PROJECT_NAME}/settings.py
# 프로젝트 바깥에 templates 폴더 사용가능하게 설정
# sed -i "s|'DIRS'\s*:\s*\[|&Path(BASE_DIR,'templates')|" ${HOME}/myapp/${PROJECT_NAME}/${PROJECT_NAME}/settings.py

# static, media 사용 가능하게 하는 설정
sed -i "1 i\import os" ${HOME}/myapp/${PROJECT_NAME}/${PROJECT_NAME}/settings.py
tee -a ${HOME}/myapp/${PROJECT_NAME}/${PROJECT_NAME}/settings.py<<EOF
STATICFILES_DIRS = [
    os.path.join(BASE_DIR, '_static/'),
]

MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media/')
X_FRAME_OPTIONS = 'SAMEORIGIN'

STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')
EOF

# 필요한 폴더 생성
mkdir -pv ${HOME}/myapp/${PROJECT_NAME}/{_data,_static,media}

# static 폴더에 임의의 이미지 저장
#wget -P ${HOME}/myapp/${PROJECT_NAME}/_static/ https://picsum.photos/200.jpg

# 기본 index 페이지 생성
#tee ${HOME}/myapp/${PROJECT_NAME}/templates/index.html<<EOF
#{%load static%}
#<!DOCTYPE html>
#<html lang="en">
#<head>
#    <meta charset="UTF-8">
#    <meta http-equiv="X-UA-Compatible" content="IE=edge">
#    <meta name="viewport" content="width=device-width, initial-scale=1.0">
#    <title>Hello World</title>
#</head>
#<body>
#    <h1>Hello World!</h1>
#    <img src="{%static '200.jpg' %}" alt="not found">
#</body>
#</html>
#EOF

# urls.py 생성
#tee ${HOME}/myapp/${PROJECT_NAME}/${PROJECT_NAME}/urls.py<<EOF
#from django.contrib import admin
#from django.urls import path, include
#from django.conf import settings
#from django.conf.urls.static import static
#
#urlpatterns = [
#    path('admin/', admin.site.urls),
#
    # 최상위 경로가 맨 아래로 가야한다.
    # path('', include('django_herobiz_dental.urls')),
#] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
#EOF

cd ${HOME}/myapp
docker compose down && docker compose build && docker compose up -d

echo "<<<<<<<<<<<<<<<<<<<< Open firewall >>>>>>>>>>>>>>>>>>>>>>"
sudo ufw allow ${PORT}

# /etc/motd에 설명 추가
bash ${HOME}/tools/making_motd.sh django_nginx \
  "Django - Nginx - Gunicorn complex installed" \
  "Domain : ${MYDOMAIN} / Project : ${PROJECT_NAME} / Port : ${PORT}" \
  "" \
  "If web site contents changed, it need to restart docker composer." \
  "docker compose down && docker compose build && docker compose up -d"
