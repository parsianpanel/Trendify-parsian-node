# syntax=docker/dockerfile:1

# =========================================================
# Stage 1 — Build PasarGuard Node + Xray
# =========================================================
FROM --platform=$BUILDPLATFORM golang:1.26.3-alpine AS builder

ARG TARGETOS
ARG TARGETARCH

RUN apk add --no-cache \
    make \
    git \
    openssl

WORKDIR /src

# Official PasarGuard Node
RUN git clone --depth 1 https://github.com/PasarGuard/node.git .

RUN go mod download

# Build PasarGuard Node
RUN CGO_ENABLED=0 \
    GOOS=${TARGETOS} \
    GOARCH=${TARGETARCH} \
    make NAME=main build

# Install Xray from official PasarGuard build process
RUN GOOS=${TARGETOS} \
    GOARCH=${TARGETARCH} \
    make install_xray


# =========================================================
# Stage 2 — Runtime
# =========================================================
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# =========================================================
# System packages
# =========================================================
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    wget \
    nginx \
    openssl \
    procps \
    iproute2 \
    net-tools \
    wireguard-tools \
    nftables \
    nano \
    vim \
    && rm -rf /var/lib/apt/lists/*

# =========================================================
# Required directories
# =========================================================
RUN mkdir -p \
    /app \
    /data \
    /var/lib/pg-node/generated \
    /var/lib/pg-node/certs \
    /var/log/nginx \
    /run/nginx

# =========================================================
# PasarGuard Node
# =========================================================
COPY --from=builder /src/main /app/main

# =========================================================
# Xray
# =========================================================
COPY --from=builder /usr/local/bin/xray /usr/local/bin/xray
COPY --from=builder /usr/local/share/xray /usr/local/share/xray

RUN chmod +x /app/main /usr/local/bin/xray

# =========================================================
# Nginx
# =========================================================
COPY railway.conf /etc/nginx/sites-available/default

RUN rm -f /etc/nginx/sites-enabled/default \
    && ln -s /etc/nginx/sites-available/default \
       /etc/nginx/sites-enabled/default

# =========================================================
# Startup
# =========================================================
COPY start-railway.sh /usr/local/bin/start-railway.sh

RUN sed -i 's/\r$//' /usr/local/bin/start-railway.sh \
    && chmod +x /usr/local/bin/start-railway.sh

# =========================================================
# Environment
# =========================================================
ENV NODE_HOST=0.0.0.0
ENV SERVICE_PORT=62050
ENV SERVICE_PROTOCOL=grpc
ENV GENERATED_CONFIG_PATH=/var/lib/pg-node/generated

# Nginx HTTP port
ENV NGINX_PORT=8080

WORKDIR /app

EXPOSE 8080
EXPOSE 62050

ENTRYPOINT ["/usr/local/bin/start-railway.sh"]
