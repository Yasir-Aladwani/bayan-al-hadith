import random
import requests
from datetime import datetime, timedelta
from app.config import (
    EMAILJS_SERVICE_ID,
    EMAILJS_TEMPLATE_ID,
    EMAILJS_TEMPLATE_ID_PASSWORD,
    EMAILJS_PUBLIC_KEY,
    EMAILJS_PRIVATE_KEY,
)

# In-memory OTP store: email -> {code, expiry}
_otp_store: dict = {}


def send_otp(email: str, is_password_reset: bool = False) -> None:
    print(f"DEBUG service='{EMAILJS_SERVICE_ID}' public='{EMAILJS_PUBLIC_KEY}' private='{EMAILJS_PRIVATE_KEY[:4] if EMAILJS_PRIVATE_KEY else ''}'", flush=True)
    code = str(random.randint(100000, 999999))
    expiry = datetime.now() + timedelta(minutes=10)
    _otp_store[email] = {"code": code, "expiry": expiry}

    template_id = EMAILJS_TEMPLATE_ID_PASSWORD if is_password_reset else EMAILJS_TEMPLATE_ID

    response = requests.post(
        "https://api.emailjs.com/api/v1.0/email/send",
        headers={"Content-Type": "application/json"},
        json={
            "service_id": EMAILJS_SERVICE_ID,
            "template_id": template_id,
            "user_id": EMAILJS_PUBLIC_KEY,
            "accessToken": EMAILJS_PRIVATE_KEY,
            "template_params": {
                "email": email,
                "passcode": code,
            },
        },
    )

    if response.status_code != 200:
        print(f"EmailJS error {response.status_code}: {response.text}", flush=True)
        raise Exception(f"EmailJS error {response.status_code}: {response.text}")


def verify_otp(email: str, code: str) -> bool:
    entry = _otp_store.get(email)
    if not entry:
        return False
    if datetime.now() > entry["expiry"]:
        _otp_store.pop(email, None)
        return False
    if entry["code"] != code.strip():
        return False
    _otp_store.pop(email, None)
    return True
