# Маршрутизация текстовых моделей Vertex AI

Обновлено: 2026-04-29.

Этот файл описывает, как реально вызывать текстовые модели из наших Electron/Node проектов. Важно: `model ID` сам по себе недостаточен. Для каждой группы моделей нужен свой маршрут вызова.

Если проект работает на Google Cloud Free Trial / $300 credits, сначала смотри `10-free-trial-models.md`. Claude/Mistral/Grok/AI21 не входят в рабочий baseline Free Trial.

## Краткий итог

Для обычных проектов сначала использовать Gemini:

```text
gemini-2.5-flash
gemini-2.5-pro
gemini-2.5-flash-lite
```

Gemini вызывается через Google Gen AI SDK.

Partner/open MaaS модели в Vertex AI не являются тем же самым API, что Gemini. Для них нужны отдельные маршруты:

- Claude: Anthropic Vertex connector или `publishers/anthropic/...:rawPredict`
- Mistral: `publishers/mistralai/...:rawPredict`
- Open MaaS: Vertex OpenAI-compatible endpoint `/endpoints/openapi/chat/completions`

Если Gemini работает, а Claude возвращает `429 RESOURCE_EXHAUSTED`, это обычно не проблема service account JSON и не проблема `private_key`. Это квота, capacity, endpoint, регион, доступ к конкретной модели или Model Garden entitlement.

## Базовый рабочий список текстовых моделей

Это короткий список, который стоит использовать для реального подключения и smoke-test. Полный каталог моделей лежит в `8-model-catalog.md`.

| Группа | Алиас | Model ID | Маршрут | Когда брать |
| --- | --- | --- | --- | --- |
| Базовый текст | `gemini-flash` | `gemini-2.5-flash` | Google Gen AI SDK | Дефолт для большинства задач |
| Сложный текст | `gemini-pro` | `gemini-2.5-pro` | Google Gen AI SDK | Исследование, анализ, сложные ответы |
| Дешевые массовые задачи | `gemini-lite` | `gemini-2.5-flash-lite` | Google Gen AI SDK | Классификация, короткие ответы |
| Open MaaS research | `deepseek-v32` | `deepseek-ai/deepseek-v3.2-maas` | Open MaaS chat completions | Альтернативный research/agent вариант |
| Open MaaS cheap | `gpt-oss-20b` | `openai/gpt-oss-20b-maas` | Open MaaS chat completions | Лёгкий open baseline |
| Open MaaS coding | `qwen-coder` | `qwen/qwen3-coder-480b-a35b-instruct-maas` | Open MaaS chat completions | Coding tasks |
| Open MaaS research | `kimi-k2` | `moonshotai/kimi-k2-thinking-maas` | Open MaaS chat completions | Thinking/research |
| Open MaaS research | `glm-5` | `zai-org/glm-5-maas` | Open MaaS chat completions | Сложный reasoning |
| Excluded partner | `claude-haiku` | `claude-haiku-4-5@20251001` | Anthropic Vertex / rawPredict | Не baseline на Free Trial |
| Excluded partner | `mistral-small` | `mistral-small-2503` | Mistral rawPredict | Не baseline на Free Trial |

Не добавлять в приложение сразу весь список. Сначала подключить один маршрут и один fallback:

```text
primary: gemini-2.5-flash
fallback/research: gemini-2.5-pro
open-maas fallback: deepseek-ai/deepseek-v3.2-maas
```

## Маршрут 1: Gemini native

Использовать для:

- `gemini-2.5-flash`
- `gemini-2.5-pro`
- `gemini-2.5-flash-lite`

Python:

```python
from google import genai
from google.genai.types import HttpOptions

client = genai.Client(
    vertexai=True,
    project=project_id,
    location="global",
    http_options=HttpOptions(api_version="v1"),
)

response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=prompt,
)

print(response.text)
```

Electron/Node main process:

```js
const { GoogleGenAI } = require("@google/genai");

const ai = new GoogleGenAI({
  vertexai: true,
  project: process.env.GOOGLE_CLOUD_PROJECT,
  location: process.env.GOOGLE_CLOUD_LOCATION || "global",
});

const response = await ai.models.generateContent({
  model: "gemini-2.5-flash",
  contents: prompt,
});
```

Перед созданием клиента в Electron main process обязательно загрузить `src/load-env.cjs`.

## Маршрут 2: Claude через Anthropic Vertex

Claude в Vertex AI не вызывать как Gemini через `client.models.generate_content(...)`.

Claude можно вызывать двумя способами:

1. Anthropic Vertex SDK.
2. REST endpoint Vertex AI `publishers/anthropic/...:rawPredict`.

Глобальный endpoint:

```text
https://aiplatform.googleapis.com/v1/projects/PROJECT_ID/locations/global/publishers/anthropic/models/MODEL:rawPredict
```

Regional endpoint:

```text
https://LOCATION-aiplatform.googleapis.com/v1/projects/PROJECT_ID/locations/LOCATION/publishers/anthropic/models/MODEL:rawPredict
```

Тело запроса:

```json
{
  "anthropic_version": "vertex-2023-10-16",
  "messages": [
    {
      "role": "user",
      "content": "Привет. Ответь одной короткой фразой."
    }
  ],
  "max_tokens": 120,
  "stream": false
}
```

Для smoke-test начинать не с Opus, а с:

```text
claude-haiku-4-5@20251001
```

Затем проверять:

```text
claude-sonnet-4-6
claude-opus-4-7
```

Перед использованием конкретной Claude модели:

- открыть Model Garden card
- нажать Enable для этой модели
- принять partner terms
- проверить IAM service account
- проверить quotas для этой модели и endpoint-типа

## Маршрут 3: Mistral через rawPredict

Mistral модели идут через publisher `mistralai`.

Endpoint:

```text
https://LOCATION-aiplatform.googleapis.com/v1/projects/PROJECT_ID/locations/LOCATION/publishers/mistralai/models/MODEL:rawPredict
```

Для Mistral не использовать `global` вслепую. В официальной документации для актуальных Mistral text-моделей указаны регионы:

```text
us-central1
europe-west4
```

Тело запроса:

```json
{
  "model": "mistral-small-2503",
  "messages": [
    {
      "role": "user",
      "content": "Привет. Ответь одной короткой фразой."
    }
  ],
  "max_tokens": 120,
  "stream": false
}
```

Для smoke-test:

```text
mistral-small-2503
```

Для более сильного режима:

```text
mistral-medium-3
```

## Маршрут 4: Open MaaS через chat completions

Часть open MaaS моделей в Vertex AI вызывается через OpenAI-compatible endpoint:

```text
https://LOCATION-aiplatform.googleapis.com/v1/projects/PROJECT_ID/locations/LOCATION/endpoints/openapi/chat/completions
```

Для `global`:

```text
https://aiplatform.googleapis.com/v1/projects/PROJECT_ID/locations/global/endpoints/openapi/chat/completions
```

Тело запроса:

```json
{
  "model": "deepseek-ai/deepseek-v3.2-maas",
  "messages": [
    {
      "role": "user",
      "content": "Привет. Ответь одной короткой фразой."
    }
  ],
  "max_tokens": 120,
  "stream": false
}
```

Для open MaaS важно: в Chat Completions API часто нужен provider-prefixed model name, например:

```text
deepseek-ai/deepseek-v3.2-maas
```

В Model Garden card может быть указан короткий model ID без prefix. Перед подключением open MaaS модели проверить карточку и официальный пример вызова.

## Почему ошибка 429 у Claude не равна проблеме авторизации

Пример ошибки:

```text
429 RESOURCE_EXHAUSTED
```

Обычно это значит одно из следующего:

- исчерпана квота QPM/TPM для конкретной модели
- исчерпана квота для endpoint-типа: global, regional или multi-region
- модель включена, но capacity временно недоступен
- выбран неподдерживаемый регион
- модель не enabled в Model Garden для проекта
- partner terms не приняты
- service account видит Vertex AI, но не имеет доступа к конкретной partner/open модели

Что делать:

1. Не менять service account JSON и не трогать `private_key`.
2. Проверить, что Gemini native всё ещё отвечает.
3. Проверить Model Garden card конкретной модели.
4. Проверить quotas в Google Cloud Console по модели, региону и endpoint-типу.
5. Для Claude сначала тестировать `claude-haiku-4-5@20251001`, потом Sonnet, потом Opus.
6. Добавить retry с exponential backoff и fallback на Gemini.

## Проверочный скрипт

В этой базе есть переносимый smoke-test:

```text
examples/test_vertex_text_routes.py
```

Он:

- читает `.env.local` из целевого проекта
- не выводит `private_key`
- использует service account ADC
- проверяет Gemini через Google Gen AI SDK
- проверяет Claude/Mistral/Open MaaS через правильные Vertex endpoints

## Фактическая проверка на VibeImp

Дата проверки: 2026-04-29 и 2026-04-30.

Проект:

```text
W:\MyIdeas\VibeImp\app
```

Команды запускались через `.env.local` проекта и общий service account ADC.

Результат:

| Алиас | Model ID | Маршрут | Результат |
| --- | --- | --- | --- |
| `gemini-flash` | `gemini-2.5-flash` | Google Gen AI SDK | OK, модель ответила |
| `deepseek-v32` | `deepseek-ai/deepseek-v3.2-maas` | Open MaaS chat completions | OK, модель ответила |
| `kimi-k2` | `moonshotai/kimi-k2-thinking-maas` | Open MaaS chat completions | OK, модель ответила |
| `gpt-oss-20b` | `openai/gpt-oss-20b-maas` | Open MaaS chat completions | OK, модель ответила |
| `gpt-oss-120b` | `openai/gpt-oss-120b-maas` | Open MaaS chat completions | OK, модель ответила |
| `minimax-m2` | `minimaxai/minimax-m2-maas` | Open MaaS chat completions | OK, модель ответила |
| `qwen-next-instruct` | `qwen/qwen3-next-80b-a3b-instruct-maas` | Open MaaS chat completions | OK после повторной проверки; возможен transient `429` |
| `qwen-next-thinking` | `qwen/qwen3-next-80b-a3b-thinking-maas` | Open MaaS chat completions | OK, модель ответила |
| `qwen-coder` | `qwen/qwen3-coder-480b-a35b-instruct-maas` | Open MaaS chat completions | OK, модель ответила |
| `glm-47` | `zai-org/glm-4.7-maas` | Open MaaS chat completions | HTTP 200; при малом лимите может уйти в reasoning |
| `glm-5` | `zai-org/glm-5-maas` | Open MaaS chat completions | OK, модель ответила |
| `claude-haiku` | `claude-haiku-4-5@20251001` | Anthropic rawPredict global | `429 RESOURCE_EXHAUSTED` |
| `mistral-small` | `mistral-small-2503` | Mistral rawPredict `us-central1` | `404 NOT_FOUND` |
| `llama-4-scout` | `meta/llama-4-scout-17b-16e-instruct-maas` | Open MaaS `us-east5` | `404 NOT_FOUND` |
| `llama-4-maverick` | `meta/llama-4-maverick-17b-128e-instruct-maas` | Open MaaS `us-east5` | `404 NOT_FOUND` |

Вывод:

- service account схема работает
- Gemini native работает
- Open MaaS маршрут работает для DeepSeek, Kimi, OpenAI OSS, MiniMax, Qwen и GLM
- Claude/Mistral не входят в Free Trial baseline
- Llama 4 в текущем trial-проекте не брать в baseline из-за `404 NOT_FOUND`

Не исправлять Claude/Mistral ошибки изменением `.env.local`, service account JSON или `private_key`.

Посмотреть доступные алиасы:

```powershell
python W:\MyIdeas\AlionIT\help-with-my-projects\Ai-clouds\google-cloud-vertex-ai\examples\test_vertex_text_routes.py --list
```

Запустить базовую Gemini-проверку из корня подготовленного проекта:

```powershell
python W:\MyIdeas\AlionIT\help-with-my-projects\Ai-clouds\google-cloud-vertex-ai\examples\test_vertex_text_routes.py --project-root . --profile gemini-smoke
```

Запустить Free Trial текстовый baseline:

```powershell
python W:\MyIdeas\AlionIT\help-with-my-projects\Ai-clouds\google-cloud-vertex-ai\examples\test_vertex_text_routes.py --project-root . --profile free-text --max-tokens 40 --continue-on-error
```

Запустить рабочие Open MaaS модели:

```powershell
python W:\MyIdeas\AlionIT\help-with-my-projects\Ai-clouds\google-cloud-vertex-ai\examples\test_vertex_text_routes.py --project-root . --profile open-maas-candidates --max-tokens 80 --continue-on-error
```

Профиль `open-maas-candidates` не включает Llama 4, потому что в текущем trial-проекте Llama 4 уже проверен и дал `404 NOT_FOUND`.

`excluded-free-trial`, `partner-smoke` и `claude` профили оставлены только для диагностики после перехода на paid billing или отдельной проверки доступа. На Free Trial не использовать их как рабочую проверку.

Если скрипт скопирован в `project/temp`, можно запускать так:

```powershell
cd temp
python .\test_vertex_text_routes.py --profile free-text --max-tokens 40 --continue-on-error
python .\test_vertex_text_routes.py --profile open-maas-candidates --max-tokens 80 --continue-on-error
```

## Electron архитектура

Правильно:

```text
renderer
-> ipcRenderer.invoke(...)
-> main process
-> model router
-> Vertex AI / Gemini / partner endpoint
-> main process возвращает результат
```

Неправильно:

- renderer читает `GOOGLE_APPLICATION_CREDENTIALS`
- renderer получает путь к JSON
- renderer получает `private_key`
- renderer напрямую вызывает partner endpoint с credentials

В main process сделать небольшой router:

```text
gemini-*        -> Google Gen AI SDK
deepseek/kimi/openai/qwen/zai-org/* -> Open MaaS chat completions
claude-*        -> Anthropic Vertex / rawPredict, excluded on Free Trial
mistral-*       -> mistralai rawPredict, excluded on Free Trial
```

UI должен передавать не секреты, а только безопасный alias модели, например:

```text
gemini-flash
gemini-pro
deepseek-v32
qwen-coder
```

## Официальные источники

- Google Gen AI SDK: https://docs.cloud.google.com/vertex-ai/generative-ai/docs/sdks/overview
- Partner models for MaaS: https://docs.cloud.google.com/vertex-ai/generative-ai/docs/partner-models/use-partner-models
- Claude on Vertex AI: https://docs.cloud.google.com/vertex-ai/generative-ai/docs/partner-models/claude/use-claude
- Anthropic Claude on Vertex AI: https://docs.anthropic.com/en/api/claude-on-vertex-ai
- Mistral on Vertex AI: https://docs.cloud.google.com/vertex-ai/generative-ai/docs/partner-models/mistral
- Open MaaS chat completions: https://docs.cloud.google.com/vertex-ai/generative-ai/docs/maas/call-open-model-apis
- 429 troubleshooting: https://docs.cloud.google.com/vertex-ai/generative-ai/docs/provisioned-throughput/error-code-429
