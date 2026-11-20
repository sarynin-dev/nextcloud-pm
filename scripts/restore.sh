#!/bin/sh
# Восстановление из резервной копии: ./scripts/restore.sh backups/2026-10-01_03-00
set -e
cd "$(dirname "$0")/.."
. ./.env
DIR="$1"
[ -d "$DIR" ] || { echo "Укажите каталог резервной копии"; exit 1; }

docker compose exec -T -u www-data app php occ maintenance:mode --on
docker compose exec -T app sh -c "rm -rf /var/www/html/data /var/www/html/config /var/www/html/custom_apps"
docker compose exec -T app tar -xzf - -C /var/www/html < "$DIR/nextcloud.tar.gz"
docker compose exec -T app chown -R www-data:www-data /var/www/html
docker compose exec -T db psql -U "$POSTGRES_USER" -d postgres -c "DROP DATABASE $POSTGRES_DB WITH (FORCE);" -c "CREATE DATABASE $POSTGRES_DB OWNER $POSTGRES_USER;"
docker compose exec -T db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" < "$DIR/db.sql"
docker compose exec -T -u www-data app php occ maintenance:mode --off
docker compose exec -T -u www-data app php occ maintenance:data-fingerprint
echo "Восстановление завершено"
