# 🛠 Решение частых проблем

## Ошибка: 404 Publisher Model Not Found
**Текст ошибки:** `404 Publisher Model was not found or your project does not have access to it.`
**Когда возникает:** Обычно при самом первом запуске скрипта в новом проекте.
**Причины и решения:**

1. **Неверный Project ID:**
   Убедитесь, что в коде (в `genai.Client(project="...")`) указан правильный ID проекта. Утилита `gcloud` часто использует системный ID (например, `project-f2d88164...`), в то время как ваш настоящий проект может называться `my-first-project-123`.
2. **Выключен Vertex AI API:**
   В новых проектах Google все API выключены по умолчанию (для защиты от биллинга). Зайдите в Google Cloud Console, в поиске вбейте "Vertex AI API" и нажмите синюю кнопку **ENABLE**. Потребуется подождать 1-2 минуты.
3. **Не привязан Биллинг (Оплата):**
   Vertex AI — платный инструмент. Даже если у вас есть подарочные кредиты ($300), к проекту должен быть привязан Billing Account. Перейдите в раздел **Billing** в консоли и привяжите аккаунт, иначе Гугл заблокирует доступ к моделям.

## Ошибка: 429 RESOURCE_EXHAUSTED

**Текст ошибки:** `429 {"error":{"code":429,"message":"Resource has been exhausted","status":"RESOURCE_EXHAUSTED"}}`

**Когда возникает:** особенно часто при partner/open MaaS моделях: Claude, Mistral, DeepSeek, Qwen и похожих моделях из Model Garden.

Если `gemini-2.5-flash` отвечает, а Claude или другая partner-модель возвращает `429`, это обычно не проблема service account JSON и не проблема `private_key`.

Что проверить:

1. Конкретная модель включена в Model Garden именно для текущего Google Cloud project.
2. Partner terms / Marketplace terms приняты для этой модели.
3. Service account имеет доступ к Vertex AI и к конкретной partner/open модели.
4. Выбран правильный регион или `global`, если модель поддерживает global endpoint.
5. Не исчерпаны QPM/TPM quotas для модели, региона и endpoint-типа.
6. Для Claude сначала проверять `claude-haiku-4-5@20251001`, потом Sonnet, потом Opus.
7. В приложении должен быть retry с exponential backoff и fallback на Gemini.

Не решать `429` заменой service account JSON или переносом credentials в renderer process. Сначала смотреть `9-text-model-routing.md`.

## Free Trial: partner MaaS не входит в baseline

Google Cloud Free Trial / $300 credits не является полным доступом ко всем моделям Model Garden.

Официальное ограничение Free Trial: нельзя использовать Free Trial credits для generative AI partner models offered as managed APIs / MaaS. Также Free Trial account не может запрашивать quota increase.

Практически для нас это значит:

- Claude/Mistral/Grok/AI21 не брать как рабочий baseline на Free Trial.
- Если Claude даёт `429 RESOURCE_EXHAUSTED`, это не лечится заменой JSON-ключа.
- Если Mistral/Llama даёт `404 NOT_FOUND`, это не лечится заменой `.env.local`.
- Рабочий список Free Trial смотреть в `10-free-trial-models.md`.

## Желтое предупреждение: UserWarning (Deprecated)
**Текст:** `UserWarning: This feature is deprecated as of June 24, 2025...`
**Решение:** Если вы видите эту ошибку, значит, вы используете старую библиотеку `google-cloud-aiplatform`. Удалите её и перепишите код под новую библиотеку `google-genai` (см. файл `examples/test_gcloud_user_adc.py`).
