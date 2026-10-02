import argparse
import json
import os
from dataclasses import dataclass
from pathlib import Path
from typing import Callable

import google.auth
import requests
from google.auth.transport.requests import Request


DEFAULT_PROMPT = "Ответь одной короткой русской фразой: связь с моделью работает?"
DEFAULT_MAX_TOKENS = 120


@dataclass(frozen=True)
class Route:
    alias: str
    family: str
    model: str
    location: str
    description: str
    free_trial: str = "candidate"


ROUTES = {
    "gemini-flash": Route(
        alias="gemini-flash",
        family="gemini",
        model="gemini-2.5-flash",
        location="global",
        description="Базовый текстовый Gemini по умолчанию",
        free_trial="confirmed",
    ),
    "gemini-pro": Route(
        alias="gemini-pro",
        family="gemini",
        model="gemini-2.5-pro",
        location="global",
        description="Сложный анализ и research через Gemini",
        free_trial="confirmed",
    ),
    "gemini-lite": Route(
        alias="gemini-lite",
        family="gemini",
        model="gemini-2.5-flash-lite",
        location="global",
        description="Дешевые массовые текстовые задачи через Gemini",
        free_trial="confirmed",
    ),
    "claude-haiku": Route(
        alias="claude-haiku",
        family="claude",
        model="claude-haiku-4-5@20251001",
        location="global",
        description="Быстрый Claude smoke-test через Anthropic Vertex",
        free_trial="excluded-partner",
    ),
    "claude-sonnet": Route(
        alias="claude-sonnet",
        family="claude",
        model="claude-sonnet-4-6",
        location="global",
        description="Основной Claude для research/coding через Anthropic Vertex",
        free_trial="excluded-partner",
    ),
    "claude-opus": Route(
        alias="claude-opus",
        family="claude",
        model="claude-opus-4-7",
        location="global",
        description="Тяжелый Claude для сложных задач",
        free_trial="excluded-partner",
    ),
    "mistral-small": Route(
        alias="mistral-small",
        family="mistral",
        model="mistral-small-2503",
        location="us-central1",
        description="Быстрый Mistral smoke-test через rawPredict",
        free_trial="excluded-partner",
    ),
    "mistral-medium": Route(
        alias="mistral-medium",
        family="mistral",
        model="mistral-medium-3",
        location="us-central1",
        description="Универсальный Mistral для текста и документов",
        free_trial="excluded-partner",
    ),
    "deepseek-v32": Route(
        alias="deepseek-v32",
        family="open-maas",
        model="deepseek-ai/deepseek-v3.2-maas",
        location="global",
        description="Open MaaS research/agent модель через chat completions",
        free_trial="confirmed",
    ),
    "kimi-k2": Route(
        alias="kimi-k2",
        family="open-maas",
        model="moonshotai/kimi-k2-thinking-maas",
        location="global",
        description="Open MaaS thinking модель Kimi",
        free_trial="confirmed",
    ),
    "gpt-oss-20b": Route(
        alias="gpt-oss-20b",
        family="open-maas",
        model="openai/gpt-oss-20b-maas",
        location="global",
        description="OpenAI OSS 20B open MaaS",
        free_trial="confirmed",
    ),
    "gpt-oss-120b": Route(
        alias="gpt-oss-120b",
        family="open-maas",
        model="openai/gpt-oss-120b-maas",
        location="global",
        description="OpenAI OSS 120B open MaaS",
        free_trial="confirmed",
    ),
    "minimax-m2": Route(
        alias="minimax-m2",
        family="open-maas",
        model="minimaxai/minimax-m2-maas",
        location="global",
        description="MiniMax M2 open MaaS для agent/coding задач",
        free_trial="confirmed",
    ),
    "llama-4-scout": Route(
        alias="llama-4-scout",
        family="open-maas",
        model="meta/llama-4-scout-17b-16e-instruct-maas",
        location="us-east5",
        description="Llama 4 Scout open MaaS, регион us-east5",
        free_trial="excluded-404",
    ),
    "llama-4-maverick": Route(
        alias="llama-4-maverick",
        family="open-maas",
        model="meta/llama-4-maverick-17b-128e-instruct-maas",
        location="us-east5",
        description="Llama 4 Maverick open MaaS, регион us-east5",
        free_trial="excluded-404",
    ),
    "qwen-next-instruct": Route(
        alias="qwen-next-instruct",
        family="open-maas",
        model="qwen/qwen3-next-80b-a3b-instruct-maas",
        location="global",
        description="Qwen3 Next Instruct open MaaS",
        free_trial="confirmed",
    ),
    "qwen-next-thinking": Route(
        alias="qwen-next-thinking",
        family="open-maas",
        model="qwen/qwen3-next-80b-a3b-thinking-maas",
        location="global",
        description="Qwen3 Next Thinking open MaaS",
        free_trial="confirmed",
    ),
    "qwen-coder": Route(
        alias="qwen-coder",
        family="open-maas",
        model="qwen/qwen3-coder-480b-a35b-instruct-maas",
        location="global",
        description="Qwen3 Coder open MaaS",
        free_trial="confirmed",
    ),
    "glm-47": Route(
        alias="glm-47",
        family="open-maas",
        model="zai-org/glm-4.7-maas",
        location="global",
        description="GLM 4.7 open MaaS",
        free_trial="confirmed-token-caveat",
    ),
    "glm-5": Route(
        alias="glm-5",
        family="open-maas",
        model="zai-org/glm-5-maas",
        location="global",
        description="GLM 5 open MaaS",
        free_trial="confirmed",
    ),
}


PROFILES = {
    "gemini-smoke": ["gemini-flash"],
    "basic-text": ["gemini-flash", "gemini-lite", "gemini-pro"],
    "free-text": ["gemini-flash", "gemini-lite", "gemini-pro", "deepseek-v32"],
    "open-maas-candidates": [
        "deepseek-v32",
        "kimi-k2",
        "gpt-oss-20b",
        "gpt-oss-120b",
        "minimax-m2",
        "qwen-next-instruct",
        "qwen-next-thinking",
        "qwen-coder",
        "glm-47",
        "glm-5",
    ],
    "excluded-partner": ["claude-haiku", "mistral-small"],
    "excluded-free-trial": [
        "claude-haiku",
        "mistral-small",
        "llama-4-scout",
        "llama-4-maverick",
    ],
    "partner-smoke": ["claude-haiku", "mistral-small"],
    "research": ["gemini-pro", "deepseek-v32", "kimi-k2", "qwen-next-thinking"],
    "claude": ["claude-haiku", "claude-sonnet", "claude-opus"],
}


def load_env_file(env_path: Path) -> None:
    if not env_path.exists():
        return

    for raw_line in env_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()

        if not line or line.startswith("#") or "=" not in line:
            continue

        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip()

        if not key:
            continue

        if len(value) >= 2 and value[0] == value[-1] and value[0] in ('"', "'"):
            value = value[1:-1]

        os.environ[key] = value


def unique_candidates(paths):
    candidates = []

    for path in paths:
        resolved = path.resolve()

        if resolved not in candidates:
            candidates.append(resolved)

    return candidates


def find_project_root(script_dir: Path, project_root_arg: str | None) -> Path:
    if project_root_arg:
        project_root = Path(project_root_arg).resolve()

        if not project_root.exists():
            raise FileNotFoundError(f"Project root does not exist: {project_root}")

        return project_root

    paths_to_check = []

    if script_dir.name.lower() == "temp":
        paths_to_check.append(script_dir.parent)

    paths_to_check.extend(
        [
            Path.cwd(),
            Path.cwd().parent,
            script_dir.parent,
            script_dir.parent.parent,
        ]
    )

    checked = unique_candidates(paths_to_check)

    for candidate in checked:
        if (candidate / ".env.local").exists() or (candidate / ".env").exists():
            return candidate

    checked_text = "\n".join(f"- {path}" for path in checked)
    raise FileNotFoundError(
        "No .env.local or .env file found. "
        "Run from a prepared app root or pass --project-root.\n"
        "Checked project roots:\n"
        f"{checked_text}"
    )


def load_project_env(project_root: Path) -> Path:
    env_local = project_root / ".env.local"
    env_file = project_root / ".env"

    if env_local.exists():
        load_env_file(env_local)
        return env_local

    if env_file.exists():
        load_env_file(env_file)
        return env_file

    raise FileNotFoundError(f"No .env.local or .env found in {project_root}")


def get_credentials_and_project():
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    credentials, project_id = google.auth.default(scopes=scopes)
    credentials.refresh(Request())

    project_id = os.environ.get("GOOGLE_CLOUD_PROJECT") or project_id

    if not project_id:
        raise RuntimeError(
            "Google Cloud project id is missing. "
            "Set GOOGLE_CLOUD_PROJECT or use a service account JSON with project_id."
        )

    return credentials, project_id


def vertex_host(location: str) -> str:
    if location == "global":
        return "https://aiplatform.googleapis.com"

    return f"https://{location}-aiplatform.googleapis.com"


def auth_headers(credentials) -> dict[str, str]:
    if not credentials.valid:
        credentials.refresh(Request())

    return {
        "Authorization": f"Bearer {credentials.token}",
        "Content-Type": "application/json; charset=utf-8",
    }


def explain_http_failure(status_code: int, response_text: str) -> str:
    if status_code == 429:
        return (
            "RESOURCE_EXHAUSTED: проверь квоты QPM/TPM, endpoint type, регион, "
            "capacity и включение конкретной модели в Model Garden."
        )

    if status_code == 403:
        return (
            "PERMISSION_DENIED: проверь IAM service account, Vertex AI API, "
            "Model Garden enablement и partner terms."
        )

    if status_code == 404:
        return (
            "NOT_FOUND: проверь model ID, publisher, location и доступность модели "
            "в выбранном регионе."
        )

    return response_text


def post_json(url: str, payload: dict, credentials) -> dict:
    response = requests.post(
        url,
        headers=auth_headers(credentials),
        data=json.dumps(payload),
        timeout=120,
    )

    if response.status_code >= 400:
        explanation = explain_http_failure(response.status_code, response.text)
        raise RuntimeError(
            f"HTTP {response.status_code} from Vertex AI.\n"
            f"{explanation}\n"
            f"Raw response: {response.text}"
        )

    return response.json()


def call_gemini(route: Route, project_id: str, prompt: str, max_tokens: int) -> str:
    from google import genai
    from google.genai.types import GenerateContentConfig, HttpOptions

    client = genai.Client(
        vertexai=True,
        project=project_id,
        location=route.location,
        http_options=HttpOptions(api_version="v1"),
    )

    response = client.models.generate_content(
        model=route.model,
        contents=prompt,
        config=GenerateContentConfig(max_output_tokens=max_tokens),
    )

    return response.text or ""


def call_claude(
    route: Route,
    project_id: str,
    prompt: str,
    max_tokens: int,
    credentials,
) -> str:
    url = (
        f"{vertex_host(route.location)}/v1/projects/{project_id}/locations/"
        f"{route.location}/publishers/anthropic/models/{route.model}:rawPredict"
    )
    payload = {
        "anthropic_version": "vertex-2023-10-16",
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": max_tokens,
        "stream": False,
    }
    data = post_json(url, payload, credentials)
    content = data.get("content") or []
    texts = [part.get("text", "") for part in content if part.get("type") == "text"]

    return "\n".join(texts).strip() or json.dumps(data, ensure_ascii=False)


def call_mistral(
    route: Route,
    project_id: str,
    prompt: str,
    max_tokens: int,
    credentials,
) -> str:
    url = (
        f"{vertex_host(route.location)}/v1/projects/{project_id}/locations/"
        f"{route.location}/publishers/mistralai/models/{route.model}:rawPredict"
    )
    payload = {
        "model": route.model,
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": max_tokens,
        "stream": False,
    }
    data = post_json(url, payload, credentials)
    choices = data.get("choices") or []

    if choices:
        message = choices[0].get("message") or {}
        content = message.get("content")

        if isinstance(content, str) and content.strip():
            return content.strip()

        return json.dumps(data, ensure_ascii=False)

    return json.dumps(data, ensure_ascii=False)


def call_open_maas(
    route: Route,
    project_id: str,
    prompt: str,
    max_tokens: int,
    credentials,
) -> str:
    url = (
        f"{vertex_host(route.location)}/v1/projects/{project_id}/locations/"
        f"{route.location}/endpoints/openapi/chat/completions"
    )
    payload = {
        "model": route.model,
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": max_tokens,
        "stream": False,
    }
    data = post_json(url, payload, credentials)
    choices = data.get("choices") or []

    if choices:
        message = choices[0].get("message") or {}
        content = message.get("content")

        if isinstance(content, str) and content.strip():
            return content.strip()

        return json.dumps(data, ensure_ascii=False)

    return json.dumps(data, ensure_ascii=False)


CALLERS: dict[str, Callable] = {
    "gemini": call_gemini,
    "claude": call_claude,
    "mistral": call_mistral,
    "open-maas": call_open_maas,
}


def list_routes() -> None:
    print("Profiles:")
    for profile, aliases in PROFILES.items():
        print(f"- {profile}: {', '.join(aliases)}")

    print("\nRoutes:")
    for alias, route in ROUTES.items():
        print(
            f"- {alias}: family={route.family}, model={route.model}, "
            f"location={route.location}, free_trial={route.free_trial} — "
            f"{route.description}"
        )


def parse_aliases(args) -> list[str]:
    aliases = []

    if args.profile:
        if args.profile not in PROFILES:
            raise RuntimeError(f"Unknown profile: {args.profile}")

        aliases.extend(PROFILES[args.profile])

    if args.only:
        aliases.extend([part.strip() for part in args.only.split(",") if part.strip()])

    if not aliases:
        aliases = PROFILES["gemini-smoke"]

    unknown = [alias for alias in aliases if alias not in ROUTES]

    if unknown:
        raise RuntimeError(f"Unknown route alias: {', '.join(unknown)}")

    return aliases


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Smoke-test Gemini and partner text model routes through Vertex AI."
    )
    parser.add_argument("--project-root", help="Prepared app root with .env.local")
    parser.add_argument("--profile", choices=sorted(PROFILES))
    parser.add_argument("--only", help="Comma-separated route aliases")
    parser.add_argument("--prompt", default=DEFAULT_PROMPT)
    parser.add_argument("--max-tokens", type=int, default=DEFAULT_MAX_TOKENS)
    parser.add_argument("--continue-on-error", action="store_true")
    parser.add_argument("--list", action="store_true")
    args = parser.parse_args()

    if args.list:
        list_routes()
        return

    script_dir = Path(__file__).resolve().parent
    project_root = find_project_root(script_dir, args.project_root)
    loaded_env = load_project_env(project_root)

    os.environ["GOOGLE_GENAI_USE_VERTEXAI"] = "True"

    credentials, project_id = get_credentials_and_project()
    aliases = parse_aliases(args)

    print("Loaded env file:", loaded_env)
    print("Project root:", project_root)
    print("Project:", project_id)
    print("Routes:", ", ".join(aliases))
    print("")

    for alias in aliases:
        route = ROUTES[alias]
        caller = CALLERS[route.family]

        print(f"=== {alias} ===")
        print(f"Family: {route.family}")
        print(f"Model: {route.model}")
        print(f"Location: {route.location}")

        try:
            if route.family == "gemini":
                text = caller(route, project_id, args.prompt, args.max_tokens)
            else:
                text = caller(
                    route,
                    project_id,
                    args.prompt,
                    args.max_tokens,
                    credentials,
                )

            print("OK:")
            print(text.strip())
            print("")

        except Exception as error:
            print("FAILED:")
            print(error)
            print("")

            if not args.continue_on_error:
                raise


if __name__ == "__main__":
    main()
