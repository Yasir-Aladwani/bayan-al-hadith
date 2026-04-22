import re
from app.config import ACCEPTED_DEGREES
from app.services.dorar_client import fetch_from_dorar


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


def keyword_from_question(question: str):
    q = question.strip()
    keywords = []

    if any(x in q for x in ["أول وقت", "اول وقت", "لوقتها", "في وقتها", "مواقيتها"]):
        keywords.extend(["الصلاة لوقتها", "الصلاة في وقتها", "مواقيت الصلاة"])

    if any(x in q for x in ["الصلاة", "صلاة"]):
        keywords.append("الصلاة")
    if any(x in q for x in ["الوضوء", "وضوء"]):
        keywords.append("الوضوء")
    if any(x in q for x in ["الزكاة", "زكاة"]):
        keywords.append("الزكاة")
    if any(x in q for x in ["الصيام", "صيام"]):
        keywords.append("الصيام")
    if any(x in q for x in ["الحج", "حج"]):
        keywords.append("الحج")
    if any(x in q for x in ["أذكار", "اذكار", "ذكر"]):
        keywords.append("الأذكار")

    if not keywords:
        keywords.append(q)

    unique = []
    seen = set()
    for k in keywords:
        if k not in seen:
            seen.add(k)
            unique.append(k)

    return unique


def deduplicate_results(results):
    unique = []
    seen = set()

    for item in results:
        key = (
            item.get("text", "").strip(),
            item.get("narrator", "").strip(),
            item.get("source", "").strip(),
        )
        if key not in seen:
            seen.add(key)
            unique.append(item)

    return unique


def filter_by_degree(results):
    filtered = []
    for item in results:
        grade = item.get("grade", "")
        if any(acc in grade for acc in ACCEPTED_DEGREES):
            filtered.append(item)
    return filtered


def relevance_score(query: str, hadith_text: str) -> int:
    q_words = normalize_arabic(query).split()
    text = normalize_arabic(hadith_text)
    return sum(1 for w in q_words if w in text)


def grade_score(grade: str) -> int:
    if "صحيح" in grade:
        return 4
    if "ثابت" in grade:
        return 3
    if "حسن" in grade:
        return 2
    if "ضعيف" in grade or "موضوع" in grade:
        return 0
    return 1


def rank_results(results, query: str):
    return sorted(
        results,
        key=lambda x: (
            relevance_score(query, x.get("text", "")),
            grade_score(x.get("grade", "")),
            len(x.get("text", "")),
        ),
        reverse=True
    )


def retrieve_hadiths_for_question(question: str):
    keywords = keyword_from_question(question)

    all_results = []
    for kw in keywords:
        all_results.extend(fetch_from_dorar(kw))

    all_results = deduplicate_results(all_results)
    all_results = filter_by_degree(all_results)
    all_results = rank_results(all_results, question)

    return all_results