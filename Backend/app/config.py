import os

DORAR_API_URL = "https://dorar.net/dorar_api.json"
HEADERS = {"User-Agent": "Mozilla/5.0"}

ACCEPTED_DEGREES = [
    "صحيح",
    "حسن",
    "ثابت",
    "صحيح لغيره",
    "حسن لغيره",
]

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "").strip()
HF_TOKEN = os.getenv("HF_TOKEN", "").strip()