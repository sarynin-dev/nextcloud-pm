#!/bin/sh
# Генерация самоподписанного SSL-сертификата для учебного стенда
set -e
cd "$(dirname "$0")/.."
mkdir -p nginx/certs
openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
  -keyout nginx/certs/nextcloud.key \
  -out nginx/certs/nextcloud.crt \
  -subj "/C=RU/ST=Moscow/O=Project Cloud/CN=localhost"
echo "Сертификат создан в nginx/certs/"
