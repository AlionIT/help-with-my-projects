# Agent brief: Google Cloud / Vertex AI

Этот файл — центральная инструкция для подключения Google Cloud / Vertex AI / Gemini в локальных Electron/Node.js проектах.

Полная база знаний лежит здесь:

```text
W:\MyIdeas\AlionIT\help-with-my-projects\Ai-clouds\google-cloud-vertex-ai
```

## Как использовать этот файл

Когда в любом другом проекте нужно подключить Google Cloud / Vertex AI / Gemini, дай агенту промпт из следующего блока. Агент должен прочитать этот `AGENT-BRIEF.md` по полному пути и работать по нему.

## Промпт для агента

```text
Перед работой с Google Cloud / Vertex AI / Gemini прочитай центральную инструкцию:
W:\MyIdeas\AlionIT\help-with-my-projects\Ai-clouds\google-cloud-vertex-ai\AGENT-BRIEF.md

Используй основную схему:
.env.local -> service account JSON -> ADC -> Vertex AI -> Gemini

В подготовленных проектах .env.local уже должен быть создан. Не пересоздавай и не перезаписывай его без отдельной причины.
Не используй API key.
Не коммить .env.local.
Не копируй service account JSON в проект.
Не выводи private_key.
Не передавай credentials в renderer process.

Если нужно подключить AI в Electron, сначала определи реальный main process файл через package.json, затем подключи src/load-env.cjs в самом начале main process до Google SDK и AI-модулей.
```

Если нужно больше контекста, сначала читай:

- `README.md`
- `7-project-service-account-auth.md`
- `examples/test_service_account_adc.py`
- `examples/test_gcloud_user_adc.py`

## Главная схема

По умолчанию используй service account схему:

```text
project .env.local
-> GOOGLE_APPLICATION_CREDENTIALS
-> W:/MyIdeas/_secrets/gcp-base-dev.json
-> service account
-> Google ADC
-> Vertex AI
-> Gemini
```

Не начинай с API key и не делай новую схему через пользовательский `gcloud`, если пользователь прямо не просит диагностику старого способа.

## Текущие параметры

```text
Google Cloud project id:
project-f2d88164-6230-481c-930

Service account:
dev-491@project-f2d88164-6230-481c-930.iam.gserviceaccount.com

Vertex AI location:
global

Dev credentials path:
W:/MyIdeas/_secrets/gcp-base-dev.json
```

Важно: путь к JSON можно фиксировать в `.env.local`, `.env.example` и документации. Нельзя переносить JSON в проект, коммитить его или выводить `private_key`.

## Что должно быть в проекте

В целевом Electron/Node проекте должны быть:

- `.env.local` с локальным путем к service account JSON
- `.env.example` с шаблоном нужных переменных
- защитный блок в `.gitignore`
- `scripts/check-google-env.cjs`
- `src/load-env.cjs`
- npm-пакет `dotenv`
- script `"check:google": "node scripts/check-google-env.cjs"`

В уже подготовленных проектах `.env.local` уже создан скриптом `setup-google-env.ps1`. Агент не должен пересоздавать или перезаписывать его без отдельной причины. Если `.env.local` отсутствует, это отдельная ситуация первичной настройки: сначала проверь `.env.example`, `.gitignore` и контекст проекта.

Ожидаемое содержимое `.env.local`:

```dotenv
GOOGLE_APPLICATION_CREDENTIALS=W:/MyIdeas/_secrets/gcp-base-dev.json
GOOGLE_CLOUD_LOCATION=global
```

`.env.local` не коммитить.

## Проверка готовности Node/Electron проекта

```powershell
npm run check:google
```

или:

```powershell
node scripts/check-google-env.cjs
```

`scripts/check-google-env.cjs` не обращается к Gemini и не делает сетевой запрос к нейросети. Он только проверяет, что проект видит `.env.local`, `GOOGLE_APPLICATION_CREDENTIALS` и service account JSON.

## Проверка service account с реальным Gemini запросом

Если в проекте есть Python test-файл:

```powershell
cd temp
python .\test_service_account_adc.py
```

Этот тест уже обращается к Vertex AI / Gemini по новой service-account схеме.

Центральный пример:

```text
W:\MyIdeas\AlionIT\help-with-my-projects\Ai-clouds\google-cloud-vertex-ai\examples\test_service_account_adc.py
```

## Старый контрольный gcloud ADC тест

Старый тест нужен только как диагностика пользовательского Google Cloud CLI ADC:

```powershell
cd temp
python .\test_gcloud_user_adc.py
```

Центральный пример:

```text
W:\MyIdeas\AlionIT\help-with-my-projects\Ai-clouds\google-cloud-vertex-ai\examples\test_gcloud_user_adc.py
```

Этот тест не читает `.env.local` и не использует service account JSON явно. Не переписывай его под service account, если он нужен как контроль старой схемы.

## Подключение в Electron main process

`src/load-env.cjs` сам ничего не делает, пока его не импортировали в Electron main process.

Перед правкой:

1. Открой `package.json`.
2. Найди поле `main` или script, который запускает Electron.
3. Определи реальный main process файл.
4. Открой его и вставь загрузку env максимально близко к началу.
5. Вставка должна быть до Google SDK, AI-модулей и любых модулей, которые читают `process.env`.

CommonJS пример, если main-файл лежит в корне проекта:

```js
const { loadEnv } = require("./src/load-env.cjs");

const loadedEnvPath = loadEnv();

if (loadedEnvPath) {
  console.log("Loaded env:", loadedEnvPath);
} else {
  console.warn("No .env.local or .env file found");
}
```

Если main-файл лежит, например, в `desktop/main.js`, путь будет другим:

```js
const { loadEnv } = require("../src/load-env.cjs");
```

Не вставляй путь вслепую. Сначала определи реальное расположение main-файла.

## Правильная Electron архитектура

Правильно:

```text
renderer
-> ipcRenderer.invoke(...)
-> main process
-> Google SDK / Vertex AI
-> main process возвращает результат в renderer
```

Неправильно:

- renderer читает `GOOGLE_APPLICATION_CREDENTIALS`
- renderer читает service account JSON
- renderer получает `private_key`
- renderer показывает путь к JSON в UI
- renderer напрямую создает Google SDK клиент с credentials

## Запреты

Нельзя:

- открывать или выводить содержимое `private_key`
- коммитить `.env.local`
- переносить service account JSON внутрь проекта
- зашивать путь к JSON в исходный код приложения
- передавать credentials в renderer process
- использовать обычный Google API key для Vertex AI
- добавлять в `.gitignore` общий `*.json`
- менять архитектуру проекта без необходимости

## Что делать агенту в новом проекте

1. Прочитать этот brief.
2. Осмотреть структуру проекта и `package.json`.
3. Проверить наличие `.env.example`, `.gitignore`, `src/load-env.cjs`, `scripts/check-google-env.cjs`.
4. Учитывать, что `.env.local` в подготовленных проектах уже должен существовать; не пересоздавать и не перезаписывать его без причины.
5. Запустить `npm run check:google`, если скрипт уже есть.
6. Подключать Google SDK только в main process или backend-части проекта.
7. Для Electron UI использовать IPC, а не прямой доступ renderer к credentials.
