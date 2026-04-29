from google import genai
from google.genai.types import HttpOptions

print("Подключаемся к Google Cloud...")

# Старый контрольный тест: авторизация берется из Google Cloud CLI ADC.
# Этот файл специально не читает .env.local и не использует service account JSON явно.
client = genai.Client(
    vertexai=True,
    project="project-f2d88164-6230-481c-930",
    location="global",
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
