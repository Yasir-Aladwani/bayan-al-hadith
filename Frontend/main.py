"""
HudAI - Arabic Hadith-based Question Answering System
FastAPI Backend - Main Entry Point
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from pipeline import HadithPipeline
import uvicorn
import logging

# ─────────────────────────────────────────────
# Logging
# ─────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("HudAI")

# ─────────────────────────────────────────────
# App Setup
# ─────────────────────────────────────────────
app = FastAPI(
    title="HudAI API",
    description="Arabic Hadith-based Question Answering System",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

pipeline = HadithPipeline()

# ─────────────────────────────────────────────
# Models
# ─────────────────────────────────────────────
class QuestionRequest(BaseModel):
    question: str

class HadithSource(BaseModel):
    text: str
    narrator: str
    source: str
    grade: str

class AnswerResponse(BaseModel):
    answer: str
    sources: list[HadithSource]
    keyword_used: str
    total_retrieved: int
    total_after_filter: int

# ─────────────────────────────────────────────
# Routes
# ─────────────────────────────────────────────
@app.get("/")
def root():
    return {"status": "ok", "service": "HudAI", "version": "1.0.0"}

@app.get("/health")
def health():
    return {"status": "healthy"}

@app.post("/ask", response_model=AnswerResponse)
async def ask(request: QuestionRequest):
    """
    Main endpoint: takes an Arabic question, retrieves Hadith, returns answer + sources.
    """
    question = request.question.strip()
    if not question:
        raise HTTPException(status_code=400, detail="السؤال لا يمكن أن يكون فارغًا")

    logger.info(f"Received question: {question}")

    try:
        result = await pipeline.run(question)
        return result
    except Exception as e:
        logger.error(f"Pipeline error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"خطأ في المعالجة: {str(e)}")

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
