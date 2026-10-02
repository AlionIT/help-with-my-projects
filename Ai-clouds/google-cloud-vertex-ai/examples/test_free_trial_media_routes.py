import argparse
import os
import time
from dataclasses import dataclass
from pathlib import Path


DEFAULT_IMAGE_PROMPT = "A tiny blue paper boat on a white background, clean minimal style."
DEFAULT_VIDEO_PROMPT = "A tiny blue paper boat floating on calm water, minimal style."


@dataclass(frozen=True)
class MediaRoute:
    alias: str
    kind: str
    model: str
    location: str
    description: str


ROUTES = {
    "gemini-image": MediaRoute(
        alias="gemini-image",
        kind="gemini-image",
        model="gemini-2.5-flash-image",
        location="global",
        description="Google native image generation через Gemini",
    ),
    "imagen-fast": MediaRoute(
        alias="imagen-fast",
        kind="imagen",
        model="imagen-4.0-fast-generate-001",
        location="us-central1",
        description="Google native Imagen, быстрый image generation",
    ),
    "imagen-standard": MediaRoute(
        alias="imagen-standard",
        kind="imagen",
        model="imagen-4.0-generate-001",
        location="us-central1",
        description="Google native Imagen, стандартный image generation",
    ),
    "veo-fast": MediaRoute(
        alias="veo-fast",
        kind="veo",
        model="veo-3.1-fast-generate-001",
        location="us-central1",
        description="Google native Veo, быстрый video generation",
    ),
}


PROFILES = {
    "images": ["gemini-image", "imagen-fast"],
    "video": ["veo-fast"],
    "all": ["gemini-image", "imagen-fast", "veo-fast"],
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


def parse_aliases(args) -> list[str]:
    aliases = []

    if args.profile:
        aliases.extend(PROFILES[args.profile])

    if args.only:
        aliases.extend([part.strip() for part in args.only.split(",") if part.strip()])

    if not aliases:
        aliases = PROFILES["images"]

    unknown = [alias for alias in aliases if alias not in ROUTES]

    if unknown:
        raise RuntimeError(f"Unknown media route alias: {', '.join(unknown)}")

    return aliases


def ensure_cost_flags(args, aliases: list[str]) -> None:
    if not args.allow_cost:
        raise RuntimeError(
            "Media generation spends Vertex AI credits. "
            "Pass --allow-cost to run image/video checks."
        )

    video_aliases = [alias for alias in aliases if ROUTES[alias].kind == "veo"]

    if video_aliases and not args.allow_video_cost:
        raise RuntimeError(
            "Veo video generation can spend several dollars of trial credits per run. "
            "Pass --allow-video-cost to run video checks."
        )


def output_dir_for(project_root: Path, output_dir_arg: str | None) -> Path:
    if output_dir_arg:
        output_dir = Path(output_dir_arg).resolve()
    else:
        output_dir = project_root / "temp" / "vertex-ai-smoke-output"

    output_dir.mkdir(parents=True, exist_ok=True)
    return output_dir


def write_bytes(path: Path, data: bytes) -> Path:
    path.write_bytes(data)
    return path


def call_gemini_image(route: MediaRoute, project_id: str, prompt: str, output_dir: Path) -> list[Path]:
    from google import genai
    from google.genai.types import GenerateContentConfig, HttpOptions, Modality

    client = genai.Client(
        vertexai=True,
        project=project_id,
        location=route.location,
        http_options=HttpOptions(api_version="v1"),
    )

    response = client.models.generate_content(
        model=route.model,
        contents=prompt,
        config=GenerateContentConfig(
            response_modalities=[Modality.TEXT, Modality.IMAGE],
            candidate_count=1,
        ),
    )

    saved = []
    index = 0

    for candidate in response.candidates or []:
        content = candidate.content

        if not content:
            continue

        for part in content.parts or []:
            inline_data = getattr(part, "inline_data", None)

            if inline_data and inline_data.data:
                index += 1
                saved.append(
                    write_bytes(
                        output_dir / f"{route.alias}-{index}.png",
                        inline_data.data,
                    )
                )

    return saved


def call_imagen(route: MediaRoute, project_id: str, prompt: str, output_dir: Path) -> list[Path]:
    from google import genai
    from google.genai.types import GenerateImagesConfig, HttpOptions

    client = genai.Client(
        vertexai=True,
        project=project_id,
        location=route.location,
        http_options=HttpOptions(api_version="v1"),
    )

    response = client.models.generate_images(
        model=route.model,
        prompt=prompt,
        config=GenerateImagesConfig(
            number_of_images=1,
            aspect_ratio="1:1",
            output_mime_type="image/png",
            enhance_prompt=False,
        ),
    )

    saved = []

    for index, generated in enumerate(response.generated_images or [], start=1):
        image = getattr(generated, "image", None)
        data = None

        if image:
            data = getattr(image, "image_bytes", None) or getattr(image, "data", None)

        if data:
            saved.append(write_bytes(output_dir / f"{route.alias}-{index}.png", data))

    return saved


def call_veo(
    route: MediaRoute,
    project_id: str,
    prompt: str,
    output_dir: Path,
    output_gcs_uri: str | None,
    timeout_seconds: int,
) -> list[str]:
    from google import genai
    from google.genai.types import GenerateVideosConfig, HttpOptions

    client = genai.Client(
        vertexai=True,
        project=project_id,
        location=route.location,
        http_options=HttpOptions(api_version="v1"),
    )

    operation = client.models.generate_videos(
        model=route.model,
        prompt=prompt,
        config=GenerateVideosConfig(
            number_of_videos=1,
            duration_seconds=4,
            aspect_ratio="16:9",
            output_gcs_uri=output_gcs_uri,
            generate_audio=False,
        ),
    )

    started = time.time()

    while not operation.done:
        if time.time() - started > timeout_seconds:
            raise TimeoutError(f"Veo operation did not finish in {timeout_seconds} seconds")

        time.sleep(15)
        operation = client.operations.get(operation)
        print("Polling:", operation.name, "done=", operation.done)

    if not operation.response:
        return [f"Operation finished without response: {operation}"]

    result = operation.result
    outputs = []

    for index, generated in enumerate(result.generated_videos or [], start=1):
        video = getattr(generated, "video", None)

        if not video:
            continue

        uri = getattr(video, "uri", None)
        data = getattr(video, "video_bytes", None) or getattr(video, "data", None)

        if uri:
            outputs.append(uri)
        elif data:
            path = output_dir / f"{route.alias}-{index}.mp4"
            write_bytes(path, data)
            outputs.append(str(path))

    return outputs


def list_routes() -> None:
    print("Profiles:")
    for profile, aliases in PROFILES.items():
        print(f"- {profile}: {', '.join(aliases)}")

    print("\nRoutes:")
    for alias, route in ROUTES.items():
        print(
            f"- {alias}: kind={route.kind}, model={route.model}, "
            f"location={route.location} — {route.description}"
        )


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Smoke-test Google-native media models that can spend Free Trial credits."
    )
    parser.add_argument("--project-root", help="Prepared app root with .env.local")
    parser.add_argument("--profile", choices=sorted(PROFILES))
    parser.add_argument("--only", help="Comma-separated media route aliases")
    parser.add_argument("--image-prompt", default=DEFAULT_IMAGE_PROMPT)
    parser.add_argument("--video-prompt", default=DEFAULT_VIDEO_PROMPT)
    parser.add_argument("--output-dir")
    parser.add_argument("--output-gcs-uri")
    parser.add_argument("--timeout-seconds", type=int, default=600)
    parser.add_argument("--allow-cost", action="store_true")
    parser.add_argument("--allow-video-cost", action="store_true")
    parser.add_argument("--continue-on-error", action="store_true")
    parser.add_argument("--list", action="store_true")
    args = parser.parse_args()

    if args.list:
        list_routes()
        return

    script_dir = Path(__file__).resolve().parent
    project_root = find_project_root(script_dir, args.project_root)
    loaded_env = load_project_env(project_root)
    aliases = parse_aliases(args)

    ensure_cost_flags(args, aliases)

    os.environ["GOOGLE_GENAI_USE_VERTEXAI"] = "True"
    project_id = os.environ.get("GOOGLE_CLOUD_PROJECT")

    if not project_id:
        import google.auth

        _, project_id = google.auth.default(
            scopes=["https://www.googleapis.com/auth/cloud-platform"]
        )

    if not project_id:
        raise RuntimeError("Google Cloud project id is missing")

    output_dir = output_dir_for(project_root, args.output_dir)

    print("Loaded env file:", loaded_env)
    print("Project root:", project_root)
    print("Project:", project_id)
    print("Output dir:", output_dir)
    print("Routes:", ", ".join(aliases))
    print("")

    for alias in aliases:
        route = ROUTES[alias]

        print(f"=== {alias} ===")
        print(f"Kind: {route.kind}")
        print(f"Model: {route.model}")
        print(f"Location: {route.location}")

        try:
            if route.kind == "gemini-image":
                outputs = call_gemini_image(route, project_id, args.image_prompt, output_dir)
            elif route.kind == "imagen":
                outputs = call_imagen(route, project_id, args.image_prompt, output_dir)
            elif route.kind == "veo":
                outputs = call_veo(
                    route,
                    project_id,
                    args.video_prompt,
                    output_dir,
                    args.output_gcs_uri,
                    args.timeout_seconds,
                )
            else:
                raise RuntimeError(f"Unsupported route kind: {route.kind}")

            print("OK:")
            for output in outputs:
                print(output)

            if not outputs:
                print("No output files returned")

            print("")

        except Exception as error:
            print("FAILED:")
            print(error)
            print("")

            if not args.continue_on_error:
                raise


if __name__ == "__main__":
    main()
