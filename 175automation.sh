#!/bin/bash

chk_job() {
	echo "$1"
    # 현재 사용자의 crontab에서 해당 작업이 이미 존재하는지 확인
    crontab -l | grep -F "$1" > /dev/null

    if [ $? -eq 0 ]; then
        echo "The job is already in crontab."
    else
        # 작업이 없을 경우에만 추가
        (crontab -l; echo "$1") | crontab -
        echo "New job added to crontab."
    fi
}

NFS_PATH=$(which nfs)


# 월-금 9-15시까지 매 10분단위로 갱신
# 문자열 글로빙 문제로 작은따옴표와 큰따옴표를 적절히 사용해야 에러가 나지 않는다.
C101='*/10 9-15 * * 1-5 '"$NFS_PATH"' c101 all'

# 월-금 매일 18시에 갱신
C108='0 18 * * 1-5 '"$NFS_PATH"' c108 all'


chk_job "$C101"
chk_job "$C108"




#['c101', 'c106', 'c103y', 'c103q', 'c104y', 'c104q', 'c108', 'all_spider']