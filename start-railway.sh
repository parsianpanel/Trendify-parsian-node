#!/bin/bash

set -e

echo "=========================================="
echo " Starting PasarGuard Railway Node"
echo "=========================================="

# ---------------------------------------------------------
# Environment defaults
# ---------------------------------------------------------

export NODE_HOST="${NODE_HOST:-0.0.0.0}"
export SERVICE_PORT="${SERVICE_PORT:-62050}"
export SERVICE_PROTOCOL="${SERVICE_PROTOCOL:-grpc}"
export GENERATED_CONFIG_PATH="${GENERATED_CONFIG_PATH:-/var/lib/pg-node/generated}"

export NGINX_PORT="${NGINX_PORT:-8080}"

# Domain used for the Node TLS certificate.
# This can be changed from Railway Variables.
export NODE_DOMAIN="${NODE_DOMAIN:-localhost}"

echo "Node Host:        ${NODE_HOST}"
echo "Node Port:        ${SERVICE_PORT}"
echo "Node Protocol:    ${SERVICE_PROTOCOL}"
echo "Nginx Port:       ${NGINX_PORT}"
echo "Node Domain:      ${NODE_DOMAIN}"

# ---------------------------------------------------------
# Validate API key
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
# Generate Node TLS certificate
# ---------------------------------------------------------

CERT_FILE="/var/lib/pg-node/certs/ssl_cert.pem"
KEY_FILE="/var/lib/pg-node/certs/ssl_key.pem"

if [ ! -f "${CERT_FILE}" ] || [ ! -f "${KEY_FILE}" ]; then

    echo "Generating TLS certificate for: ${NODE_DOMAIN}"

    openssl req -x509 \
        -newkey ec \
        -pkeyopt ec_paramgen_curve:P-256 \
        -keyout "${KEY_FILE}" \
        -out "${CERT_FILE}" \
        -days 3650 \
        -nodes \
        -subj "/CN=${NODE_DOMAIN}" \
        -addext "subjectAltName=DNS:${NODE_DOMAIN},DNS:localhost,IP:127.0.0.1"

    chmod 600 "${KEY_FILE}"
    chmod 644 "${CERT_FILE}"

    echo "TLS certificate generated."

else

    echo "Existing TLS certificate found."
fi

# ---------------------------------------------------------
# PasarGuard Node TLS paths
# ---------------------------------------------------------

export SSL_CERT_FILE="${CERT_FILE}"
export SSL_KEY_FILE="${KEY_FILE}"

echo "SSL_CERT_FILE:    ${SSL_CERT_FILE}"
echo "SSL_KEY_FILE:     ${SSL_KEY_FILE}"

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
