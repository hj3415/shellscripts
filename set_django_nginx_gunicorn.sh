#!/bin/bash

# docker compose로 django nginx gunicorn 설치

MYIP=`hostname -I | cut -d ' ' -f1`
MYDOMAIN="hj3415.iptime.org"
PORT="8687"
PROJECT_NAME="gsden"

echo ">>> The prerequisite is the making of python environment. Did you do that?(y/N)"
read answer
if [[ ${answer} == 'n' ]];then
exit 0
fi
pip install django gunicorn
mkdir docker_django_nginx
cd ./docker_django_nginx

echo "***********************************************************************"
echo "*                     Making django skeleton                            *"
echo "***********************************************************************"
django-admin startproject ${PROJECT_NAME}
cd ${PROJECT_NAME}
python manage.py migrate

tee requirements.txt<<EOF
Django
gunicorn
EOF

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

cd ..
# 빈 장고 프로젝트 생성 완료 및 도커 생성 파일 작성 완료

echo "***********************************************************************"
echo "*                     Making nginx docker                            *"
echo "***********************************************************************"

mkdir nginx
cd nginx

tee nginx.conf<<EOF
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

tee Dockerfile<<EOF
# Fetching the latest nginx image
FROM nginx

# Removing default nginx.conf
RUN rm /etc/nginx/conf.d/default.conf

# Copying new conf.d into conf.d nginx image
COPY nginx.conf /etc/nginx/conf.d
EOF

cd ..
# nginx 프로시 설정 완료 및 도커 생성 파일 작성 완료

echo "***********************************************************************"
echo "*                     Making docker-compose.yml                        *"
echo "***********************************************************************"

tee docker-compose.yml<<EOF
version: '1.0'

# Defining the compose version
services:

 nginx:
  build: ./nginx
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

# settings.py 수정
cp ./${PROJECT_NAME}/${PROJECT_NAME}/settings.py.orig ./${PROJECT_NAME}/${PROJECT_NAME}/settings.py
cp ./${PROJECT_NAME}/${PROJECT_NAME}/settings.py ./${PROJECT_NAME}/${PROJECT_NAME}/settings.py.orig

sed -i "s|ALLOWED_HOSTS\s*=\s*\[|&'localhost','${MYIP}','${MYDOMAIN}'|" ./${PROJECT_NAME}/${PROJECT_NAME}/settings.py
sed -i "s|'DIRS'\s*:\s*\[|&Path(BASE_DIR,'templates')|" ./${PROJECT_NAME}/${PROJECT_NAME}/settings.py

tee -a ./${PROJECT_NAME}/${PROJECT_NAME}/settings.py<<EOF
STATIC_URL = '/static/'
STATIC_ROOT = Path(BASE_DIR, 'staticfiles')
STATICFILES_DIRS = [Path(BASE_DIR,'static'),]

MEDIA_URL = "/media/"
MEDIA_ROOT = Path(BASE_DIR, 'mediafiles')
EOF

# 필요한 폴더 생성
mkdir -pv ./${PROJECT_NAME}/{static,media,templates}

# static 폴더에 임의의 이미지 저장
wget -P ./${PROJECT_NAME}/static/ https://picsum.photos/200.jpg

# 기본 index 페이지 생성
tee ./${PROJECT_NAME}/templates/index.html<<EOF
{%load static%}
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hello World</title>
</head>
<body>
    <h1>Hello World!</h1>
    <img src="{%static '200.jpg' %}" alt="not found">
</body>
</html>
EOF

# urls.py 생성
tee ./${PROJECT_NAME}/${PROJECT_NAME}/urls.py<<EOF
from django.urls import path
from django.shortcuts import render

def home(request):
    return render(request, template_name='index.html')

urlpatterns = [
    path('', home ),
]
EOF

# Open firewall
sudo ufw allow ${PORT}

# 원하는 장고 프로젝트를 프로젝트 폴더에 복사
# 이후 작업 폴더에서 docker compose up --build 실행
# ip 8687에서 접속테스트
# 도커 삭제 docker compose down -rmi all