# Корпоративное облако для управления проектами (Nextcloud + Deck)

Курсовая работа по дисциплине «Настройка и администрирование сервисного программного обеспечения».

## Состав

| Контейнер | Образ | Назначение |
|-----------|-------|------------|
| nc-proxy  | nginx:1.27-alpine   | обратный прокси, HTTPS, перенаправление HTTP → HTTPS |
| nc-app    | nextcloud:33-apache | веб-приложение Nextcloud |
| nc-cron   | nextcloud:33-apache | фоновые задачи (каждые 5 минут) |
| nc-db     | postgres:16-alpine  | база данных |
| nc-redis  | redis:7-alpine      | кэш и блокировки файлов |

Приложения Nextcloud: **Deck** (канбан-доски), **Calendar** (календарь), **Tasks** (задачи), **Group folders** (общие папки отделов).

## Требования

Docker Desktop (Windows/macOS, на Windows — с WSL 2) или Docker Engine + Docker Compose (Linux), 4 ГБ ОЗУ.

## Запуск (пошагово)

```bash
# 1. Создать файл с паролями
cp .env.example .env          # Windows PowerShell: copy .env.example .env

# 2. Сгенерировать SSL-сертификат (нужен openssl; есть в Git Bash и WSL)
sh scripts/gen-cert.sh

# 3. Запустить контейнеры
docker compose up -d
docker compose ps             # все контейнеры должны быть в статусе running/healthy

# 4. Первичная настройка (приложения, группы, пользователи, общая папка)
sh scripts/setup.sh
```

Откройте **https://localhost** (браузер предупредит о самоподписанном сертификате — нажмите «Дополнительно → Перейти»).
Вход: `admin` / пароль из `.env`. Сотрудники: `ivanov`, `petrova`, `sidorov`, `smirnova`, пароль — `DEMO_USER_PASSWORD` из `.env`.

## Администрирование

```bash
docker compose exec -u www-data app php occ status          # состояние
docker compose exec -u www-data app php occ user:list       # пользователи
docker compose exec -u www-data app php occ app:list        # приложения
docker compose logs -f app                                  # журналы
sh scripts/backup.sh                                        # резервная копия
sh scripts/restore.sh backups/<дата>                         # восстановление
docker compose pull && docker compose up -d                 # обновление
docker compose down                                         # остановка (данные сохраняются в томах)
```
