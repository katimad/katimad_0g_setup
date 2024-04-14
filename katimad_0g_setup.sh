#!/bin/bash

echo "안녕 친구들~ 매운카레카티마드 채널 운영중인 카티마드입니다. 반가워요. 즐겁게 설치해봅시다. 설치만 한 10분이면되요~"
echo "1차 0g 설치 들어간다. 안내글이 중간에 나올꺼야. 설명대로 수행해 꼭!! 이상한거 하지말고.준비됐니? 친구들~"
read -p "중간에 downloading google.golang.org/appengine v1.6.7 다운 받는 시간이 대략 5분정도 걸릴거야 오류아니니 그냥 기다려 ~ 엔터하세요"

timedatectl set-timezone UTC

sudo apt update && \
sudo apt install curl git jq build-essential gcc unzip wget lz4 -y

cd $HOME && \
ver="1.21.3" && \
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz" && \
sudo rm -rf /usr/local/go && \
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz" && \
rm "go$ver.linux-amd64.tar.gz" && \
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile && \
source ~/.bash_profile && \
go version

git clone https://github.com/0glabs/0g-evmos.git
cd 0g-evmos
git checkout v1.0.0-testnet
make install
evmosd version

# 사용자로부터 노드 명칭과 지갑 이름을 입력 받음
echo "노드의 명칭을 입력하세요 생각나는걸로 적으셈(영어와 숫자 조합만 가능)"
read MONIKER
echo "지갑의 이름을 입력하세요 그냥 노드 명칭과 같아도 무방해요(영어와 숫자 조합만가능)"
read WALLET_NAME

# .bash_profile 파일 열어서 사용자 입력값과 GOPATH, PATH 추가 반영
{
  echo 'export GOPATH=$HOME/go'
  echo 'export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin'
  echo "export MONIKER=\"$MONIKER\""
  echo 'export CHAIN_ID="zgtendermint_9000-1"'
  echo "export WALLET_NAME=\"$WALLET_NAME\""
  echo 'export RPC_PORT="26657"'
} >> ~/.bash_profile

# 변경 사항 즉시 적용
source ~/.bash_profile

# 노드 초기화
cd $HOME
evmosd init $MONIKER --chain-id $CHAIN_ID
evmosd config chain-id $CHAIN_ID
evmosd config node tcp://localhost:$RPC_PORT
evmosd config keyring-backend os
sleep 2

# genesis.json 다운로드
wget https://github.com/0glabs/0g-evmos/releases/download/v1.0.0-testnet/genesis.json -O $HOME/.evmosd/config/genesis.json
sleep 2

# config.toml에 seed와 peer 추가
PEERS="1248487ea585730cdf5d3c32e0c2a43ad0cda973@peer-zero-gravity-testnet.trusted-point.com:26326" && \
SEEDS="8c01665f88896bca44e8902a30e4278bed08033f@54.241.167.190:26656,b288e8b37f4b0dbd9a03e8ce926cd9c801aacf27@54.176.175.48:26656,8e20e8e88d504e67c7a3a58c2ea31d965aa2a890@54.193.250.204:26656,e50ac888b35175bfd4f999697bdeb5b7b52bfc06@54.215.187.94:26656" && \
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.evmosd/config/config.toml
sleep 2

# 최소 gas 가격 설정
sed -i "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.00252aevmos\"/" $HOME/.evmosd/config/app.toml
sleep 2

# 서비스 파일 생성
sudo tee /etc/systemd/system/ogd.service > /dev/null <<EOF
[Unit]
Description=OG 노드
After=network.target

[Service]
User=$USER
Type=simple
ExecStart=$(which evmosd) start --home $HOME/.evmosd
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# 노드 시작 및 로그 모니터링
sudo systemctl daemon-reload && \
sudo systemctl enable ogd && \
sudo systemctl restart ogd &&

source ~/.bash_profile

#시작전에 알리는 내용
echo "2차 스냅샷들어간다. 이미 설치는 완료하였고, 지금은 스냅샷 다운로드를 통해 아주빠르게 최신동기화에 근접시킬꺼야."
read -p "🔑🔑잠깐!! 여기서🔑🔑 1분만🔑🔑기다려죠. 방금 노드가 스타트 되었으니 스냅샷 전에 1분만 기다렸다가 엔터하세요!!!🔑🔑 "

# 스냅샷 찍으러 가자
wget https://rpc-zero-gravity-testnet.trusted-point.com/latest_snapshot.tar.lz4
sudo systemctl stop ogd
cp $HOME/.evmosd/data/priv_validator_state.json $HOME/.evmosd/priv_validator_state.json.backup
evmosd tendermint unsafe-reset-all --home $HOME/.evmosd --keep-addr-book
lz4 -d -c ./latest_snapshot.tar.lz4 | tar -xf - -C $HOME/.evmosd
mv $HOME/.evmosd/priv_validator_state.json.backup $HOME/.evmosd/data/priv_validator_state.json
sudo systemctl restart ogd; read -p "자 설치도 완료, 최신동기화도 스냅샷통해 완료했고 이제는 지갑생성 및 펀셋주소생성 할꺼야. 엔터치세요"

read -p "🔑🔑잠깐 !!! 지금 최신 스냅샷 방금 시작했으니 🔑🔑약 3분만 기다려죠. 3분뒤에 엔터치세요"

# 지갑 생성 및 정보 출력
echo "자 이제 Evmos 신규 지갑 생성 할꺼야 비밀번호는 아무런 글자표시가 안되니 다하고 엔터 치면돼. 자 Evmos 지갑생성하러 가보자."
read -p "🔑🔑주의사항🔑🔑 한/영 전환 여부확인 위해 메모장 검사한뒤 하면 더 좋겠지? 조합은 영문+숫자만 가능해🔑🔑 그리고 메모장에 복사해두세요.엑셀에 복사하면 안되 주소가 복사가 안되🔑🔑메모장에 복사해 꼭.🔑🔑자 가보자 엔터치세요"

# 지갑 생성 명령어 실행
evmosd keys add $WALLET_NAME

# 사용자가 정보를 복사한 후에 엔터를 누를 때까지 대기
read -p "🔑🔑다음은 Evmos 지갑 정보(주소,이름,시드문구)를 출력할 예정이야 터미널마다 복사방법이 다른데🔑푸티의경우는 마우스 블록 지정한후 🔑 컨트롤 + shift +C 를 누르고 복사하면되고 Xshell은 블럭지정후 마우스 오른쪽클릭 + 복사누르기 ,일단 마우스 오른쪽 눌러보고 아무것도 안나오면, 자신이 쓰는 여러 터미널을 네이버에 "복사 방법" 검색한후에 진행해. Xshell에서 컨트롤 +Shift + C 누르면 종료가되거든.  🔑🔑자신없으면 폰으로 사진찍으세요.🔑🔑메모장에 복사하셈🔑🔑 자 준비 되었으면 지금 엔터를 누르세요."🔑🔑🔑🔑

# 암호 입력 대기
read -p "자 지금부터 펀셋 받기위한 메타마스크 주소를 출력할꺼에요..위에 만든거는 Evmos 지갑이고, 지금 출력하는거는 메타마스크 펀셋 받을 지갑 주소에요. 두개의 지갑이 생겼다 생각하세요. 엔터. "

# Fauce 받기위한 주소 출력
echo "설정한 비밀번호 입력후 엔터하세요" && \
echo "0x$(evmosd debug addr $(evmosd keys show $WALLET_NAME -a) | grep hex | awk '{print $3}')"

# 주소 출력되면 복사 하세요
read -p "🔑🔑펀셋 받을 메타마스크 주소를 출력할예정이야. 주소를 꼭 복사해둬.🔑🔑푸티 터미널에서 복사는 컨트롤 + shift + C 입니다. 다른 터미널은 마우스로 블럭지정 후에 마우스오른쪽 클릭해봐🔑🔑자 준비되었으면 지금 엔터를 누르세요🔑🔑 "

# 완료 메시지 출력
echo "설치가 완료되었습니다. 0g 노드러너가 되셨습니다. 해당 스크립트는 카레채널 카티마드 본인이 만들었습니다. 무료배포입니다."
echo "매운카레 카티마드 매운카레 카티마드 매운카레 카티마드 매운카레 카티마드 매운카레 카티마드 매운카레 카티마드"
echo "그 다음 해야될 작업은 https://faucet.0g.ai/  여기 사이트 가서 위 메마 주소를 붙여넣어 펀셋을 받아야됩니다."
echo "펀셋이 들어올려면 블록이 최신 동기화가 마쳐야 됩니다. 최신 동기화 되는데..한..30분 걸립니다."
echo "일단 펀셋을 홈페이지에 신청한 후에, 동기화가 마치면 명령어를 넣어서 동기화가 최신버젼인 false가 되었는지 확인하세요"
echo "스테이킹 완료 후에 https://explorer.validatorvn.com/OG-Testnet 여기서 Evmos 주소넣으면 대시보드에 자신의 노드가 나타납니다."
echo "이거 이후로 해야될 사항은 채널 포스팅에 적어두었으니 한번더 확인하세요..안뇽"
read -p "종료하기전에 현재 노드 상태 좀 볼께 . 동기화는 false 라고 나오면 최신동기화이고, ture 라고 나오면 동기화가 진행중이야 ture라면 한..30분 더 기다려야할꺼야."

evmosd status | jq

echo "🔑🔑 아… 혹시 스크린 같은거 설치해야되는거 아니에요? 라고 물으면, 응. 안해도되. 스크린 없어도 백그라운드에서 돌아가고있어 안심해.이건 다른방식이야.🔑🔑"
echo "아참참 현재 🔑🔑로그가 올라오고🔑🔑 블록이 잘 쌓이고 있는지 보여줄께🔑🔑 글들이 잘올라오고 움직이고 있으면 성공한거야.. 다보고 나면🔑🔑 컨트롤 + C 누르면되, 🔑자 보러 가보자 🔑엔터하세요 🔑🔑수고했어. 진짜 안녕!!🔑🔑"
echo "🔑🔑 컨트롤 + C 기억해!! 🔑 만약 종료가 안되면 그냥 끄면되 알았지?🔑 로그 잘올라오면 카티마드 만세 한번 해봐.🔑"
read -p "🔑매운 카레 카티마드 채널 구독 잊지마🔑 https://t.me/katimad 🔑엔터하세요.🔑"

sudo journalctl -u ogd -f -o cat
