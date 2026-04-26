import json
import re
from pathlib import Path
from app.services.llm_service import openai_client


DATA_PATH = Path("app/data/hisn_almuslim.json")


def normalize_arabic(text: str) -> str:
    if not text:
        return ""

    text = text.strip()
    text = re.sub(r"[إأآا]", "ا", text)
    text = re.sub(r"ى", "ي", text)
    text = re.sub(r"ؤ", "و", text)
    text = re.sub(r"ئ", "ي", text)
    text = re.sub(r"ة", "ه", text)
    text = re.sub(r"[ًٌٍَُِّْـ]", "", text)
    text = re.sub(r"[^\w\s]", " ", text)
    text = re.sub(r"\s+", " ", text)

    return text.strip().lower()


def load_hisn_data():
    with open(DATA_PATH, "r", encoding="utf-8") as file:
        return json.load(file)


def score_dua(query: str, title: str, texts: list[str]) -> int:
    q = normalize_arabic(query)
    title_norm = normalize_arabic(title)
    joined_text = normalize_arabic(" ".join(texts))

    score = 0

    for word in q.split():
        if word in title_norm:
            score += 5
        if word in joined_text:
            score += 2

    if q in title_norm:
        score += 10

    if q in joined_text:
        score += 5

    return score


def choose_best_dua_with_llm(query: str, candidates: list[dict]):
    if not candidates:
        return None

    if not openai_client:
        return candidates[0]

    prompt = f"""
اختر الدعاء الأنسب من حصن المسلم حسب كلام المستخدم.

كلام المستخدم أو الحالة:
{query}

القواعد:
إذا كان المستخدم غاضب أو معصب اختر دعاء الغضب.
إذا كان المستخدم حزين اختر دعاء الهم والحزن.
إذا كان المستخدم قلق أو مكروب اختر دعاء الكرب.
إذا كان المستخدم فرحان أو ممتن اختر ذكر الشكر أو أذكار الصباح والمساء.
إذا كان المستخدم خائف اختر دعاء الخوف أو الكرب.

الأدعية المتاحة:
"""

    for i, candidate in enumerate(candidates, start=1):
        title = candidate.get("title", "")
        sample = candidate.get("text", [""])[0]
        prompt += f"\n{i}) {title}\n{sample}\n"

    prompt += """
أعد رقم الدعاء الأنسب فقط.
"""

    try:
        response = openai_client.chat.completions.create(
            model="gpt-4o-mini",
            temperature=0,
            messages=[{"role": "user", "content": prompt}],
        )

        index = int(response.choices[0].message.content.strip()) - 1

        if 0 <= index < len(candidates):
            return candidates[index]

    except Exception:
        pass

    return candidates[0]


def search_dua(dua_query: str):
    data = load_hisn_data()

    candidates = []

    for title, item in data.items():
        candidates.append({
            "title": title,
            "text": item.get("text", []),
            "footnote": item.get("footnote", []),
            "score": score_dua(dua_query, title, item.get("text", [])),
        })

    if not candidates:
        return None

    top_candidates = sorted(
        candidates,
        key=lambda x: x["score"],
        reverse=True
    )[:20]

    best = choose_best_dua_with_llm(dua_query, top_candidates)

    return best