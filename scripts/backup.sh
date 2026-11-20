#!/bin/sh
# Резервное копирование: дамп базы данных + архив данных Nextcloud.
# Пример запуска по расписанию (crontab -e):  0 3 * * * /path/to/scripts/backup.sh
set -e
cd "$(dirname "$0")/.."
. ./.env

DATE=$(date +%Y-%m-%d_%H-%M)
DIR="backups/$DATE"
mkdir -p "$DIR"

echo "== Включение режима обслуживания"
docker compose exec -T -u www-data app php occ maintenance:mode --on

echo "== Дамп базы данных"
docker compose exec -T db pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" > "$DIR/db.sql"

echo "== Архив файлов и конфигурации"
docker compose exec -T app tar -czf - -C /var/www/html config data custom_apps > "$DIR/nextcloud.tar.gz"

echo "== Выключение режима обслуживания"
docker compose exec -T -u www-data app php occ maintenance:mode --off

# Храним только 7 последних копий
ls -1d backups/*/ | head -n -7 | xargs -r rm -rf

echo "Резервная копия сохранена в $DIR"
