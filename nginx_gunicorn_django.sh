#!/bin/bash

MYIP=`hostname -I | cut -d ' ' -f1`
MYDOMAIN="hj3415.iptime.org"
PROJECT_NAME="nfs_web"

echo "<<<<<<<<<<<<<<<<<<<< Append nginx gunicorn django motd >>>>>>>>>>>>>>>>>>>>>>"
# Make motd file
sudo tee -a /etc/motd<<EOF
********************************************************************
django project dir - ${HOME}/${PROJECT_NAME}

nginx static dir - /var/www/${USER}/html
nginx conf file - /etc/nginx/sites-enabled/${PROJECT_NAME}

gunicorn service & socket name - gunicorn_${PROJECT_NAME}

EOF

echo "<<<<<<<<<<<<<<<<<<<< Install google chrome >>>>>>>>>>>>>>>>>>>>>>"
# 구글 크롬 설치 위해 GUI설치
# sudo apt install -y ubuntu-desktop

# Install chrome
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb

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
sudo mkdir -pv /var/www/${USER}/html
sudo tee /var/www/${USER}/html/index.html<<EOF
<html>
    <head>
        <title>Welcome to ${PROJECT_NAME}!</title>
    </head>
    <body>
        <h1>Success!  The ${MYDOMAIN} ${MYIP} server block is working!</h1>
    </body>
</html>
EOF
sudo chmod -Rv 755 /var/www/${USER}

echo "<<<<<<<<<<<<<<<<<<<<< Setting up the gunicorn >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
# install gunicron from system package
pip3 install gunicorn

# make socket file
sudo tee /etc/systemd/system/gunicorn_${PROJECT_NAME}.socket<<EOF
[Unit]
Description=gunicorn_${PROJECT_NAME} socket

[Socket]
ListenStream=/run/gunicorn_${PROJECT_NAME}.sock
# Our service won't need permissions for the socket, since it
# inherits the file descriptor by socket activation
# only the nginx daemon will need access to the socket
SocketUser=www-data
# Optionally restrict the socket permissions even more.
# SocketMode=600

[Install]
WantedBy=sockets.target
EOF

# make service file
sudo tee /etc/systemd/system/gunicorn_${PROJECT_NAME}.service<<EOF
[Unit]
Description=gunicorn ${PROJECT_NAME} daemon
Requires=gunicorn_${PROJECT_NAME}.socket
After=network.target

[Service]
Type=notify
# the specific user that our service will run as
User=${USER}
Group=${GROUPS}
# another option for an even more restricted service is
# DynamicUser=yes
# see http://0pointer.net/blog/dynamic-users-with-systemd.html
RuntimeDirectory=gunicorn
WorkingDirectory=${HOME}/${PROJECT_NAME}
ExecStart=${VIRTUAL_ENV}/bin/gunicorn ${PROJECT_NAME}.wsgi
ExecReload=/bin/kill -s HUP ${MAINPID}
KillMode=mixed
TimeoutStopSec=5
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

# execute service
sudo systemctl start gunicorn_${PROJECT_NAME}.socket
sudo systemctl start gunicorn_${PROJECT_NAME}.service
sudo systemctl enable gunicorn_${PROJECT_NAME}.socket
sudo systemctl enable gunicorn_${PROJECT_NAME}.service

echo "<<<<<<<<<<<<<<<<<<<<< Make nginx reverse proxy setting >>>>>>>>>>>>>>>>>>>>>>>>>"
# Setting up server blocks
sudo tee /etc/nginx/sites-available/${PROJECT_NAME}<<EOF
upstream app_server {
    server unix:/run/gunicorn_${PROJECT_NAME}.sock fail_timeout=0;
  }

  server {
    # if no Host match, close the connection to prevent host spoofing
    listen 80 default_server;
    return 444;
  }

  server {
    # use 'listen 80 deferred;' for Linux
    # use 'listen 80 accept_filter=httpready;' for FreeBSD
    listen 80;
    client_max_body_size 4G;

    # set the correct host(s) for your site
    server_name ${MYDOMAIN} ${MYIP};

    keepalive_timeout 5;

    # path for static files
    root /var/www/${USER}/html;

    location / {
      # checks for static file, if not found proxy to app
      try_files \$uri @proxy_to_app;
    }

    location @proxy_to_app {
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto \$scheme;
      proxy_set_header Host \$http_host;
      # we don't want nginx trying to do something clever with
      # redirects, we set the Host: header above already.
      proxy_redirect off;
      proxy_pass http://app_server;
    }

    # error_page 500 502 503 504 /500.html;
    # location = /500.html {
    #  root /path/to/app/current/public;
    # }
}
EOF

sudo ln -sv /etc/nginx/sites-available/${PROJECT_NAME} /etc/nginx/sites-enabled/
sudo rm -v /etc/nginx/sites-enabled/default

sudo nginx -t
sudo systemctl restart nginx

sudo ufw enable
sudo ufw allow 'Nginx Full'
