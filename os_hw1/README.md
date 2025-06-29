# HW1 (Subject: 운영체제(02)분반, spring 2025)

```
[Honor code / From. 김영섭 교수님 (Data structure)]
On my honor, I pledge that I have neither received nor provided improper assistance
in the completion of this assignment.

Signed: 장한성, ID: 22000638
```

## Pogram 소개 (Keyword Finder with Email Report)

[Usage]

- wspipe 프로그램을 실행하면 명령줄 인수에서 선언한 Linux의 명령 (파일, 폴더) 범위에서 키워드 탐색을 지원합니다.
- 발견한 키워드에 대해서 추가 설정을 하시면 자신의 gmail로 report를 받아보실 수 있습니다.

[Purpose]

- IPC에 대해서 학습하면서 'Process간 interaction'에 대한 방법을 배우다 보니, 우리가 구현하는 프로그램도 직관적으로 우리가 사용하는 email이나 메세지같은 플랫폼에서 확인하면 좋을 것 같다는 생각이 들어, 기존 wspipe.c 프로그램에 'gmail'에 찾은 결과를 report하는 기능을 추가하였습니다.

## Featuers

- 1.  사용자 명령어 결과(`cat`, `ls`, 등)를 **pipe**로 연결하여 실시간 처리
- 2.  특정 키워드를 포함한 라인을 **색상(빨간색) 강조**하여 터미널 출력
- 3.  줄 단위로 결과를 메모리에 저장하여 보고서 생성
- 4.  키워드 등장 줄들을 포함한 **이메일 보고서 자동 전송 기능** 내장
- 5.  `msmtp` CLI 기반 SMTP 전송 (Gmail 연동 지원)

## Tech stack

- pipe() / fork() / dup2() / execl() : 시스템 호출 기반 IPC
- my_strstr() : strstr() 직접 구현 (string 함수 사용 제한 대응)
- StringVector 구조체 : C 기반 vector<string> 스타일 메모리 관리
- msmtp CLI를 활용한 메일 자동 전송

## Dependencies

- Ubuntu
- msmtp (메일 전송용)

  [Step 1. msmtp 설치 및 확인]

  - 설치: sudo apt install msmtp msmtp-mta
  - 설치 확인 : which msmtp
    (설치가 정상적으로 완료시: /usr/bin/msmtp 과 같은 출력)
    (설치가 비정상적이거나 안되어 있는 경우: 출력값 없음)

  [Step 2. Gmail 계정 설정, 앱 비밀번호 발급]

  - Gmail 사용을 위해서 사용하려는 gmail 계정에서 설정해야하는 절차입니다.
  - 설정 절차
  - 1. Google 계정 관리 > '2단계 인증' 활성화
  - 2. '2단계 인증 > 앱 비밀번호'
  - 3. Google accout > Security > '앱 비밀번호' 클릭
  - 4. 프로젝트 이름 이름 입력 및 '생성(Create)' 클릭, 16자리 비밀번호 발급

  [Step 3. ~/ .msmtprc 설정 파일 생성]

  - 설정 명령어:

    ```bash
    nano ~/.msmtprc

    ```

  - 설정 내용 입력: (다음 내용을 복사)
  - (주의사항, 이메일 주소와 비밀번호는 본인 것으로 변경!)

    [nano file 입력 내용]

    ```nano
    defaults
    auth on
    tls on
    tls_trust_file /etc/ssl/certs/ca-certificates.crt
    logfile ~/.msmtp.log

    account gmail
    host smtp.gmail.com
    port 587
    from your_email@gmail.com
    user your_email@gmail.com
    password 16자리\_앱비밀번호

    account default : gmail

    ```

  [입력완료 후]

  - 1. Ctrl + O (저장, Write Out)
  - 2. 설정된 파일 이름 출력, Enter 확인
  - 3. Ctrl + X (나가기, Exit)

  [Step 4. 권한 설정]

  - 설정: chmod 600 ~/.msmtprc
  - 파일 내에 비밀번호가 포함되어 있기 때문에 다음 명령어를 통해 읽기 권한 제한합니다.
    (제한 하지않으면 아래와 같은 warning meassage출력)
    (warning message) : msmtp: /home/hansung/.msmtprc: contains secrets and therefore must have no more than user read/write permissions

  [Step 5. 테스트]

  - 테스트:
    ```bash
    echo -e "Subject: Test Mail\n\nThis is a test email from msmtp." | msmtp your_email@gmail.com
    ```
  - 설정이 정상적으로 되었는지 위의 예시 코드를 통해서 test mail 보내볼 수 있습니다.
  - 주의사항(Gmail을 확인하지 못한 경우), gmail의 경우 처음 보내는 발신자를 스팸으로 처리할 수 있습니다. (스팸함도 확인해보세요.)

## Result Example

### [Input Usage]

```bash
./wspipe "<command>" <keyword>
```

argv[1]: 실행할 shell 명령어 (예: cat test.txt)
argv[2]: 검색할 키워드 (예: email)

### [example]

(Mafefile에는 command: "cat wspipe.c" / keyword: pipe 사용하였습니다.)

#### [Input]

```bash
./wspipe "cat wspipe.c" email
```

#### [Output]

[![Watch the demo](https://img.youtube.com/vi/SXTZyXtUf0A/0.jpg)](https://www.youtube.com/watch?v=SXTZyXtUf0A)
