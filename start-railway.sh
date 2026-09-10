#!/bin/bash

set -e

echo "=========================================="
echo " Starting PasarGuard Railway Node"
echo "=========================================="

# ---------------------------------------------------------
# Environment defaults
# ---------------------------------------------------------

export NODE_HOST="${NODE_HOST:-127.0.0.1}"
export SERVICE_PORT="${SERVICE_PORT:-62050}"
export SERVICE_PROTOCOL="${SERVICE_PROTOCOL:-grpc}"
export GENERATED_CONFIG_PATH="${GENERATED_CONFIG_PATH:-/var/lib/pg-node/generated}"

export NGINX_PORT="${NGINX_PORT:-8080}"

echo "Node Host:        ${NODE_HOST}"
echo "Node Port:        ${SERVICE_PORT}"
echo "Node Protocol:    ${SERVICE_PROTOCOL}"
echo "Nginx Port:       ${NGINX_PORT}"

# ---------------------------------------------------------
# Validate Node API key
# ---------------------------------------------------------

if [ -z "${API_KEY}" ]; then
    echo "ERROR: API_KEY environment variable is not set."
    exit 1
fi

echo "API_KEY: configured"

# ---------------------------------------------------------
# Prepare directories
# ---------------------------------------------------------

mkdir -p \
    /var/lib/pg-node/generated \
    /var/lib/pg-node/certs \
    /var/log/nginx \
    /run/nginx

# ---------------------------------------------------------
# Nginx
# ---------------------------------------------------------

echo "Starting Nginx..."

nginx -t

nginx

echo "Nginx started."

# ---------------------------------------------------------
# PasarGuard Node
# ---------------------------------------------------------

echo "Starting PasarGuard Node..."

cd /app

exec ./main
