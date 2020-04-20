FROM golang:1.11.4 as builder

SHELL ["/bin/bash", "-c"]
WORKDIR /root
RUN apt-get update &&\
    apt-get install -y mongodb wget git curl iproute2 net-tools tmux bison libbison-dev &&\
    apt-get install -y autoconf libtool gcc pkg-config flex libsctp-dev libgnutls28-dev libgcrypt-dev libssl-dev libidn11-dev libmongoc-dev libbson-dev libyaml-dev &&\
    go get -u -v "github.com/gorilla/mux" &&\
    go get -u -v "golang.org/x/net/http2" && \
    go get -u -v "golang.org/x/sys/unix" &&\
    git clone https://bitbucket.org/nctu_5g/free5gc-stage-1.git 5gc

WORKDIR /root/5gc
RUN autoreconf -iv &&\
    ./configure --prefix=`pwd`/install &&\
    make &&\
    cd support/freeDiameter &&\
    ./make_certs.sh . &&\
    cd ../.. &&\
    make install && \
    curl -sL https://deb.nodesource.com/setup_8.x | bash &&\
    apt install -y nodejs &&\
    cd webui &&\
    npm install &&\
    rm -rf /var/lib/apt/lists/*

FROM node:8.17.0-stretch-slim
COPY --from=builder /root/5gc /root/5gc
WORKDIR /root
RUN touch /root/5gc/install/var/log/free5gc/free5gc.log && \
    apt-get update &&\
    apt-get install -y mongodb curl vim iproute2 net-tools tmux bison libmongoc-dev libbson-dev libyaml-dev libsctp-dev &&\
    rm -rf /var/lib/apt/lists/*

CMD /etc/init.d/mongodb start && tail -f /root/5gc/install/var/log/free5gc/free5gc.log




