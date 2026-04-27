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

EMAILJS_SERVICE_ID          = os.getenv("EMAILJS_SERVICE_ID", "").strip()
EMAILJS_TEMPLATE_ID         = os.getenv("EMAILJS_TEMPLATE_ID", "").strip()
EMAILJS_TEMPLATE_ID_PASSWORD= os.getenv("EMAILJS_TEMPLATE_ID_PASSWORD", "").strip()
EMAILJS_PUBLIC_KEY          = os.getenv("EMAILJS_PUBLIC_KEY", "").strip()
EMAILJS_PRIVATE_KEY         = os.getenv("EMAILJS_PRIVATE_KEY", "").strip()