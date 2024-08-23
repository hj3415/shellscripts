#!/bin/bash

# subversion 설치 및 설정
# referenced from https://blog.eldernode.com/install-subversion-on-ubuntu/

ID="hj3415"
PASS="piyrw421"
PORT="7443"
SVN_PATH="/var/lib/svn"
MYIP=`hostname -I | cut -d ' ' -f1`

echo "***********************************************************************"
echo "*                      Install Subversion                          *"
echo "***********************************************************************"

echo "<<<<<<<<<<<<<<<<<<<<< Setting up SVN >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
# install apache2
sudo apt update
sudo apt install -y apache2 apache2-utils

# install SVN
sudo apt install -y subversion libapache2-mod-svn subversion-tools libsvn-dev
sudo a2enmod dav dav_svn

# change port
sudo sed -i "s/Listen 80/Listen ${PORT}/" /etc/apache2/ports.conf

echo "<<<<<<<<< Set subversion ${ID} password...(${PASS}) >>>>>>>>>>>>>>>"
sudo htpasswd -cm /etc/apache2/dav_svn.passwd ${ID}

# 필요한 기본 디렉토리 생성
echo ">>> Do you want to reset subversion directory?(!!contents could be deleted!!) (y/N)"
read answer
if [[ ${answer} == 'y' ]];then
sudo rm -rf ${SVN_PATH}
fi

echo "<<<<<<<<<<<<<<<<<<<<<<< Create repository >>>>>>>>>>>>>>>>>>>>>>>>>>>"
sudo mkdir -pv ${SVN_PATH}
sudo svnadmin create ${SVN_PATH}/project
sudo chown -R www-data:www-data ${SVN_PATH}
sudo chmod -R 775 ${SVN_PATH}

echo "<<<<<<<<<<<<<<<<< configure apache2 with SVN >>>>>>>>>>>>>>>>>>>>>>>"
# Edit a /etc/apache2/mods-enabled/dav_svn.conf
sudo tee /etc/apache2/mods-enabled/dav_svn.conf<<EOF
<Location /svn>
  DAV svn

  SVNParentPath ${SVN_PATH}

  AuthType Basic
  AuthName "Subversion Repository"
  AuthUserFile /etc/apache2/dav_svn.passwd

  <LimitExcept GET PROPFIND OPTIONS REPORT>
    Require valid-user
  </LimitExcept>
</Location>
EOF


echo "<<<<<<<<<<<<<<<<<<<< Open firewall - SVN ports >>>>>>>>>>>>>>>>>>>>>>"
sudo ufw allow ${PORT}

sudo apachectl -t
sudo systemctl restart apache2
sudo systemctl status apache2

echo "<<<<<<<<<<<<<<<<<<<< Append subversion motd >>>>>>>>>>>>>>>>>>>>>>"
bash ${HOME}/tools/making_motd.sh transmission \
  "apache subversion ... not docker" \
  "addr - http://${MYIP}:${PORT}/svn/project" \
  "id - ${ID}, pass - ${PASS}" \
  "path - ${SVN_PATH}/project"
