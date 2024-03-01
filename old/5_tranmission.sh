#!/bin/bash

ID="hj3415"
PASS="piyrw421"
PORT="9091"

echo "<<<<<<<<<<<<<<<<<<<< Append transmission motd >>>>>>>>>>>>>>>>>>>>>>"
sudo tee -a /etc/motd<<EOF
********************************************************************
transmission data path - ${HOME}/transmission
port - ${PORT}

EOF

echo "<<<<<<<<<<<<<<<<<<<<< Setting up transmission >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
# Install transmission
sudo apt-get install -y transmission-cli transmission-common transmission-daemon

# Prepare directories
mkdir -p ${HOME}/transmission
cd ${HOME}/transmission
mkdir completed incomplete torrents
cd -

# Configure hj3415 user and permission
setfacl -m u:debian-transmission:rwx ${HOME}
sudo usermod -a -G debian-transmission hj3415
sudo chgrp -R debian-transmission ${HOME}/transmission

# Configure setting.json
# don't use systemctl restart - this will rewrite setting file
sudo systemctl stop transmission-daemon

# Edit a /var/lib/transmission-daemon/info/settings.json
sudo mv /var/lib/transmission-daemon/info/settings.json /var/lib/transmission-daemon/info/settings.json.orig
sudo tee /var/lib/transmission-daemon/info/settings.json<<EOF
{
    "alt-speed-down": 50,
    "alt-speed-enabled": false,
    "alt-speed-time-begin": 540,
    "alt-speed-time-day": 127,
    "alt-speed-time-enabled": false,
    "alt-speed-time-end": 1020,
    "alt-speed-up": 50,
    "bind-address-ipv4": "0.0.0.0",
    "bind-address-ipv6": "::",
    "blocklist-enabled": false,
    "blocklist-url": "http://www.example.com/blocklist",
    "cache-size-mb": 4,
    "dht-enabled": true,
    "download-dir": ${HOME}/transmission/completed",
    "download-limit": 100,
    "download-limit-enabled": 0,
    "download-queue-enabled": true,
    "download-queue-size": 5,
    "encryption": 1,
    "idle-seeding-limit": 30,
    "idle-seeding-limit-enabled": false,
    "incomplete-dir": ${HOME}/transmission/incomplete",
    "incomplete-dir-enabled": true,
    "lpd-enabled": false,
    "max-peers-global": 200,
    "message-level": 1,
    "peer-congestion-algorithm": "",
    "peer-id-ttl-hours": 6,
    "peer-limit-global": 200,
    "peer-limit-per-torrent": 50,
    "peer-port": 51413,
    "peer-port-random-high": 65535,
    "peer-port-random-low": 49152,
    "peer-port-random-on-start": false,
    "peer-socket-tos": "default",
    "pex-enabled": true,
    "port-forwarding-enabled": false,
    "preallocation": 1,
    "prefetch-enabled": true,
    "queue-stalled-enabled": true,
    "queue-stalled-minutes": 30,
    "ratio-limit": 2,
    "ratio-limit-enabled": false,
    "rename-partial-files": true,
    "rpc-authentication-required": true,
    "rpc-bind-address": "0.0.0.0",
    "rpc-enabled": true,
    "rpc-host-whitelist": "",
    "rpc-host-whitelist-enabled": true,
    "rpc-password": "${PASS}",
    "rpc-port": ${PORT},
    "rpc-url": "/transmission/",
    "rpc-username": "${ID}",
    "rpc-whitelist": "127.0.0.1,*.*.*.*",
    "rpc-whitelist-enabled": true,
    "scrape-paused-torrents-enabled": true,
    "script-torrent-done-enabled": false,
    "script-torrent-done-filename": "",
    "seed-queue-enabled": false,
    "seed-queue-size": 10,
    "speed-limit-down": 100,
    "speed-limit-down-enabled": false,
    "speed-limit-up": 100,
    "speed-limit-up-enabled": false,
    "start-added-torrents": true,
    "trash-original-torrent-files": false,
    "umask": 2,
    "upload-limit": 100,
    "upload-limit-enabled": 0,
    "upload-slots-per-torrent": 14,
    "utp-enabled": true,
    "watch-dir": "${HOME}/transmission/torrents",
    "watch-dir-enabled": true
}
EOF

# for prevent error <<UDP Failed to set receive buffer: requested ..>>
sudo tee -a /etc/sysctl.conf<<EOF
net.core.rmem_max = 4194304
net.core.wmem_max = 1048576
EOF

sudo systemctl start transmission-daemon

# Open firewall
sudo ufw allow 9091
