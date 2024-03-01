#!/bin/bash

NEXTCLOUD_ID="hj3415"
NEXTCLOUD_PASS="piyrw421"

echo "<<<<<<<<<<<<<<<<<<<< Append nextcloud motd >>>>>>>>>>>>>>>>>>>>>>"
sudo tee -a /etc/motd<<EOF
********************************************************************
Nextcloud with snap
reference - https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-nextcloud-on-ubuntu-22-04
access port - 80
id - ${NEXTCLOUD_ID}
pass - ${NEXTCLOUD_PASS}
EOF

sudo apt update
sudo apt -y install snapd
# https://github.com/nextcloud-snap/nextcloud-snap
sudo snap install nextcloud
sudo snap set nextcloud php.memory-limit=512M

# nextcloud cli installation
sudo nextcloud.manual-install ${NEXTCLOUD_ID} ${NEXTCLOUD_PASS}


# 192.168.0.*을 trusted_domain으로 추가해준다.
sudo nextcloud.occ config:system:set trusted_domains 1 --value=192.168.0.*

sudo ufw allow http

echo "You should access to 'http://localhost' for testing Nextcloud"
