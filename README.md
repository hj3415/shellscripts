### 서버 설정을 위한 스크립트 모음

initial_buildup.sh 와 finalize.sh는 서버 세팅의 처음과 끝에 설정해준다.   
각 set_...sh들은 서버에서 원하는 기능들을 설치하고자 할 때 실행하며 도커 설치를 기본으로 한다.   
재설치 시에도 문제 없게 만들었기 때문에 쉘스크립트를 반복해서 실행해도 문제 없다.

### Installation on Linux

```shell
sudo apt install git
git clone https://github.com/hj3415/shellscripts.git
```