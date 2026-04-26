from fastapi import APIRouter
from fastapi.responses import JSONResponse
from app.schemas import MemoryRequest
from app.services.memory_service import search_closest_hadith

router = APIRouter()

@router.post("/hadith-memory")
def hadith_memory(payload: MemoryRequest):
    remembered_text = payload.remembered_text.strip()
    best_match = search_closest_hadith(remembered_text)

    return JSONResponse({
        "remembered_text": remembered_text,
        "closest_match": best_match
    })