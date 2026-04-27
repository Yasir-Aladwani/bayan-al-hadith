from pydantic import BaseModel
from typing import List, Optional


class HistoryMessage(BaseModel):
    role: str
    content: str


class AskRequest(BaseModel):
    question: str
    history: Optional[List[HistoryMessage]] = []


class MemoryRequest(BaseModel):
    remembered_text: str


class HadithItem(BaseModel):
    text: str
    narrator: str
    scholar: str
    source: str
    page: str
    grade: str


class AskResponse(BaseModel):
    question: str
    answer: str
    hadiths: List[HadithItem]


class MemoryResponse(BaseModel):
    remembered_text: str
    closest_match: dict