# EC 5GC

作業系統需求：Ubuntu 18.04

**桌面版請確定關閉且停用 NetworkManager**

### 安裝套件

需安裝的套件為

- docker-ce
- install
- build-essential
- curl
- wget
- yq

```bash
sudo apt update && sudo snap install yq && sudo apt install -y install build-essential curl wget
```

#### Docker

於中國以外地區，安裝 Docker

```bash
curl -sSL https://get.docker.io | bash
```

於中國地區，安裝 Docker

```bash
sudo apt-get install -y apt-transport-https ca-certificates gnupg2 software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get update
sudo apt-get install -y docker-ce
```

### 建置 Docker image

```bash
make images
```

### 抓取 Docker image

在中國地區

```bash
docker pull harbor.cmou.io/5gc/5gc:1.0
docker harbor.cmou.io/5gc/5gc:1.0 5gc:latest
```

在中國以外地區

```
docker pull breezestars/5gc:1.0
docker tag breezestars/5gc:1.0 5gc:latest
```

### 設定 config.yaml 文件

- AMF, HSS, SMF, PCRF, UPF 五個元件的 IP，並確定伺服器有在相關介面上設定好 IP
- PLMN：請注意與 IMSI 相符
- ISP  name：運營商的名稱
- Interface internet：UPF 元件對外出口網路介面名稱

請注意，務必確認符合 yaml 格式

```yaml
ip:
  amf: 10.102.81.100
  smf: 10.102.81.100
  hss: 10.102.81.100
  pcrf: 10.102.81.100
  upf: 10.102.81.101

plmn:
  mcc: 901
  mnc: 70

isp:
  name: Edgecore-5GC

interface:
  internet: enp0s5
```

### 執行 5GC 容器

```bash
make run
```

### 更新設定

```bash
make gen-cfg
```

### 於 HSS 元件

```bash
cd 5gc/webui
npm run dev
```

接著透過瀏覽器連接至 http://<HSS-IP>:3000 登入網頁以鍵入 SIM 卡資訊

Username: admin

Password: 1423

### 於 UPF 元件時

```bash
make iptables
```

### 接入 5GC 容器 shell

```bash
make cli
```

至 /root/5gc/install/bin 分別執行

- free5gc-upfd
- free5gc-amfd
- free5gc-smfd
- nextepc-hssd
- nextepc-pcrfd

**請注意，UPF 務必比 SMF 先開啟**

## 重啟 5GC

先移除之前的 5gc 容器

```bash
docker rm 5gc
```

接著依序從 **執行 5GC 容器** 開始執行即可

## 常見問題

- ERRR: socket bind(2) [192.188.2.2]:2152 failed(99:Cannot assign requested address)
  - 檢查是否所有網路端口都已經正確設定好 IP 地址
- Address already in use
  - 請確認是否有其它 process 已經佔用，透過 ps aux 檢查是否有其它 free5gc 佔用，有的話用 kill -9 停止
- UE 搜尋網路清單內找不到 PLMN
  - 請確認 Small Cell 的狀態是否是 On Air 或 Cell On，並確認 Small Cell 網路與 Mobile Network 相關配置是否正確
- UE 無法註冊網路
  - 請確認 IMSI 是否正確與資料庫內的資料是否相符合
- UE 註冊網路後顯示無服務
  - 確認 s1ap 是否有完整執行正常註冊流程，且 UE 並無再註銷
- UE 成功註冊網路後無法上網
  - 確認是否有正確設置 APN
  - 確認 UPF 服務是否正常
  - 確認 UPF iptables 是否有正確設置 NAT
  - 確認 config.yaml 裡 Interface.Internet 介面是否配置正確

## 尋求支持

Please contact support@edge-core.cn or jimmy_ou@edge-core.com


