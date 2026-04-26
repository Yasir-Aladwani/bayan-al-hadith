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


def detect_mode(question: str) -> str:
    q = question.strip()

    sharh_words = ["اشرح", "شرح", "فسر", "فسري", "وضح", "وضحي", "معنى الحديث"]
    hadith_words = ["اعطني حديث", "أعطني حديث", "هات حديث", "حديث عن", "ما الحديث"]

    if any(word in q for word in sharh_words):
        return "sharh"

    if any(word in q for word in hadith_words):
        return "direct_hadith"

    return "general"


def build_search_queries(question: str) -> list[str]:
    q = question.strip()
    queries = []

    if any(x in q for x in ["أول وقت", "اول وقت", "في وقتها", "لوقتها", "مواقيتها"]):
        queries.extend([
            "الصلاة لوقتها",
            "الصلاة في وقتها",
            "مواقيت الصلاة",
            "فضل الصلاة لوقتها",
        ])

    if any(x in q for x in ["الصلاة", "صلاة"]):
        queries.append("الصلاة")

    if any(x in q for x in ["الوضوء", "وضوء"]):
        queries.extend(["الوضوء", "صفة الوضوء"])

    if any(x in q for x in ["الزكاة", "زكاة"]):
        queries.append("الزكاة")

    if any(x in q for x in ["الصيام", "صيام"]):
        queries.append("الصيام")

    if any(x in q for x in ["الحج", "حج"]):
        queries.append("الحج")

    if any(x in q for x in ["اذكار", "أذكار", "ذكر"]):
        queries.extend(["الأذكار", "أذكار النوم", "أذكار الصباح"])

    if not queries:
        queries.append(q)

    unique = []
    seen = set()
    for item in queries:
        if item not in seen:
            seen.add(item)
            unique.append(item)

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
    score = 0

    for w in q_words:
        if w in text:
            score += 2

    if normalize_arabic(query) in text:
        score += 5

    return score


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


def rank_results(results, question: str):
    return sorted(
        results,
        key=lambda x: (
            relevance_score(question, x.get("text", "")),
            grade_score(x.get("grade", "")),
            -len(x.get("text", ""))
        ),
        reverse=True
    )


def retrieve_hadiths_for_question(question: str):
    queries = build_search_queries(question)

    all_results = []
    for query in queries:
        all_results.extend(fetch_from_dorar(query))

    all_results = deduplicate_results(all_results)
    all_results = filter_by_degree(all_results)
    all_results = rank_results(all_results, question)

    return all_results


def retrieve_hadiths_by_queries(queries):
    if not queries:
        return []

    all_results = []

    for query in queries:
        all_results.extend(fetch_from_dorar(query))

    all_results = deduplicate_results(all_results)
    all_results = filter_by_degree(all_results)

    joined_query = " ".join(queries)
    all_results = rank_results(all_results, joined_query)

    return all_results

def filter_wrong_meaning(hadiths, question):
    filtered = []

    q = question.replace("أ", "ا").replace("إ", "ا").replace("آ", "ا")

    for h in hadiths:
        text = h.get("text", "")

        if "سحر" in q:
            wrong_words = [
                "السَّحَر",
                "سحور",
                "تسحروا",
                "تسحَّروا",
                "صيام",
                "صائم",
                "أكل",
                "شرب",
                "الفجر",
            ]

            if any(word in text for word in wrong_words):
                continue

        filtered.append(h)

    return filtered