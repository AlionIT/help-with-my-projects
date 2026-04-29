# ☁️ Интеграция с Google Cloud Vertex AI (Gemini)

В этой директории собрана исчерпывающая база знаний по правильному аппаратному и программному подключению к энтерпрайз-нейросетям Google (семейство Gemini) через платформу **Vertex AI**.

Документация составлена на основе реального опыта решения проблем с авторизацией и политиками безопасности Google Cloud. 

**Для ИИ-агентов:** При необходимости развернуть приложение, использующее Vertex AI, строго следуйте инструкциям из этой папки. Не используйте устаревшие библиотеки (`google-cloud-aiplatform`) и не пытайтесь использовать обычные API Keys.

## 📂 Оглавление базы знаний

1. `0-setup-history.md` — История наших ошибок (почему нельзя использовать простые API-ключи).
2. `1-overview.md` — Архитектура решения: что такое ADC и почему мы выбрали библиотеку `google-genai`.
3. `2-setup-local.md` — Инструкция для настройки локальной среды разработчика (через `gcloud CLI`).
4. `3-setup-prod.md` — Инструкция для боевого сервера (через Service Account JSON).
5. `4-models.md` — Актуальные модели и специфика их версионирования.
6. `5-troubleshooting.md` — Решение частых ошибок (например, 404 Not Found).
7. `6-console-navigation.md` — Шпаргалка по интерфейсу Google Cloud Console.
8. `7-project-service-account-auth.md` — Текущая схема для Electron/Node проектов: `.env.local`, service account JSON, проверки и будущий main process.
9. `AGENT-BRIEF.md` — Короткий входной документ для агентов, подключающих Vertex AI в других проектах.
10. `examples/test_gcloud_user_adc.py` — Старый контрольный Python-тест через Google Cloud CLI ADC.
11. `examples/test_service_account_adc.py` — Новый Python-тест через `.env.local` и service account JSON.
