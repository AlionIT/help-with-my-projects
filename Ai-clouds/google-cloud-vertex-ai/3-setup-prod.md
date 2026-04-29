# 🚀 Настройка продакшн-сервера (Prod / VPS)

Инструкция для удаленных серверов (VPS, VDS, Docker-контейнеров), где нет возможности открыть браузер для авторизации. 

## Шаг 1: Создание Service Account (Робота)
1. Зайдите в Google Cloud Console -> **IAM & Admin** -> **Service Accounts**.
2. Создайте новый аккаунт (например, `ai-bot@your-project.iam.gserviceaccount.com`).
3. Выдайте ему роль **Vertex AI User** (пользователь Vertex AI).

## Шаг 2: Скачивание JSON-ключа
1. Нажмите на созданный сервисный аккаунт -> вкладка **Keys** -> **Add Key** -> **Create new key** -> **JSON**.
2. *Возможная проблема:* Если скачивание запрещено, вам нужно зайти в **IAM & Admin** -> **Organization Policies**, найти политику `iam.disableServiceAccountKeyCreation` и временно отключить её (Enforce: Off).
3. Скачайте файл и загрузите его на ваш сервер в безопасную директорию (например, `/etc/secrets/gcp-key.json`).

## Шаг 3: Настройка сервера
На сервере необходимо задать системную переменную окружения, чтобы библиотека ADC поняла, где лежит ключ.

Добавьте в `~/.bashrc`, `.env` файл или настройки Systemd сервиса:
```bash
export GOOGLE_APPLICATION_CREDENTIALS="/путь/к/вашему/ключу/gcp-key.json"