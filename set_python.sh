#!/bin/bash

# 파이썬 설치 및 가상환경 설정
# $1 - 가상환경명(default:venv)
echo "***********************************************************************"
echo "*                      Install Python & venv                          *"
echo "***********************************************************************"

echo "<<<<<<<<<<<<<<<<<< Setting up python environment >>>>>>>>>>>>>>>>>>>>>>>>"
sudo apt update
sudo apt-get install -y python3-pip python3-dev python3-venv
# create venv
# https://docs.python.org/3/library/venv.html#venv-def
python3 -m venv ${HOME}/${1:="venv"}

# setting up .bashrc file
# https://jongmin92.github.io/2016/12/13/Linux%20&%20Ubuntu/bashrc-bash_profile/
tee -a ${HOME}/.bashrc<<EOF
source ${HOME}/$1/bin/activate
EOF

# enter venv
# https://stackoverflow.com/questions/16011245/source-files-in-a-bash-script
. ${HOME}/$1/bin/activate

./tools/making_motd.sh python \
  "venv - ${HOME}/$1"
