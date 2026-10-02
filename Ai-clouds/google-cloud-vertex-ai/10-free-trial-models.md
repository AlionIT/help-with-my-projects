# Free Trial baseline: модели на $300 credits

Обновлено: 2026-04-30.

Этот файл фиксирует только те модели, которые имеют смысл использовать на текущем Google Cloud Free Trial / $300 credits. Всё, что требует paid billing, partner terms, Marketplace entitlement или quota increase, не входит в рабочий baseline.

## Краткий итог

На текущем trial-проекте подтверждены:

- Google Gemini text: `gemini-2.5-flash`, `gemini-2.5-flash-lite`, `gemini-2.5-pro`
- Google image: `gemini-2.5-flash-image`, `imagen-4.0-fast-generate-001`
- Google video: `veo-3.1-fast-generate-001`
- Open MaaS text: DeepSeek, Kimi, OpenAI OSS, MiniMax, Qwen, GLM

Не использовать на Free Trial baseline:

- Anthropic Claude
- Mistral
- Grok
- AI21
- Llama 4 в нашем текущем проекте
- любые partner MaaS модели, которые требуют paid billing или дают `429` / `404`

## Официальное правило Free Trial

Google Cloud Free Trial credits можно использовать для многих Google Cloud ресурсов, но в официальных исключениях указано:

```text
You can't access or use Free Trial credits for generative AI partner models offered as managed APIs (also known as model as a service).
```

Также Free Trial account не может запрашивать quota increase.

Практический вывод:

- Google-first-party модели можно рассматривать как рабочий baseline на trial credits.
- Open MaaS модели проверять smoke-test по одной.
- Partner MaaS модели вроде Claude/Mistral не брать в baseline до перехода на paid billing.

Источник: https://cloud.google.com/free/docs/free-cloud-features

## Рабочий baseline

| Группа | Алиас | Model ID | Route | Статус |
| --- | --- | --- | --- | --- |
| Текст default | `gemini-flash` | `gemini-2.5-flash` | Google Gen AI SDK | OK |
| Текст cheap | `gemini-lite` | `gemini-2.5-flash-lite` | Google Gen AI SDK | OK |
| Текст research | `gemini-pro` | `gemini-2.5-pro` | Google Gen AI SDK | OK |
| Open MaaS baseline | `deepseek-v32` | `deepseek-ai/deepseek-v3.2-maas` | OpenAI-compatible Vertex endpoint | OK |
| Image baseline | `gemini-image` | `gemini-2.5-flash-image` | Google Gen AI SDK | OK |
| Image baseline | `imagen-fast` | `imagen-4.0-fast-generate-001` | Google Gen AI SDK | OK |
| Video baseline | `veo-fast` | `veo-3.1-fast-generate-001` | Google Gen AI SDK / LRO | OK |

Для обычного приложения:

```text
primary: gemini-2.5-flash
cheap: gemini-2.5-flash-lite
research: gemini-2.5-pro
open-maas fallback/research: deepseek-ai/deepseek-v3.2-maas
image: gemini-2.5-flash-image или imagen-4.0-fast-generate-001
video: veo-3.1-fast-generate-001 только по явному запросу
```

## Open MaaS модели, проверенные на trial

Профиль `open-maas-candidates` содержит только те Open MaaS модели, которые имеют смысл проверять дальше на текущем Free Trial проекте. Модели, уже давшие устойчивый `404` / `429`, вынесены в `excluded-free-trial` и не входят в рабочий профиль.

Команда:

```powershell
python W:\MyIdeas\AlionIT\help-with-my-projects\Ai-clouds\google-cloud-vertex-ai\examples\test_vertex_text_routes.py --project-root W:\MyIdeas\VibeImp\app --profile open-maas-candidates --max-tokens 40 --continue-on-error
```

Дополнительная проверка с `--prompt "Ответь ровно одним словом: OK"` и `--max-tokens 160` выполнялась для thinking-моделей.

| Алиас | Model ID для endpoint | Статус на 2026-04-30 | Комментарий |
| --- | --- | --- | --- |
| `deepseek-v32` | `deepseek-ai/deepseek-v3.2-maas` | OK | Рабочий baseline |
| `kimi-k2` | `moonshotai/kimi-k2-thinking-maas` | OK | Thinking-модель, нужен нормальный `max_tokens` |
| `gpt-oss-20b` | `openai/gpt-oss-20b-maas` | OK | Хороший лёгкий open baseline |
| `gpt-oss-120b` | `openai/gpt-oss-120b-maas` | OK | Более тяжёлый research/coding вариант |
| `minimax-m2` | `minimaxai/minimax-m2-maas` | OK | Может отдавать `<think>` в ответе |
| `qwen-next-instruct` | `qwen/qwen3-next-80b-a3b-instruct-maas` | OK | Один раз был transient `429`, повторный smoke-test прошёл |
| `qwen-next-thinking` | `qwen/qwen3-next-80b-a3b-thinking-maas` | OK | Thinking-модель |
| `qwen-coder` | `qwen/qwen3-coder-480b-a35b-instruct-maas` | OK | Кандидат для coding tasks |
| `glm-47` | `zai-org/glm-4.7-maas` | OK / HTTP 200 | При малом лимите токенов ушёл в reasoning без финального текста |
| `glm-5` | `zai-org/glm-5-maas` | OK | Кандидат для сложного reasoning |

Важно: для OpenAI-compatible Vertex endpoint нужен формат:

```text
publisher/model
```

Например:

```text
deepseek-ai/deepseek-v3.2-maas
openai/gpt-oss-20b-maas
qwen/qwen3-coder-480b-a35b-instruct-maas
zai-org/glm-5-maas
```

Короткий ID без publisher часто даёт:

```text
400 INVALID_ARGUMENT: expected <publisher>/<model>
```

## Проверенные, но исключённые модели

| Provider | Model ID | Route | Результат | Решение |
| --- | --- | --- | --- | --- |
| Anthropic | `claude-haiku-4-5@20251001` | `publishers/anthropic/...:rawPredict` | `429 RESOURCE_EXHAUSTED` | Исключить до paid billing / quota / enablement |
| Mistral | `mistral-small-2503` | `publishers/mistralai/...:rawPredict` | `404 NOT_FOUND` | Исключить до paid billing / Model Garden enablement |
| Meta Llama | `meta/llama-4-scout-17b-16e-instruct-maas` | OpenAI-compatible endpoint, `us-east5` | `404 NOT_FOUND` | Не брать в baseline |
| Meta Llama | `meta/llama-4-maverick-17b-128e-instruct-maas` | OpenAI-compatible endpoint, `us-east5` | `404 NOT_FOUND` | Не брать в baseline |

Вывод: если модель относится к partner MaaS или уже дала `429` / `404` в trial-проекте, агент не должен выбирать её для текущих приложений.

## Изображения

Проверены на `W:\MyIdeas\VibeImp\app`:

```powershell
python W:\MyIdeas\AlionIT\help-with-my-projects\Ai-clouds\google-cloud-vertex-ai\examples\test_free_trial_media_routes.py --project-root W:\MyIdeas\VibeImp\app --profile images --allow-cost --continue-on-error
```

Результат:

| Алиас | Model ID | Статус | Вывод |
| --- | --- | --- | --- |
| `gemini-image` | `gemini-2.5-flash-image` | OK | PNG создан |
| `imagen-fast` | `imagen-4.0-fast-generate-001` | OK | PNG создан |

Выходные файлы были сохранены в:

```text
W:\MyIdeas\VibeImp\app\temp\vertex-ai-smoke-output
```

Рекомендация:

- для conversational image editing использовать `gemini-2.5-flash-image`
- для простой генерации изображений использовать `imagen-4.0-fast-generate-001`
- `imagen-4.0-generate-001` оставить как более качественный, но не дефолтный вариант

## Видео

Проверено на `W:\MyIdeas\VibeImp\app`:

```powershell
python W:\MyIdeas\AlionIT\help-with-my-projects\Ai-clouds\google-cloud-vertex-ai\examples\test_free_trial_media_routes.py --project-root W:\MyIdeas\VibeImp\app --profile video --allow-cost --allow-video-cost --timeout-seconds 900 --continue-on-error
```

Результат:

| Алиас | Model ID | Статус | Вывод |
| --- | --- | --- | --- |
| `veo-fast` | `veo-3.1-fast-generate-001` | OK | MP4 создан |

Выходной файл был сохранён в:

```text
W:\MyIdeas\VibeImp\app\temp\vertex-ai-smoke-output\veo-fast-1.mp4
```

Видео не запускать автоматически в обычных тестах: оно тратит заметно больше credits, чем текст и изображения.

## Команды проверки

Показать текстовые маршруты:

```powershell
python W:\MyIdeas\AlionIT\help-with-my-projects\Ai-clouds\google-cloud-vertex-ai\examples\test_vertex_text_routes.py --list
```

Проверить базовый free-text набор:

```powershell
python W:\MyIdeas\AlionIT\help-with-my-projects\Ai-clouds\google-cloud-vertex-ai\examples\test_vertex_text_routes.py --project-root . --profile free-text --max-tokens 40 --continue-on-error
```

Проверить рабочие Open MaaS модели:

```powershell
python W:\MyIdeas\AlionIT\help-with-my-projects\Ai-clouds\google-cloud-vertex-ai\examples\test_vertex_text_routes.py --project-root . --profile open-maas-candidates --max-tokens 80 --continue-on-error
```

Посмотреть исключённые Free Trial модели диагностически, без ожидания успешного результата:

```powershell
python W:\MyIdeas\AlionIT\help-with-my-projects\Ai-clouds\google-cloud-vertex-ai\examples\test_vertex_text_routes.py --project-root . --profile excluded-free-trial --max-tokens 40 --continue-on-error
```

Показать media маршруты:

```powershell
python W:\MyIdeas\AlionIT\help-with-my-projects\Ai-clouds\google-cloud-vertex-ai\examples\test_free_trial_media_routes.py --list
```

Проверить изображения:

```powershell
python W:\MyIdeas\AlionIT\help-with-my-projects\Ai-clouds\google-cloud-vertex-ai\examples\test_free_trial_media_routes.py --project-root . --profile images --allow-cost --continue-on-error
```

Проверить видео:

```powershell
python W:\MyIdeas\AlionIT\help-with-my-projects\Ai-clouds\google-cloud-vertex-ai\examples\test_free_trial_media_routes.py --project-root . --profile video --allow-cost --allow-video-cost --timeout-seconds 900 --continue-on-error
```

## Что агент должен делать

Если проект остаётся на Free Trial / $300 credits:

1. Сначала читать этот файл.
2. Не выбирать Claude, Mistral, Grok, AI21 и Llama как baseline.
3. Для текста начинать с `gemini-2.5-flash`.
4. Для research брать `gemini-2.5-pro` или `deepseek-ai/deepseek-v3.2-maas`.
5. Open MaaS модели подключать только через `publisher/model`.
6. Для изображений брать `gemini-2.5-flash-image` или `imagen-4.0-fast-generate-001`.
7. Для видео брать `veo-3.1-fast-generate-001` только по явному запросу пользователя.
8. Не менять credentials при `429` / `404`; это доступность, квоты или модельный route.

## Источники

- Google Cloud Free Trial: https://cloud.google.com/free/docs/free-cloud-features
- Vertex AI Google models: https://docs.cloud.google.com/vertex-ai/generative-ai/docs/models
- Open MaaS APIs: https://docs.cloud.google.com/vertex-ai/generative-ai/docs/maas/call-open-model-apis
- Grant access to open models: https://docs.cloud.google.com/vertex-ai/generative-ai/docs/maas/grant-access-open-models
- Gemini image generation: https://docs.cloud.google.com/vertex-ai/generative-ai/docs/multimodal/image-generation
- Imagen API: https://docs.cloud.google.com/vertex-ai/generative-ai/docs/model-reference/imagen-api
- Veo text-to-video: https://docs.cloud.google.com/vertex-ai/generative-ai/docs/video/generate-videos-from-text
