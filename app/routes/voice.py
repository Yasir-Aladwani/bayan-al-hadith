from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse

from app.services.voice_service import transcribe_audio_with_hf
from app.services.retrieval_service import retrieve_hadiths_for_question
from app.services.llm_service import llm_answer

router = APIRouter()


def serialize_hadiths(hadiths, limit=5):
    return [
        {
            "text": h.get("text", ""),
            "narrator": h.get("narrator", ""),
            "scholar": h.get("scholar", ""),
            "source": h.get("source", ""),
            "page": h.get("page", ""),
            "grade": h.get("grade", ""),
        }
        for h in hadiths[:limit]
    ]


@router.post("/ask-voice")
async def ask_voice(audio: UploadFile = File(...)):
    file_bytes = await audio.read()
    if not file_bytes:
        raise HTTPException(status_code=400, detail="Empty audio file")

    transcript = transcribe_audio_with_hf(
        file_bytes=file_bytes,
        content_type=audio.content_type or "audio/wav"
    )

    hadiths = retrieve_hadiths_for_question(transcript)
    answer = llm_answer(transcript, hadiths)

    return JSONResponse({
        "transcript": transcript,
        "answer": answer,
        "hadiths": serialize_hadiths(hadiths),
    })