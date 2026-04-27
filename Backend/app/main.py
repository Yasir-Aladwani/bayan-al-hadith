from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routes.ask import router as ask_router
from app.routes.voice import router as voice_router
from app.routes.otp import router as otp_router

app = FastAPI(title="Hadith Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(ask_router)
app.include_router(voice_router)
app.include_router(otp_router)


@app.get("/")
def root():
    return {"message": "Hadith backend is running"}