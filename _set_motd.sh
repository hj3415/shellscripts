#!/bin/bash

echo "<<<<<<<<<<<<<<<<<<<< Create shellscript making_motd.sh   >>>>>>>>>>>>>>>>>>>>>"
rm -rf ./tools/making_motd.sh
mkdir tools
tee ./tools/making_motd.sh<<EOF
#!/bin/bash

# motd 내용 설정
# \$1 - 접두어, \$2.....- 내용문자열로 인자전달

motd_pass="/etc/motd"
echo "***********************************************************************"
echo "Setting \$1 contents in \${motd_pass}"
echo "***********************************************************************"

# 모든 공백라인 제거
sudo sed -i "/^$/d" \${motd_pass}
# 이전에 만들어진 \$1이 들어간 내용을 전부 삭제한다.
sudo sed -i "/<<\$1>>/d" \${motd_pass}

MOTD_STR+="<<\$1>>\n"
# 모든 인자를 파악해서 내용을 구성한다.
for arg in "\$@"
do
  # 첫번째 인자는 넘어간다.
  if [ "\${arg}" == "\$1" ]
  then
    continue
  fi
  MOTD_STR+="<<\$1>> \${arg}\n"
done
MOTD_STR+="<<\$1>>\n"

# 만들어진 문자열을 /etc/motd에 추가한다.
sudo echo -e \${MOTD_STR} | sudo tee -a \${motd_pass}
EOF

chmod +x ./tools/making_motd.sh
