import os
import json
from pathlib import Path


def load_env_file(env_path: Path) -> None:
    if not env_path.exists():
        return

    for raw_line in env_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()

        if not line:
            continue

        if line.startswith("#"):
            continue

        if "=" not in line:
            continue

        key, value = line.split("=", 1)

        key = key.strip()
        value = value.strip()

        if not key:
            continue

        if (
            len(value) >= 2
            and value[0] == value[-1]
            and value[0] in ('"', "'")
        ):
            value = value[1:-1]

        os.environ[key] = value


def unique_candidates(paths):
    candidates = []

    for path in paths:
        resolved_path = path.resolve()

        if resolved_path not in candidates:
            candidates.append(resolved_path)

    return candidates


def find_project_root(script_dir: Path) -> Path:
    paths_to_check = []

    if script_dir.name.lower() == "temp":
        paths_to_check.append(script_dir.parent)

    paths_to_check.extend([
        Path.cwd(),
        Path.cwd().parent,
        script_dir.parent,
    ])

    checked_paths = unique_candidates(paths_to_check)

    for candidate in checked_paths:
        if (candidate / ".env.local").exists() or (candidate / ".env").exists():
            return candidate

    checked_text = "\n".join(f"- {path}" for path in checked_paths)

    raise FileNotFoundError(
        "No .env.local or .env file found. "
        "Run this script from an app root with .env.local or copy it to project/temp.\n"
        "Checked project roots:\n"
        f"{checked_text}"
    )


script_dir = Path(__file__).resolve().parent
project_root = find_project_root(script_dir)

env_local_path = project_root / ".env.local"
env_path = project_root / ".env"

if env_local_path.exists():
    load_env_file(env_local_path)
    print("Loaded env file:", env_local_path)
elif env_path.exists():
    load_env_file(env_path)
    print("Loaded env file:", env_path)
else:
    raise FileNotFoundError(
        f"No .env.local or .env file found in project root: {project_root}"
    )


credentials_path_raw = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")

if not credentials_path_raw:
    raise RuntimeError("GOOGLE_APPLICATION_CREDENTIALS is not set")

credentials_path = Path(credentials_path_raw)

if not credentials_path.exists():
    raise FileNotFoundError(f"Google credentials file not found: {credentials_path}")

with credentials_path.open("r", encoding="utf-8") as file:
    credentials_json = json.load(file)

if credentials_json.get("type") != "service_account":
    raise RuntimeError(
        f"This JSON is not a service account key. type={credentials_json.get('type')}"
    )

if not credentials_json.get("private_key"):
    raise RuntimeError("private_key is missing in service account JSON")

if not credentials_json.get("client_email"):
    raise RuntimeError("client_email is missing in service account JSON")

project_id = os.environ.get("GOOGLE_CLOUD_PROJECT") or credentials_json.get("project_id")
location = os.environ.get("GOOGLE_CLOUD_LOCATION") or "global"

if not project_id:
    raise RuntimeError("Google Cloud project id is missing")

os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = str(credentials_path)
os.environ["GOOGLE_CLOUD_PROJECT"] = project_id
os.environ["GOOGLE_CLOUD_LOCATION"] = location
os.environ["GOOGLE_GENAI_USE_VERTEXAI"] = "True"


from google import genai
from google.genai.types import HttpOptions


print("")
print("Подключаемся к Google Cloud через service account...")
print("Project root:", project_root)
print("Project:", project_id)
print("Location:", location)
print("Service account:", credentials_json.get("client_email"))
print("Credentials:", credentials_path)
print("")

client = genai.Client(
    vertexai=True,
    project=project_id,
    location=location,
    http_options=HttpOptions(api_version="v1"),
)

prompt = "Привет! Напиши один интересный и очень короткий факт про космос."
print(f"Отправляем запрос: {prompt!r}")

try:
    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=prompt,
    )

    print("\n--- ОТВЕТ ОТ НЕЙРОСЕТИ ---")
    print(response.text)

except Exception as error:
    print("\n--- ПРОИЗОШЛА ОШИБКА ---")
    print(error)
    raise
