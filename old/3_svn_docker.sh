#!/bin/bash

ID="hj3415"
PASS="piyrw421"
WEBDAV_PORT="7443"
SVN_PORT="3690"
NAME="svn-server"

# https://gist.github.com/dpmex4527/1d702357697162384d31d033a7d505eb

sudo apt install -y subversion

docker volume create svn-root
docker run -dit --name ${NAME} -v svn-root:/home/svn -p ${WEBDAV_PORT}:80 -p ${SVN_PORT}:3690 -w /home/svn elleflorio/svn-server
docker update --restart=unless-stopped ${NAME}
docker exec -t svn-server htpasswd -b /etc/subversion/passwd ${ID} ${PASS}
docker exec -it svn-server svnadmin create project
echo "<<<<<<<<<<<<<<<<<<<< SVN info >>>>>>>>>>>>>>>>>>>>>>"
svn info svn://localhost:${SVN_PORT}/project

echo "<<<<<<<<<<<<<<<<<<<< Open firewall - SVN ports >>>>>>>>>>>>>>>>>>>>>>"
sudo ufw allow ${WEBDAV_PORT}
sudo ufw allow ${SVN_PORT}

echo "<<<<<<<<<<<<<<<<<<<< Append to /etc/motd >>>>>>>>>>>>>>>>>>>>>>"
sudo tee -a /etc/motd<<EOF
********************************************************************

${NAME} docker installed
access - http://localhost:${WEBDAV_PORT}/svn/project
svn://localhost:${SVN_PORT}/project
user id - ${ID}, pass - ${PASS}

EOF
