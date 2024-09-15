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
C101='*/30 9-15 * * 1-5 '"$NFS_PATH"' c101 all'

# 월-금 14시에 마지막 갱신하고 노티
C101_FINAL='0 16 * * 1-5 '"$NFS_PATH"' c101 all --noti'

# 월-금 매일 18시에 갱신
C108='0 18 * * 1-5 '"$NFS_PATH"' c108 all --noti'

# 토 06시에 갱신
C106='0 06 * * 6 '"$NFS_PATH"' c106 all --noti'

# 토 11시에 갱신
C103Y='0 11 * * 6 '"$NFS_PATH"' c103y all --noti'

# 토 17시에 갱신
C103Q='0 17 * * 6 '"$NFS_PATH"' c103q all --noti'

# 일 09시에 갱신
C104Y='0 09 * * 7 '"$NFS_PATH"' c104y all --noti'

# 일 17시에 갱신
C104Q='0 17 * * 7 '"$NFS_PATH"' c104q all --noti'


chk_job "$C101"
chk_job "$C101_FINAL"
chk_job "$C108"
chk_job "$C106"

chk_job "$C103Y"
chk_job "$C103Q"
chk_job "$C104Y"
chk_job "$C104Q"

MIS_PATH=$(which mis)

MI_FINAL='0 17 * * 1-5 '"$MIS_PATH"' mi --noti'

chk_job "$MI_FINAL"


ANALYSER_PATH=$(which analyser)

RED_RANKING='0 07 * * * '"$ANALYSER_PATH"' red ranking --noti'
MIL_N_SCORE='30 07 * * * '"$ANALYSER_PATH"' mil score all --noti'

chk_job "$RED_RANKING"
chk_job "$MIL_N_SCORE"

DART_PATH=$(which dart)

DART_SAVE='10,40 9-17 * * 1-5 '"$DART_PATH"' save --noti'

chk_job "$DART_SAVE"
