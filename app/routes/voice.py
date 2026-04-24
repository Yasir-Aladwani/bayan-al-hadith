from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse

from app.services.voice_service import transcribe_audio_with_hf
from app.services.query_router import route_question

router = APIRouter()


def serialize_hadiths(hadiths, limit=5):
    output = []

    for h in hadiths[:limit]:
        output.append({
            "text": h.get("text", h.get("نص_الحديث", "")),
            "narrator": h.get("narrator", h.get("الراوي", "")),
            "scholar": h.get("scholar", h.get("المحدث", "")),
            "source": h.get("source", h.get("المصدر", "")),
            "page": h.get("page", h.get("الصفحة", "")),
            "grade": h.get("grade", h.get("الدرجة", "")),
            "match_score": h.get("match_score", None),
        })

    return output


@router.post("/ask-voice")
async def ask_voice(audio: UploadFile = File(...)):
    file_bytes = await audio.read()

    if not file_bytes:
        raise HTTPException(status_code=400, detail="Empty audio file")

    transcript = transcribe_audio_with_hf(
        file_bytes=file_bytes,
        content_type=audio.content_type or "audio/wav",
    )

    result = route_question(transcript)

    return JSONResponse({
        "transcript": transcript,
        "mode": result["mode"],
        "search_queries": result["search_queries"],
        "answer": result["answer"],
        "support": result.get("support"),
        "hadiths": serialize_hadiths(result["hadiths"]),
    })