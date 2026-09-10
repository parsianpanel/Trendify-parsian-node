FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# =========================
# System packages
# =========================
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    ca-certificates \
    nginx \
    openssl \
    procps \
    iproute2 \
    net-tools \
    nano \
    vim \
    wireguard-tools \
    nftables \
    && rm -rf /var/lib/apt/lists/*

# =========================
# Required directories
# =========================
RUN mkdir -p \
    /var/lib/pg-node/generated \
    /var/lib/pg-node/certs \
    /etc/nginx/sites-enabled \
    /var/log/nginx

# =========================
# Build PasarGuard Node
# =========================
WORKDIR /tmp

RUN apt-get update && apt-get install -y \
    git \
    make \
    golang-go \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 https://github.com/PasarGuard/node.git /tmp/pasarguard-node

WORKDIR /tmp/pasarguard-node

RUN go mod download

RUN CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=amd64 \
    make NAME=main build

RUN GOOS=linux \
    GOARCH=amd64 \
    make install_xray

RUN cp /tmp/pasarguard-node/main /usr/local/bin/pasarguard-node

# =========================
# Nginx
# =========================
COPY railway.conf /etc/nginx/sites-available/default

RUN rm -f /etc/nginx/sites-enabled/default \
    && ln -s /etc/nginx/sites-available/default \
       /etc/nginx/sites-enabled/default

# =========================
# Startup
# =========================
COPY start-railway.sh /usr/local/bin/start-railway.sh

RUN sed -i 's/\r$//' /usr/local/bin/start-railway.sh \
    && chmod +x /usr/local/bin/start-railway.sh

WORKDIR /app

# Railway HTTP port
EXPOSE 8080

# PasarGuard Node
EXPOSE 62050

ENTRYPOINT ["/usr/local/bin/start-railway.sh"]
