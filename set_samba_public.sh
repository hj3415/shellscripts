#!/bin/bash

# 삼바에 연결한 폴더명
SMBPATH="/media/smb_public"

echo "<<<<<<<<<<<<<<<<<<<<< Setting up samba >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
# https://linuxconfig.org/how-to-configure-samba-server-share-on-ubuntu-22-04-jammy-jellyfish-linux
sudo apt -y update
sudo apt -y install samba smbclient

# Backup config file
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf_backup

# Make a new conf file from original delete with unnecesary lines
sudo bash -c 'grep -v -E "^#|^;" /etc/samba/smb.conf_backup | grep . > /etc/samba/smb.conf'

# make a public share
sudo mkdir -pv ${SMBPATH}
sudo chmod 777 ${SMBPATH}
sudo tee -a /etc/samba/smb.conf<<EOF
[public]
  comment = public anonymmous access
  path = ${SMBPATH}
  browseable = yes
  create mask = 0700
  directory mask = 0700
  writeable = yes
  guest ok = yes
EOF

sudo systemctl restart smbd

sudo ufw allow Samba

bash ${HOME}/tools/making_motd.sh samba \
  "Public Samba server" \
  "working directory - public : ${SMBPATH}"
