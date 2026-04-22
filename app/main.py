from fastapi import FastAPI
from app.routes.ask import router as ask_router
from app.routes.memory import router as memory_router
from app.routes.voice import router as voice_router

app = FastAPI(title="Hadith Backend")

app.include_router(ask_router)
app.include_router(memory_router)
app.include_router(voice_router)


@app.get("/")
def root():
    return {
        "message": "Hadith backend is running"
    }