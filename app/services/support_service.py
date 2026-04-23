import json
from pathlib import Path


DATA_PATH = Path("app/data/spiritual_support.json")


def load_support_data():
    with open(DATA_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


def detect_support_mode(question: str) -> bool:
    q = question.strip()

    support_signals = [
        "زعلان",
        "حزين",
        "مهموم",
        "مضايق",
        "متضايق",
        "تعبان",
        "خايف",
        "قلقان",
        "قلق",
        "ضايق",
        "ضيقة",
        "ضيق",
        "مكتئب",
        "أبي دعاء",
        "ابغى دعاء",
        "أحتاج دعاء",
        "دعاء",
        "فضفضة",
        "طفشان",
        "متوتر",
        "توتر",
        "مشكلة",
        "مشكلتي",
        "أحس",
        "اشعر",
        "أشعر",
    ]

    return any(word in q for word in support_signals)


def detect_emotion(text: str) -> str:
    q = text.strip()

    if any(w in q for w in ["حزين", "زعلان", "مكسور", "منهار"]):
        return "حزن"

    if any(w in q for w in ["خايف", "خوف", "مرعوب"]):
        return "خوف"

    if any(w in q for w in ["قلق", "قلقان", "متوتر", "توتر"]):
        return "قلق"

    if any(w in q for w in ["ضيق", "مضايق", "متضايق", "ضيقة"]):
        return "ضيق"

    if any(w in q for w in ["ذنبي", "سويت ذنب", "معصية", "تبت", "استغفر"]):
        return "ذنب"

    if any(w in q for w in ["فقد", "مات", "توفي", "خسرت"]):
        return "فقد"

    if any(w in q for w in ["تعبان", "مرهق", "متعب", "تعب"]):
        return "تعب"

    if any(w in q for w in ["اختبار", "دراسة", "امتحان", "مذاكرة"]):
        return "دراسة"

    if any(w in q for w in ["فلوس", "رزق", "راتب", "ديون"]):
        return "رزق"

    if any(w in q for w in ["مريض", "مرض", "صداع", "وجع", "ألم"]):
        return "مرض"

    return "حزن"


def get_spiritual_support(emotion: str):
    data = load_support_data()

    for item in data:
        if item["emotion"] == emotion:
            return item

    return data[0]