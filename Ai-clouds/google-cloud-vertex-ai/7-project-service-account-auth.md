# Google Cloud / Vertex AI auth в Electron/Node проектах

Этот документ фиксирует текущую схему авторизации Google Cloud / Vertex AI / Gemini для локальных Electron/Node.js проектов на Windows.

В этой справочной папке примеры лежат в `examples/`. В целевых приложениях рабочие проверочные файлы лежат в `temp/`, например:

- `temp/test_gcloud_user_adc.py` — старый контрольный тест через Google Cloud CLI ADC.
- `temp/test_service_account_adc.py` — новый тест через `.env.local` и service account JSON.

## Краткий итог

В проектах теперь есть две схемы авторизации:

1. **Старая контрольная схема:** `gcloud ADC user credentials`.
2. **Новая основная схема:** `.env.local -> service account JSON -> ADC -> Vertex AI -> Gemini`.

Новая схема является основной для Electron/Node проектов, потому что она не зависит от того, какой пользователь сейчас залогинен в Google Cloud CLI. Проект сам читает `.env.local`, получает путь к service account JSON через `GOOGLE_APPLICATION_CREDENTIALS`, а Google SDK использует этот путь через стандартный механизм ADC.

Старую схему оставляем как контрольный тест. Она полезна, чтобы быстро понять, работает ли авторизация через локальный Google Cloud CLI, но она не должна быть основной схемой приложения.

## Что уже настроено

Для локальной подготовки проектов использовался PowerShell-скрипт:

```powershell
.\setup-google-env.ps1 -RootPath "W:\MyIdeas" -RepoName "app"
```

Схема поиска была безопасной:

- `RootPath\RepoName`
- `RootPath\*\RepoName`
- без глубокой рекурсии
- папки, начинающиеся с `_`, пропускались

Скрипт нашел и обработал 10 репозиториев:

- `W:\MyIdeas\3passwords\app`
- `W:\MyIdeas\AlionIT\app`
- `W:\MyIdeas\AvantaCanvas\app`
- `W:\MyIdeas\CTRL-CCV\app`
- `W:\MyIdeas\ideaNamer\app`
- `W:\MyIdeas\kikNotes\app`
- `W:\MyIdeas\TalkingMirror\app`
- `W:\MyIdeas\VibeDictionary\app`
- `W:\MyIdeas\VibeImp\app`
- `W:\MyIdeas\VibePlans\app`

В каждом проекте скрипт должен был:

- добавить защитный блок в `.gitignore`
- создать или обновить `.env.local`
- создать или обновить `.env.example`
- создать `scripts/check-google-env.cjs`
- создать `src/load-env.cjs`
- добавить npm-script `check:google` в `package.json`
- установить npm-пакет `dotenv`
- выполнить `npm run check:google`

Итог запуска:

- успешно обработано: 10
- пропущено: 0
- с ошибками: 0

## Общий service account JSON

Для локальной разработки разных проектов используется общий dev service account JSON:

```text
W:\MyIdeas\_secrets\gcp-base-dev.json
```

Это не файл проекта. Его нельзя переносить внутрь репозитория и нельзя коммитить.

Текущие параметры Google Cloud:

```text
Google Cloud project id:
project-f2d88164-6230-481c-930

Service account:
dev-491@project-f2d88164-6230-481c-930.iam.gserviceaccount.com

Vertex AI location:
global
```

Важно: в документации можно фиксировать путь к файлу и email service account, но нельзя выводить содержимое JSON-ключа, особенно `private_key`.

## Новая основная схема: .env.local + service account JSON

Основной поток авторизации:

```text
Electron/Node проект
-> .env.local
-> GOOGLE_APPLICATION_CREDENTIALS
-> W:/MyIdeas/_secrets/gcp-base-dev.json
-> service account dev-491
-> Google ADC
-> Vertex AI
-> Gemini
```

Преимущество этой схемы: она не зависит от локального пользователя `gcloud`. Даже если в Google Cloud CLI залогинен другой аккаунт или CLI вообще не используется в момент запуска приложения, проект все равно может авторизоваться через service account JSON, указанный в `.env.local`.

Для будущего Electron-приложения именно эта схема должна быть основной.

## Старая контрольная схема: gcloud ADC

Старая схема:

```text
Python script
-> Google Gen AI SDK
-> Application Default Credentials
-> credentials из Google Cloud CLI
-> Vertex AI
-> Gemini
```

Она появляется после настройки:

```powershell
gcloud auth application-default login
```

Старый тестовый файл:

```text
temp/test_gcloud_user_adc.py
```

В этой справочной папке соответствующий пример:

```text
examples/test_gcloud_user_adc.py
```

Старый тест создает `genai.Client(...)` с `vertexai=True`, `project="project-f2d88164-6230-481c-930"` и `location="global"`, но не читает `.env.local`, не показывает путь к service account JSON и не использует явно `W:\MyIdeas\_secrets\gcp-base-dev.json`.

Если он отвечает от Gemini, это означает, что старая пользовательская авторизация через Google Cloud CLI ADC работает.

## Разница между схемами

| Вопрос | Старая схема: gcloud ADC | Новая схема: project .env.local + service account JSON |
| --- | --- | --- |
| Источник credentials | Локальный Google Cloud CLI | `GOOGLE_APPLICATION_CREDENTIALS` из `.env.local` |
| Кто авторизуется | Пользователь, залогиненный через `gcloud` | Service account `dev-491` |
| Зависит от `gcloud` login | Да | Нет |
| Читает `.env.local` | Нет | Да |
| Показывает service account | Нет | Да, email service account |
| Показывает путь к JSON | Нет | Да, путь из `GOOGLE_APPLICATION_CREDENTIALS` |
| Основная для Electron | Нет, только контроль | Да |

## .env.local и .env.example

В уже подготовленных целевых проектах `.env.local` уже создан скриптом `setup-google-env.ps1`. Его не нужно пересоздавать или перезаписывать без отдельной причины.

Ожидаемое содержимое `.env.local`:

```dotenv
GOOGLE_APPLICATION_CREDENTIALS=W:/MyIdeas/_secrets/gcp-base-dev.json
GOOGLE_CLOUD_LOCATION=global
```

`.env.local` хранит локальные настройки разработчика и не должен коммититься.

`.env.example` может содержать такой же шаблон, чтобы было понятно, какие переменные нужны:

```dotenv
GOOGLE_APPLICATION_CREDENTIALS=W:/MyIdeas/_secrets/gcp-base-dev.json
GOOGLE_CLOUD_LOCATION=global
```

Если в будущем путь к dev-ключу изменится, менять нужно `.env.local`, `.env.example` и документацию. Нельзя зашивать этот путь в исходный код приложения.

## .gitignore

В проектах должен быть защитный блок:

```gitignore
.env
.env.*
!.env.example

secrets/
credentials/

*_service_account*.json
*service-account*.json
*credentials*.json
*gcp*key*.json
```

Нельзя добавлять просто:

```gitignore
*.json
```

В Electron/Node проектах есть нормальные JSON-файлы, которые должны оставаться в репозитории: `package.json`, `package-lock.json`, `tsconfig.json`, `electron-builder.json` и другие.

## Проверка credentials через npm run check:google

В проектах есть проверочный скрипт:

```text
scripts/check-google-env.cjs
```

Запуск:

```powershell
npm run check:google
```

или напрямую:

```powershell
node scripts/check-google-env.cjs
```

Этот скрипт проверяет только базовую готовность credentials:

- найден ли `.env.local`
- загрузился ли `.env.local` через `dotenv`
- есть ли `GOOGLE_APPLICATION_CREDENTIALS`
- существует ли JSON-файл по этому пути
- валидный ли это JSON
- является ли JSON ключом `service_account`
- есть ли `project_id`
- есть ли `client_email`
- есть ли `private_key`

Важно: `scripts/check-google-env.cjs` не обращается к Gemini, Vertex AI или другой нейронной сети. Он только проверяет, что проект видит env-файл и service account JSON. Скрипт может проверить наличие поля `private_key`, но не должен выводить значение приватного ключа.

## Новый Python-тест temp/test_service_account_adc.py

Новый тестовый файл:

```text
temp/test_service_account_adc.py
```

В этой справочной папке соответствующий пример:

```text
examples/test_service_account_adc.py
```

Запуск из целевого проекта:

```powershell
cd temp
python .\test_service_account_adc.py
```

В целевом проекте тест обычно лежит в папке `temp` внутри корня проекта:

```text
project/temp/test_service_account_adc.py
-> project/.env.local
```

Логика теста:

- если скрипт лежит в `temp`, находит корень проекта как папку на уровень выше `temp`
- если скрипт запускается из другого места, проверяет текущую рабочую папку и соседние разумные кандидаты
- сначала ищет `project/.env.local`
- если `.env.local` нет, ищет `project/.env`
- читает `GOOGLE_APPLICATION_CREDENTIALS`
- проверяет, что JSON-файл существует
- проверяет, что JSON является `service_account`
- берет `project_id` из `GOOGLE_CLOUD_PROJECT` или из JSON
- берет location из `GOOGLE_CLOUD_LOCATION` или использует `global`
- выставляет `GOOGLE_GENAI_USE_VERTEXAI=True`
- создает `genai.Client(...)`
- отправляет запрос к `gemini-2.5-flash`

Важно: `temp/test_service_account_adc.py` уже обращается к нейронной сети по новой схеме. Если он получил ответ от Gemini, значит вся цепочка `.env.local -> service account JSON -> ADC -> Vertex AI -> Gemini` работает.

Рабочий запуск этой service-account схемы был проверен в проекте:

```text
W:\MyIdeas\VibeImp\app
```

После переименования команда для такого же запуска:

```powershell
cd W:\MyIdeas\VibeImp\app\temp
python .\test_service_account_adc.py
```

Проверенный вывод показывал:

```text
Loaded env file: W:\MyIdeas\VibeImp\app\.env.local

Подключаемся к Google Cloud через service account...
Project root: W:\MyIdeas\VibeImp\app
Project: project-f2d88164-6230-481c-930
Location: global
Service account: dev-491@project-f2d88164-6230-481c-930.iam.gserviceaccount.com
Credentials: W:\MyIdeas\_secrets\gcp-base-dev.json

--- ОТВЕТ ОТ НЕЙРОСЕТИ ---
Привет! Вот один интересный факт:
Один день на Венере длится дольше, чем её год.
```

Это доказывает, что новая service-account схема работает полностью.

## Старый контрольный Python-тест temp/test_gcloud_user_adc.py

Старый тестовый файл:

```text
temp/test_gcloud_user_adc.py
```

В этой справочной папке соответствующий пример:

```text
examples/test_gcloud_user_adc.py
```

Запуск из целевого проекта:

```powershell
cd temp
python .\test_gcloud_user_adc.py
```

Этот тест:

- импортирует `google.genai`
- создает `genai.Client(vertexai=True, project=..., location=...)`
- отправляет запрос к `gemini-2.5-flash`
- получает ответ от нейросети

Но он:

- не читает `.env.local`
- не показывает `Loaded env file`
- не показывает service account
- не показывает `Credentials`
- не использует явно `W:\MyIdeas\_secrets\gcp-base-dev.json`

Поэтому, если старый тест работает, это означает только то, что работает старая схема Google Cloud CLI ADC. Его не нужно переписывать под новую схему, потому что тогда он перестанет быть независимым контрольным тестом.

## Подключение src/load-env.cjs в Electron main process

В проектах есть файл:

```text
src/load-env.cjs
```

Его задача:

- читать `.env.local` из корня проекта
- если `.env.local` нет, читать `.env`
- загрузить значения в `process.env` через `dotenv`
- вернуть путь к загруженному env-файлу
- вернуть `null`, если env-файл не найден

Этот файл сам по себе ничего не подключает. Он начнет работать только после явного импорта в Electron main process.

Алгоритм подключения:

1. Открыть `package.json`.
2. Найти поле `main` или script `start`, который запускает Electron.
3. Определить реальный файл Electron main process.
4. Открыть этот main-файл.
5. Вставить загрузку env максимально близко к началу файла.
6. Сделать это до подключения Google SDK, AI-модулей и любых модулей, которые могут читать `process.env`.

Пример для CommonJS main-файла в корне проекта:

```js
const { loadEnv } = require("./src/load-env.cjs");

const loadedEnvPath = loadEnv();

if (loadedEnvPath) {
  console.log("Loaded env:", loadedEnvPath);
} else {
  console.warn("No .env.local or .env file found");
}
```

Если main-файл лежит, например, в `desktop/main.js`, путь должен быть другим:

```js
const { loadEnv } = require("../src/load-env.cjs");
```

Нельзя вставлять путь вслепую. Сначала нужно определить реальное расположение main-файла.

После подключения архитектура должна быть такой:

```text
renderer
-> ipcRenderer.invoke(...)
-> main process
-> Google SDK / Vertex AI
-> main process возвращает результат в renderer
```

## Почему нельзя передавать credentials в renderer

Renderer process — это UI-слой. Он ближе к браузерной среде, DevTools, пользовательским данным и потенциально небезопасному контенту. Поэтому туда нельзя передавать credentials.

Неправильно:

- renderer читает `GOOGLE_APPLICATION_CREDENTIALS`
- renderer читает service account JSON
- renderer получает `private_key`
- renderer показывает путь к JSON в UI
- renderer напрямую создает Google SDK клиент с credentials

Правильно:

- main process читает env
- main process создает Google SDK клиент
- renderer вызывает main process через IPC
- main process возвращает в renderer только результат операции

## Что еще не подключено автоматически

`src/load-env.cjs` уже подготовлен в проектах, но он не гарантирует, что Electron-приложение уже использует новую схему.

Пока `loadEnv()` не импортирован и не вызван в Electron main process:

- `.env.local` может не загружаться при старте приложения
- `process.env.GOOGLE_APPLICATION_CREDENTIALS` может быть пустым внутри Electron
- Google SDK может уйти в другую ADC-схему
- приложение может случайно зависеть от локального `gcloud` login

Следующий шаг для каждого Electron-проекта: отдельно и минимально подключить `src/load-env.cjs` в его реальный main process.

## Что нельзя делать

Нельзя:

- открывать и выводить содержимое `private_key`
- коммитить `.env.local`
- переносить service account JSON внутрь проекта
- зашивать путь к JSON-ключу в исходный код приложения
- передавать credentials в renderer process
- показывать путь к JSON или service account details в UI
- отправлять JSON-ключ в логи, issue, чат или pull request
- добавлять в `.gitignore` общий `*.json`
- переписывать `temp/test_gcloud_user_adc.py` под новую схему, если он нужен как старый контрольный тест

Можно:

- хранить путь к JSON в `.env.local`
- показывать шаблон переменных в `.env.example`
- документировать путь к dev-ключу в этой локальной справочной базе
- проверять наличие `private_key`, не выводя его значение
- использовать `npm run check:google` перед подключением Google SDK в Electron

## Быстрые команды проверки

Проверить, что Node/Electron проект видит env и service account JSON:

```powershell
npm run check:google
```

Проверить новую service-account схему с реальным запросом к Gemini:

```powershell
cd temp
python .\test_service_account_adc.py
```

Проверить старую Google Cloud CLI ADC схему с реальным запросом к Gemini:

```powershell
cd temp
python .\test_gcloud_user_adc.py
```
