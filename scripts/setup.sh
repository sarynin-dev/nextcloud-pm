#!/bin/sh
# Первичная настройка Nextcloud после запуска контейнеров:
# установка приложений, настройка фоновых задач, создание групп и пользователей.
set -e
cd "$(dirname "$0")/.."
. ./.env

# Выполнение команды occ от имени пользователя www-data внутри контейнера
occ() { docker compose exec -T -e OC_PASS="$DEMO_USER_PASSWORD" -u www-data app php occ "$@"; }

echo "== Ожидание завершения установки Nextcloud..."
until occ status 2>/dev/null | grep -q "installed: true"; do sleep 5; done

echo "== Базовые настройки"
occ background:cron                                  # фоновые задачи через контейнер cron
occ config:system:set default_phone_region --value="RU"
occ config:system:set default_language --value="ru"
occ config:system:set default_locale --value="ru_RU"
occ config:system:set maintenance_window_start --type=integer --value=1

echo "== Установка приложений для управления проектами"
occ app:disable firstrunwizard || true
for a in deck calendar tasks groupfolders; do
  occ app:install "$a" || occ app:enable "$a"
done

echo "== Создание групп (отделов)"
for g in managers developers testers; do
  occ group:add "$g" || true
done

echo "== Создание пользователей"
export OC_PASS="$DEMO_USER_PASSWORD"
add_user() { # логин, ФИО, группа
  occ user:add --password-from-env --display-name="$2" --group="$3" "$1" || true
}
add_user ivanov   "Иванов Иван (руководитель проекта)" managers
add_user petrova  "Петрова Анна (разработчик)"         developers
add_user sidorov  "Сидоров Пётр (разработчик)"         developers
add_user smirnova "Смирнова Ольга (тестировщик)"       testers

echo "== Общая папка проекта с правами по группам"
FID=$(occ groupfolders:create "Проект Альфа" | tail -n1)
occ groupfolders:group "$FID" managers   read write share delete
occ groupfolders:group "$FID" developers read write
occ groupfolders:group "$FID" testers    read
occ groupfolders:quota "$FID" 10G

echo "== Квоты пользователей"
for u in ivanov petrova sidorov smirnova; do
  occ user:setting "$u" files quota "5 GB"
done

echo "Готово! Откройте https://$NC_DOMAIN и войдите как $NC_ADMIN_USER"
