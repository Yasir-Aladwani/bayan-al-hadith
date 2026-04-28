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

EMAILJS_SERVICE_ID           = "service_jkytisf"
EMAILJS_TEMPLATE_ID          = "template_k7xkcw1"
EMAILJS_TEMPLATE_ID_PASSWORD = "template_n4x7r8o"
EMAILJS_PUBLIC_KEY           = "_PCJUgH4omH5FwzUT"
EMAILJS_PRIVATE_KEY          = "gLvYG8uXEPGxjuPmThEeI"