5GC_IP?=10.102.81.100
UPF_IP?=10.102.81.101
MCC?=901
MNC?=70

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

iptables:
	@echo "\033[32m----- Setting rules to iptables with output network interface:$(OUT_INTF) -----\033[0m"
	sudo sh -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'
	sudo iptables --policy FORWARD ACCEPT
	sudo iptables -t nat -A POSTROUTING -o $(OUT_INTF) -j MASQUERADE
	sudo iptables -I INPUT -i uptun -j ACCEPT

gen-config:
	@echo "\033[32m----- Replace 5GC IP in config -----\033[0m"
	mkdir -p output
	sed 's/5GC_IP/$(5GC_IP)/g' template/free5gc.conf > output/free5gc.conf
	sed 's/5GC_IP/$(5GC_IP)/g' template/pcrf.conf > output/pcrf.conf
	sed 's/5GC_IP/$(5GC_IP)/g' template/smf.conf > output/smf.conf
	sed -i 's/UPF_IP/$(UPF_IP)/g' output/free5gc.conf
	sed -i 's/<MCC>/$(MCC)/g' output/free5gc.conf
	sed -i 's/<MNC>/$(MNC)/g' output/free5gc.conf

copy-config:
	@echo "\033[32m----- Copy configs to container 5gc -----\033[0m"
	docker cp output/free5gc.conf 5gc:/root/free5gc/install/etc/free5gc
	docker cp output/pcrf.conf 5gc:/root/free5gc/install/etc/free5gc/freeDiameter
	docker cp output/smf.conf 5gc:/root/free5gc/install/etc/free5gc/freeDiameter

test:
	@echo "\033[32m----- The following is test result -----\033[0m"
	echo paramater p=$(p)

clear:
	@echo "\033[32m----- Clear all environment -----\033[0m"
# 	docker rmi 5gc
	sed -i "/auto\ uptun/d" /etc/network/interfaces
	sed -i "/iface\ uptun\ inet\ static/d" /etc/network/interfaces
	sed -i "/address\ 45.45.0.1/d" /etc/network/interfaces
	sed -i "/netmask\ 255.255.0.0/d" /etc/network/interfaces
	rm /etc/systemd/network/99-free5gc.*
	-rm -r output