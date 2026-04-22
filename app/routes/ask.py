from fastapi import APIRouter
from fastapi.responses import JSONResponse
from app.schemas import AskRequest
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

@router.post("/ask-text")
def ask_text(payload: AskRequest):
    question = payload.question.strip()
    hadiths = retrieve_hadiths_for_question(question)
    answer = llm_answer(question, hadiths)

    return JSONResponse({
        "question": question,
        "answer": answer,
        "hadiths": serialize_hadiths(hadiths),
    })