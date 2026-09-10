FROM pasarguard/node:latest

WORKDIR /app

ENV SERVICE_PORT=62050
ENV SERVICE_PROTOCOL=grpc
ENV SSL_CERT_FILE=/var/lib/pg-node/certs/ssl_cert.pem
ENV SSL_KEY_FILE=/var/lib/pg-node/certs/ssl_key.pem
ENV GENERATED_CONFIG_PATH=/var/lib/pg-node/generated

RUN mkdir -p /var/lib/pg-node/certs /var/lib/pg-node/generated

EXPOSE 62050

ENTRYPOINT ["./main"]
