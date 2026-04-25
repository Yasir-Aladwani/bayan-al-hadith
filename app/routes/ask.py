from fastapi import APIRouter
from fastapi.responses import JSONResponse
from app.schemas import AskRequest
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


@router.post("/ask")
def ask(payload: AskRequest):
    question = payload.question.strip()

    if not question:
        return JSONResponse(
            status_code=400,
            content={"detail": "Question is required"},
        )

    result = route_question(question)

    return JSONResponse({
        "question": question,
        "mode": result["mode"],
        "search_queries": result["search_queries"],
        "answer": result["answer"],
        "support": result.get("support"),
        "verses": result.get("verses", []),
        "hadiths": serialize_hadiths(result["hadiths"]),
    })