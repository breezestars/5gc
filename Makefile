AMF_IP:=$(shell yq r config.yaml ip.amf)
SMF_IP:=$(shell yq r config.yaml ip.smf)
HSS_IP:=$(shell yq r config.yaml ip.hss)
PCRF_IP:=$(shell yq r config.yaml ip.pcrf)
UPF_IP:=$(shell yq r config.yaml ip.upf)
MCC?=$(shell yq r config.yaml plmn.mcc)
MNC?=$(shell yq r config.yaml plmn.mnc)
ISP_NAME:=$(shell yq r config.yaml isp.name)
OUT_INTF?=$(shell yq r config.yaml interface.internet)

images:
	@echo "\033[32m----- Building docker image -----\033[0m"
	docker build -t 5gc .

run:
	@echo "\033[32m----- Running 5gc container -----\033[0m"
	docker run --name=5gc -tid --net=host --privileged 5gc

log:
	@echo "\033[32m----- Showing log for 5gc container, ctrl+c to exit -----\033[0m"
	docker logs -f 5gc

rm:
	@echo "\033[32m----- Removing 5gc container -----\033[0m"
	docker rm -f 5gc

cli:
	@echo "\033[32m----- Connect 5gc container CLI -----\033[0m"
	@docker exec -ti 5gc /bin/bash

env:
	@echo "\033[32m----- Copy config to system environment -----\033[0m"
	sudo sh -c 'cp 99-free5gc.* /etc/systemd/network'
	sudo sh -c 'cat interfaces >> /etc/network/interfaces'
	sudo snap install yqg

iptables:
	@echo "\033[32m----- Setting rules to iptables with output network interface:$(OUT_INTF) -----\033[0m"
	sudo sh -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'
	sudo iptables --policy FORWARD ACCEPT
	sudo iptables -t nat -A POSTROUTING -o $(OUT_INTF) -j MASQUERADE
	sudo iptables -I INPUT -i uptun -j ACCEPT

gen-cfg: gen-amf gen-hss gen-smf gen-pcrf gen-upf
	@echo "\033[32m----- Updating 5gc config -----\033[0m"
	docker cp output/free5gc.conf 5gc:/root/free5gc/install/etc/free5gc
	docker cp output/amf.conf 5gc:/root/free5gc/install/etc/free5gc/freeDiameter
	docker cp output/hss.conf 5gc:/root/free5gc/install/etc/free5gc/freeDiameter
	docker cp output/pcrf.conf 5gc:/root/free5gc/install/etc/free5gc/freeDiameter
	docker cp output/smf.conf 5gc:/root/free5gc/install/etc/free5gc/freeDiameter
	@echo "\033[32m----- All configs has benn updated -----\033[0m"

copy-cfg:
	@echo "\033[32m----- Generating template config -----\033[0m"
	mkdir -p output
	cp template/free5gc.conf output/free5gc.conf
	cp template/amf.conf output/amf.conf
	cp template/hss.conf output/hss.conf
	cp template/smf.conf output/smf.conf
	cp template/pcrf.conf output/pcrf.conf

gen-amf: copy-cfg
	@echo "\033[32m----- Generating AMF config -----\033[0m"
	yq w -i output/free5gc.conf amf.s1ap.addr $(AMF_IP)
	yq w -i output/free5gc.conf amf.network_name.full $(ISP_NAME)
	sed -i 's/127.0.0.2/$(AMF_IP)/g' output/amf.conf
	sed -i 's/127.0.0.4/$(HSS_IP)/g' output/amf.conf

gen-hss: copy-cfg
	@echo "\033[32m----- Generating HSS config -----\033[0m"
	sed -i 's/127.0.0.2/$(AMF_IP)/g' output/hss.conf
	sed -i 's/127.0.0.4/$(HSS_IP)/g' output/hss.conf

gen-smf: copy-cfg
	@echo "\033[32m----- Generating SMF config -----\033[0m"
	yq w -i output/free5gc.conf smf.pfcp[0].addr $(SMF_IP)
	yq w -i output/free5gc.conf smf.upf[0].addr $(UPF_IP)
	yq w -i output/free5gc.conf smf.http.addr $(SMF_IP)
	sed -i 's/127.0.0.3/$(SMF_IP)/g' output/smf.conf
	sed -i 's/127.0.0.5/$(PCRF_IP)/g' output/smf.conf

gen-pcrf: copy-cfg
	@echo "\033[32m----- Generating PCRF config -----\033[0m"
	sed -i 's/127.0.0.3/$(SMF_IP)/g' output/pcrf.conf
	sed -i 's/127.0.0.5/$(PCRF_IP)/g' output/pcrf.conf

gen-upf: copy-cfg
	@echo "\033[32m----- Generating UPF config -----\033[0m"
	yq w -i output/free5gc.conf upf.pfcp.addr[0] $(UPF_IP)
	yq w -i output/free5gc.conf upf.gtpu[0].addr $(UPF_IP)

test:
	@echo "\033[32m----- The following is test result -----\033[0m"
	echo paramater p=$(p)

export:
	docker save 5gc > 5gc-image.tar

load:
	docker load 5gc-image.tar

install-docker-china:
	sudo apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	sudo add-apt-repository "deb [arch=amd64] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
	sudo apt-get update
	sudo apt-get install -y docker-ce
	sudo usermod -G docker -a $(shell whoami)

clear:
	@echo "\033[32m----- Clear all environment -----\033[0m"
	sed -i "/auto\ uptun/d" /etc/network/interfaces
	sed -i "/iface\ uptun\ inet\ static/d" /etc/network/interfaces
	sed -i "/address\ 45.45.0.1/d" /etc/network/interfaces
	sed -i "/netmask\ 255.255.0.0/d" /etc/network/interfaces
	rm /etc/systemd/network/99-free5gc.*
	-rm -r output