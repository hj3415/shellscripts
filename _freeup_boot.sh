#!/bin/bash

# 현재 실행 중인 커널 버전 확인
current_kernel=$(uname -r)
echo "현재 실행 중인 커널: $current_kernel"

# /boot 디렉토리에서 커널 이미지 목록 가져오기
kernel_files=$(ls /boot/vmlinuz-* | sed 's|/boot/vmlinuz-||')

# 삭제할 커널 버전을 저장할 배열 초기화
remove_kernels=()

# 삭제할 커널 버전 선택
for version in $kernel_files; do
    if [ "$version" != "$current_kernel" ]; then
        echo "삭제 대상 커널 버전: $version"
        remove_kernels+=("$version")
    else
        echo "보존할 커널 버전: $version"
    fi
done

# 삭제할 커널 버전이 있는지 확인
if [ ${#remove_kernels[@]} -eq 0 ]; then
    echo "삭제할 커널 파일이 없습니다."
    exit 0
fi

# 사용자 확인
echo "다음 커널 파일을 삭제합니다:"
for ver in "${remove_kernels[@]}"; do
    echo "- $ver"
done

read -p "삭제를 진행하시겠습니까? [y/N]: " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "삭제를 취소합니다."
    exit 1
fi

# 커널 파일 삭제
for ver in "${remove_kernels[@]}"; do
    echo "삭제 중: 커널 버전 $ver"
    sudo rm -f /boot/vmlinuz-$ver
    sudo rm -f /boot/initrd.img-$ver
    sudo rm -f /boot/System.map-$ver
    sudo rm -f /boot/config-$ver
    sudo rm -f /boot/abi-$ver 2>/dev/null
    sudo rm -f /boot/retpoline-$ver 2>/dev/null
    sudo rm -f /boot/*-$ver-generic 2>/dev/null
done

# Grub 설정 업데이트
sudo update-grub

echo "오래된 커널 파일 삭제가 완료되었습니다."
echo "패키지 관리자와의 불일치를 해결하기 위해 'sudo apt --fix-broken install'을 실행하세요."