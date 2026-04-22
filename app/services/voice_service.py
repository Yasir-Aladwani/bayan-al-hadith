import requests
from fastapi import HTTPException
from app.config import HF_TOKEN


def transcribe_audio_with_hf(
    file_bytes: bytes,
    content_type: str = "audio/wav"
) -> str:
    if not HF_TOKEN:
        raise HTTPException(status_code=400, detail="HF_TOKEN is missing")

    model_url = "https://router.huggingface.co/hf-inference/models/openai/whisper-large-v3"

    headers = {
        "Authorization": f"Bearer {HF_TOKEN}",
        "Content-Type": content_type,
    }

    try:
        response = requests.post(
            model_url,
            headers=headers,
            data=file_bytes,
            timeout=120
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"HF request failed: {e}")

    if response.status_code != 200:
        raise HTTPException(
            status_code=500,
            detail=f"HF transcription failed: {response.text}"
        )

    try:
        result = response.json()
    except Exception:
        raise HTTPException(
            status_code=500,
            detail=f"HF returned non-JSON: {response.text}"
        )

    if isinstance(result, dict):
        text = result.get("text", "") or result.get("generated_text", "")
        if text:
            return text.strip()

    raise HTTPException(status_code=500, detail=f"Unexpected HF response: {result}")