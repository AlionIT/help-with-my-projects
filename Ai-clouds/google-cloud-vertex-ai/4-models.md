# Модели Gemini в Vertex AI

Библиотека `google-genai` требует явно указывать model ID при генерации ответа.

Актуальный локальный каталог моделей и рекомендации лежат здесь:

```text
8-model-catalog.md
```

Инструкция по реальным маршрутам вызова моделей лежит здесь:

```text
9-text-model-routing.md
```

Рабочий список для Google Cloud Free Trial / $300 credits лежит здесь:

```text
10-free-trial-models.md
```

Главный стандарт для наших Electron/Node проектов:

```text
gemini-2.5-flash
```

Для сложных задач:

```text
gemini-2.5-pro
```

Для дешевых массовых задач:

```text
gemini-2.5-flash-lite
```

Для сторонних текстовых моделей нельзя просто заменить model ID в Gemini-вызове. Claude, Mistral и open MaaS модели вызываются другими маршрутами, описанными в `9-text-model-routing.md`.

Если проект остаётся на Free Trial / $300 credits, не использовать Claude, Mistral, Grok, AI21 и Llama как baseline. Использовать только модели, отмеченные рабочими в `10-free-trial-models.md`.

Не использовать старые `gemini-1.5-*`, `gemini-1.0-*`, `text-bison`, `chat-bison` и `code-gecko` в новых проектах. Они находятся в legacy/retired зоне и могут давать `404 Publisher Model was not found`.
