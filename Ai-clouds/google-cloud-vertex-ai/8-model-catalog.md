# Каталог моделей Vertex AI / Gemini

Обновлено: 2026-04-29.

Это локальный снимок моделей и рекомендаций для наших Electron/Node проектов. Агентам не нужно каждый раз заново собирать список моделей из Google Cloud docs: сначала использовать этот файл, а обновлять его отдельно по запросу.

Каталог покрывает не все 200+ моделей Model Garden, а практичный рабочий набор для наших проектов. При этом сторонние managed API варианты здесь не скрыты: partner MaaS и open MaaS модели перечислены отдельными секциями, чтобы пользователь мог выбрать не только Gemini.

Важно: этот файл отвечает на вопрос "какую модель выбрать". Как именно вызывать Gemini, Claude, Mistral и open MaaS модели, описано отдельно в `9-text-model-routing.md`.

Если проект работает на Google Cloud Free Trial / $300 credits, использовать не весь каталог, а рабочий baseline из `10-free-trial-models.md`.

- Google first-party модели: Gemini, Imagen, Veo, Lyria, embeddings.
- Partner MaaS модели: Claude, Grok, Mistral, AI21.
- Managed open models: DeepSeek, Gemma, Kimi, Llama, MiniMax, OpenAI OSS, Qwen, ZAI/GLM.

Важно: для наших обычных приложений основной путь — Gemini через Google Gen AI SDK. Partner/open модели в Model Garden могут требовать отдельного включения, acceptance в Marketplace/Model Garden, других endpoint-форматов и другой интеграции.

Если в официальной документации есть устойчивый Vertex AI model ID, он записан в таблицах ниже. Если точный ID нужно брать из карточки Model Garden, это помечено явно: лучше проверить карточку, чем придумать неверное имя модели.

Официальные источники для обновления:

- Google models: https://docs.cloud.google.com/vertex-ai/generative-ai/docs/models
- Model versions and lifecycle: https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/model-versions
- Partner models for MaaS: https://docs.cloud.google.com/vertex-ai/generative-ai/docs/partner-models/use-partner-models
- Model Garden models: https://docs.cloud.google.com/model-garden
- Google Gen AI SDK: https://docs.cloud.google.com/vertex-ai/generative-ai/docs/sdks/overview
- Publisher models list API: https://docs.cloud.google.com/vertex-ai/docs/reference/rest/v1beta1/publishers.models/list
- Vertex AI pricing: https://cloud.google.com/vertex-ai/generative-ai/pricing

## Главная рекомендация

Для обычных текстовых задач, чатов, ассистентов, анализа документов и большинства AI-функций в приложениях использовать:

```text
gemini-2.5-flash
```

Это наш базовый model ID по умолчанию.

Если агент подключает AI в проект и пользователь не попросил другую модель, начинать с `gemini-2.5-flash`.

## Базовые подборки для агента

Это короткие рабочие списки. Их можно давать агенту как готовые группы: "бери basic-text", "бери research", "бери images" и так далее.

Точные цены в этом файле не фиксируем: они меняются и зависят от провайдера, региона, endpoint-типа и billing. Перед продакшеном проверять Vertex AI pricing и карточку модели в Model Garden. Не считать автоматически, что старая модель дешевле новой.

### `basic-text`

Для обычного текста, чата, суммаризации, JSON-ответов и большинства Electron AI-функций.

- `gemini-2.5-flash`
- `gemini-2.5-flash-lite`
- `gemini-2.5-pro`

Рекомендация: начинать с `gemini-2.5-flash`.

### `research`

Для сложного анализа, исследования, больших документов и задач, где качество важнее цены.

- `gemini-2.5-pro`
- `deepseek-ai/deepseek-v3.2-maas`
- `moonshotai/kimi-k2-thinking-maas`
- `qwen/qwen3-next-80b-a3b-thinking-maas`
- `zai-org/glm-5-maas`

Рекомендация: на Free Trial начинать с `gemini-2.5-pro`, затем смотреть DeepSeek/Open MaaS. Claude/Grok не брать в Free Trial baseline.

### `coding-agents`

Для кода, agentic workflows, рефакторинга и сложных инженерных задач.

- `gemini-2.5-pro`
- `qwen/qwen3-coder-480b-a35b-instruct-maas`
- `minimaxai/minimax-m2-maas`
- `openai/gpt-oss-120b-maas`
- `zai-org/glm-4.7-maas`

Рекомендация: для стандартного подключения начать с `gemini-2.5-pro`; на Free Trial не брать Claude/Codestral.

### `cheap-bulk`

Для массовых дешевых запросов: классификация, короткие ответы, автозаполнение, фоновые задачи.

- `gemini-2.5-flash-lite`
- `gemini-2.5-flash`
- `openai/gpt-oss-20b-maas`

Рекомендация: начинать с `gemini-2.5-flash-lite`; partner-модели не брать на Free Trial.

### `images`

Для генерации и редактирования изображений.

- `gemini-2.5-flash-image`
- `imagen-4.0-fast-generate-001`
- `imagen-4.0-generate-001`
- `imagen-4.0-ultra-generate-001`

Рекомендация: для conversational editing начинать с `gemini-2.5-flash-image`; для простой генерации на Free Trial использовать `imagen-4.0-fast-generate-001`.

### `video`

Для генерации видео.

- `veo-3.1-fast-generate-001`
- `veo-3.1-generate-001`
- `veo-2.0-generate-001`

Рекомендация: на Free Trial использовать только по явному запросу, начинать с `veo-3.1-fast-generate-001`.

### `audio-live`

Для live/audio сценариев и музыки.

- `gemini-live-2.5-flash-native-audio`
- Lyria 3
- Lyria 2

Рекомендация: для голосовых/live-сессий использовать Gemini Live, для музыки смотреть Lyria.

### `embeddings-search`

Для семантического поиска, RAG и сравнения текстов по смыслу.

- `gemini-embedding-001`
- Multilingual E5 Large
- Multilingual E5 Small

Рекомендация: начинать с `gemini-embedding-001`. E5 брать через Model Garden card, если нужен именно open embedding model.

### `ocr-docs`

Для OCR, документов и извлечения данных.

- `gemini-2.5-flash`
- `deepseek-ocr-maas`

Рекомендация: начинать с `gemini-2.5-flash`. `deepseek-ocr-maas` отдельно проверить перед использованием; Mistral OCR не брать на Free Trial baseline.

## Короткая карта выбора

| Задача | Model ID | Когда использовать |
| --- | --- | --- |
| Основной текстовый ассистент | `gemini-2.5-flash` | Выбор по умолчанию для 90% задач |
| Сложные рассуждения и код | `gemini-2.5-pro` | Когда важнее качество, чем скорость и цена |
| Массовые дешевые запросы | `gemini-2.5-flash-lite` | Классификация, простые ответы, автозаполнение |
| Новые Gemini 3 тесты | `gemini-3-flash-preview` / `gemini-3.1-pro-preview` | Только если явно нужен preview |
| Frontier coding / agents через Anthropic | Claude Opus/Sonnet | Partner model, не дефолтная Gemini-интеграция |
| Генерация/редактирование изображений через Gemini | `gemini-2.5-flash-image` | Когда нужен image output или conversational image editing |
| Embeddings | `gemini-embedding-001` | Поиск, RAG, семантическое сравнение |
| Live/audio сценарии | `gemini-live-2.5-flash-native-audio` | Голосовые/live-сессии, не обычный chat completion |

## Текстовые Gemini модели

### `gemini-2.5-flash`

Основная модель для наших проектов.

Использовать для:

- обычного чата
- AI-помощников в приложениях
- суммаризации
- анализа пользовательского текста
- анализа документов
- генерации JSON/структурированных ответов
- функций Electron-приложений через main process

Пример:

```python
response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=prompt,
)
```

### `gemini-2.5-pro`

Более тяжелая модель для сложных задач.

Использовать для:

- сложного reasoning
- сложного анализа кода
- архитектурных задач
- больших документов
- задач, где качество важнее скорости

Не использовать по умолчанию для массовых запросов.

### `gemini-2.5-flash-lite`

Более легкая модель.

Использовать для:

- простых классификаций
- коротких ответов
- массовой обработки мелких задач
- дешевых фоновых AI-функций

Не использовать там, где требуется глубокое рассуждение.

## Gemini 3 preview

Gemini 3 / 3.1 модели уже есть в Google Cloud docs, но они относятся к preview. Не делать их дефолтом в наших проектах без отдельного решения.

Текущие preview model ID:

- `gemini-3.1-pro-preview`
- `gemini-3.1-pro-preview-customtools`
- `gemini-3-pro-preview`
- `gemini-3-flash-preview`
- `gemini-3.1-flash-lite-preview`
- `gemini-3-pro-image-preview`
- `gemini-3.1-flash-image-preview`

Когда рассматривать:

- сложные agentic/coding задачи
- большие multimodal запросы
- тестирование новых возможностей Gemini 3
- отдельные эксперименты, где допустим preview-риск

Не использовать как стандарт для всех 10 проектов, пока не принято отдельное решение.

## Изображения

### `gemini-2.5-flash-image`

Gemini-модель для image generation и conversational editing.

Использовать, когда нужен не просто текстовый ответ, а изображение или редактирование изображения через Gemini.

Важно: для изображений могут использоваться другие методы SDK и другие параметры, не обычный минимальный `generate_content` только с текстом.

## Embeddings

### `gemini-embedding-001`

Основная модель для embeddings.

Использовать для:

- семантического поиска
- RAG
- сравнения текстов по смыслу
- построения векторного индекса

Это не chat-модель. Ее не нужно передавать в обычный `generate_content` для ответа пользователю.

## Imagen

Модели Imagen используются для специализированной генерации и обработки изображений.

Актуальные stable model ID из lifecycle:

- `imagen-4.0-generate-001`
- `imagen-4.0-fast-generate-001`
- `imagen-4.0-ultra-generate-001`
- `imagen-3.0-generate-002`
- `imagen-3.0-generate-001`
- `imagen-3.0-fast-generate-001`
- `imagen-3.0-capability-001`
- `virtual-try-on-001`

Для обычных текстовых AI-функций в Electron эти модели не нужны.

## Veo

Модели Veo используются для video generation.

Актуальные model ID из lifecycle:

- `veo-3.1-generate-001`
- `veo-3.1-fast-generate-001`
- `veo-3.0-generate-001`
- `veo-3.0-fast-generate-001`
- `veo-2.0-generate-001`

Для обычных текстовых AI-функций в Electron эти модели не нужны.

## Lyria

Lyria используется для генерации музыки.

Модели из Google docs:

- Lyria 2
- Lyria 3

Для обычных текстовых AI-функций в Electron эти модели не нужны.

## Partner models / Model Garden MaaS

Partner-модели в Vertex AI доступны как managed APIs в Model Garden. Это не “обычные Gemini model ID” для нашего минимального `client.models.generate_content(...)`.

Перед использованием partner-моделей нужно проверить:

- включен ли доступ к конкретной модели в Model Garden
- приняты ли нужные условия/Marketplace entitlement
- хватает ли IAM прав service account
- поддерживает ли модель `global` или нужен regional/multi-region endpoint
- какой endpoint и формат запроса нужен для конкретного publisher

### Anthropic Claude

Вот где находятся “опусы”. Они есть в Vertex AI как partner models.

Актуальные Claude model ID:

| Модель | Vertex AI model ID | Статус / когда смотреть |
| --- | --- | --- |
| Claude Opus 4.7 | `claude-opus-4-7` | Самый новый Opus; coding, agents, enterprise workflows |
| Claude Sonnet 4.6 | `claude-sonnet-4-6` | Сильный универсальный agent/coding вариант |
| Claude Opus 4.6 | `claude-opus-4-6` | Frontier Opus для сложных задач |
| Claude Opus 4.5 | `claude-opus-4-5@20251101` | Opus-класс, coding/agents |
| Claude Sonnet 4.5 | `claude-sonnet-4-5@20250929` | Баланс качества/скорости для agents/coding |
| Claude Opus 4.1 | `claude-opus-4-1@20250805` | Opus-класс, coding/agentic search |
| Claude Haiku 4.5 | `claude-haiku-4-5@20251001` | Быстрый и более дешевый Claude для массовых задач |
| Claude Opus 4 | `claude-opus-4@20250514` | Старший Opus 4 |
| Claude Sonnet 4 | `claude-sonnet-4@20250514` | Sonnet 4 |

Старые / deprecated / existing customers:

| Модель | Vertex AI model ID | Статус |
| --- | --- | --- |
| Claude 3.7 Sonnet | `claude-3-7-sonnet@20250219` | Deprecated / existing customers |
| Claude 3.5 Sonnet v2 | `claude-3-5-sonnet-v2@20241022` | Deprecated / existing customers |
| Claude 3.5 Sonnet | `claude-3-5-sonnet@20240620` | Deprecated / existing customers |
| Claude 3.5 Haiku | `claude-3-5-haiku@20241022` | Deprecated / existing customers |
| Claude 3 Opus | `claude-3-opus@20240229` | Deprecated |
| Claude 3 Haiku | `claude-3-haiku@20240307` | Старый Claude 3 |

Когда рассматривать:

- frontier coding
- agentic workflows
- сложные долгие задачи
- сравнение качества с Gemini

Не использовать как дефолт в наших проектах. Сначала проверить доступ и способ вызова в Model Garden.

### Grok

| Модель | Vertex AI model ID | Статус / когда смотреть |
| --- | --- | --- |
| Grok 4.20 Reasoning | `grok-4.20-reasoning` | Preview; reasoning, tool calling |
| Grok 4.20 Non-Reasoning | `grok-4.20-non-reasoning` | Preview; latency-sensitive tasks |
| Grok 4.1 Fast Reasoning | `grok-4.1-fast-reasoning` | Preview; cheaper reasoning/tool use |
| Grok 4.1 Fast Non-Reasoning | `grok-4.1-fast-non-reasoning` | Preview; fast summarization/categorization |

В docs они помечены как preview. Не использовать как дефолт.

### Mistral AI

| Модель | Vertex AI model ID | Статус / когда смотреть |
| --- | --- | --- |
| Mistral Medium 3 | `mistral-medium-3` | GA; универсальные language-задачи |
| Mistral OCR (25.05) | `mistral-ocr-2505` | GA; document/OCR |
| Mistral Small 3.1 (25.03) | `mistral-small-2503` | GA; small multimodal/document tasks |
| Codestral 2 | `codestral-2` | GA; code generation / FIM |

Когда рассматривать:

- Mistral Medium 3 — универсальные language-задачи
- Mistral OCR — document/OCR
- Codestral 2 — специализированный code completion

### AI21

| Модель | Vertex AI model ID | Статус |
| --- | --- | --- |
| Jamba 1.5 Large | `jamba-1.5-large` | Deprecated / existing customers |
| Jamba 1.5 Mini | `jamba-1.5-mini` | Deprecated / existing customers |

Не использовать как дефолт.

## Managed open models / Model Garden MaaS

Open models в Model Garden могут быть доступны как MaaS или self-deployed модели. Для них обычно нужны Model Garden docs, отдельный endpoint и часто другой publisher path.

### DeepSeek

| Модель | Model ID | OpenAI-compatible endpoint ID | Статус |
| --- | --- | --- | --- |
| DeepSeek-V3.2 | `deepseek-v3.2-maas` | `deepseek-ai/deepseek-v3.2-maas` | OK на Free Trial |
| DeepSeek-V3.1 | `deepseek-v3.1-maas` | `deepseek-ai/deepseek-v3.1-maas` | Candidate |
| DeepSeek R1 (0528) | `deepseek-r1-0528-maas` | `deepseek-ai/deepseek-r1-0528-maas` | Candidate |
| DeepSeek-OCR | `deepseek-ocr-maas` | `deepseek-ai/deepseek-ocr-maas` | Candidate |

### Embedding e5

| Модель | Model ID | Статус |
| --- | --- | --- |
| Multilingual E5 Small | проверить в Model Garden card | Open embedding model |
| Multilingual E5 Large | проверить в Model Garden card | Open embedding model |

### Google Gemma

| Модель | Model ID | Статус |
| --- | --- | --- |
| Gemma-4-26B-A4B-IT MaaS | проверить в Model Garden card | MaaS / preview в Model Garden |
| Gemma self-deployed variants | endpoint/model ID создаются при deploy | Self-deployed |

Для Gemma MaaS перед использованием обязательно открыть Model Garden card и взять точный model ID из карточки. Не подставлять имя вслепую.

### Kimi

| Модель | Model ID | OpenAI-compatible endpoint ID | Статус |
| --- | --- | --- | --- |
| Kimi K2 Thinking | `kimi-k2-thinking-maas` | `moonshotai/kimi-k2-thinking-maas` | OK на Free Trial |

### Llama

| Модель | Vertex AI model ID | Статус |
| --- | --- | --- |
| Llama 4 Maverick 17B-128E | `meta/llama-4-maverick-17b-128e-instruct-maas` | Проверено: `404 NOT_FOUND`, не baseline Free Trial |
| Llama 4 Scout 17B-16E | `meta/llama-4-scout-17b-16e-instruct-maas` | Проверено: `404 NOT_FOUND`, не baseline Free Trial |
| Llama 3.3 70B | `meta/llama-3.3-70b-instruct-maas` | Не проверено |

### MiniMax

| Модель | Model ID | OpenAI-compatible endpoint ID | Статус |
| --- | --- | --- | --- |
| MiniMax M2 | `minimax-m2-maas` | `minimaxai/minimax-m2-maas` | OK на Free Trial |

### OpenAI OSS

| Модель | Model ID | OpenAI-compatible endpoint ID | Статус |
| --- | --- | --- | --- |
| OpenAI gpt-oss 120B | `gpt-oss-120b-maas` | `openai/gpt-oss-120b-maas` | OK на Free Trial |
| OpenAI gpt-oss 20B | `gpt-oss-20b-maas` | `openai/gpt-oss-20b-maas` | OK на Free Trial |

### Qwen

| Модель | Model ID | OpenAI-compatible endpoint ID | Статус |
| --- | --- | --- | --- |
| Qwen 3 Next Instruct 80B | `qwen3-next-80b-a3b-instruct-maas` | `qwen/qwen3-next-80b-a3b-instruct-maas` | OK на Free Trial; возможен transient `429` |
| Qwen 3 Next Thinking 80B | `qwen3-next-80b-a3b-thinking-maas` | `qwen/qwen3-next-80b-a3b-thinking-maas` | OK на Free Trial |
| Qwen 3 Coder | `qwen3-coder-480b-a35b-instruct-maas` | `qwen/qwen3-coder-480b-a35b-instruct-maas` | OK на Free Trial |
| Qwen 3 235B | `qwen3-235b-a22b-instruct-2507-maas` | `qwen/qwen3-235b-a22b-instruct-2507-maas` | Не проверено |

### ZAI.org / GLM

| Модель | Model ID | OpenAI-compatible endpoint ID | Статус |
| --- | --- | --- | --- |
| GLM 5 | `glm-5-maas` | `zai-org/glm-5-maas` | OK на Free Trial |
| GLM 4.7 | `glm-4.7-maas` | `zai-org/glm-4.7-maas` | HTTP 200 на Free Trial; нужен достаточный `max_tokens` |

Не использовать open MaaS модели вслепую в Electron-проектах. Сначала определить endpoint, publisher, доступность, стоимость и формат SDK/API.

## Устаревшие и рискованные варианты

Не использовать в новых проектах:

- `gemini-1.5-pro-001`
- `gemini-1.5-pro-002`
- `gemini-1.5-flash-001`
- `gemini-1.5-flash-002`
- `gemini-1.0-pro-001`
- `gemini-1.0-pro-002`
- `gemini-1.0-pro-vision-001`
- `text-bison`
- `chat-bison`
- `code-gecko`

Эти модели находятся в legacy/retired зоне. Если приложение ссылается на них, оно может получить `404 Publisher Model was not found`.

С осторожностью:

- `gemini-2.0-flash-001`
- `gemini-2.0-flash-lite-001`

По lifecycle эти модели доступны для existing customers, а новые проекты должны использовать `gemini-2.5-flash`, `gemini-2.5-flash-lite` или более свежие stable-релизы.

## Preview / новые модели

В Google Cloud docs уже есть preview-модели Gemini 3 / 3.1, Grok и часть partner/open моделей. Не делать их дефолтом в наших проектах без отдельного решения.

Правило:

- stable модели можно использовать как рабочий стандарт
- preview модели можно тестировать отдельно
- перед внедрением preview модели проверить Model Garden, права проекта, регион/location и billing
- если модель дает 404, не менять авторизацию вслепую: сначала проверить model ID, доступность модели и lifecycle

## Как получить актуальный список при обновлении каталога

### Через официальную документацию

1. Открыть Google models:
   https://docs.cloud.google.com/vertex-ai/generative-ai/docs/models
2. Открыть Model versions and lifecycle:
   https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/model-versions
3. Перенести в этот файл только нужные stable model ID и рекомендации.
4. Обновить дату вверху файла.

### Через Google Gen AI SDK

Можно вывести список моделей через SDK:

```python
from google import genai
from google.genai.types import HttpOptions

client = genai.Client(
    vertexai=True,
    project="project-f2d88164-6230-481c-930",
    location="global",
    http_options=HttpOptions(api_version="v1"),
)

for model in client.models.list():
    print(model.name)
```

Для наших проектов такой скрипт должен использовать service account схему через `.env.local` и `GOOGLE_APPLICATION_CREDENTIALS`, а не API key.

### Через REST API Model Garden

Для полного списка publisher models использовать:

```text
publishers.models.list
```

Документация:

```text
https://docs.cloud.google.com/vertex-ai/docs/reference/rest/v1beta1/publishers.models/list
```

Важно: `gcloud ai models list` не является надежным способом получить список Gemini / Model Garden моделей. Он обычно показывает модели, созданные или загруженные в конкретном проекте, а не все Google publisher models.

## Что писать в коде сейчас

Для обычной генерации текста:

```python
response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=prompt,
)
```

Для более сложного режима:

```python
response = client.models.generate_content(
    model="gemini-2.5-pro",
    contents=prompt,
)
```

Для дешевого массового режима:

```python
response = client.models.generate_content(
    model="gemini-2.5-flash-lite",
    contents=prompt,
)
```
