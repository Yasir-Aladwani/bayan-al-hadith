from difflib import SequenceMatcher
from fastapi import HTTPException
from app.services.dorar_client import fetch_from_dorar
from app.services.retrieval_service import (
    deduplicate_results,
    build_search_queries,
    normalize_arabic,
    relevance_score,
)


def grade_priority(grade: str) -> int:
    grade = grade or ""

    if "صحيح" in grade:
        return 5
    if "إسناده صحيح" in grade:
        return 5
    if "حسن" in grade:
        return 4
    if "ثابت" in grade:
        return 4
    if "صحيح لغيره" in grade:
        return 3
    if "حسن لغيره" in grade:
        return 3
    if "مرسل" in grade:
        return 1
    if "ضعيف" in grade or "موضوع" in grade:
        return 0

    return 2


def search_closest_hadith(user_memory_text: str):
    candidates_keywords = build_search_queries(user_memory_text)
    if user_memory_text not in candidates_keywords:
        candidates_keywords.append(user_memory_text)

    all_results = []
    for kw in candidates_keywords:
        all_results.extend(fetch_from_dorar(kw))

    all_results = deduplicate_results(all_results)

    if not all_results:
        raise HTTPException(status_code=404, detail="No matching hadiths found")

    target = normalize_arabic(user_memory_text)

    best_item = None
    best_score = -1.0

    for item in all_results:
        text = normalize_arabic(item.get("text", ""))
        score = SequenceMatcher(None, target, text).ratio()
        score += relevance_score(user_memory_text, item.get("text", "")) * 0.05

        if score > best_score:
            best_score = score
            best_item = item

    result = dict(best_item)
    result["match_score"] = round(best_score, 4)
    return result


def search_best_verified_hadith(user_input: str):
    candidates_keywords = build_search_queries(user_input)
    if user_input not in candidates_keywords:
        candidates_keywords.append(user_input)

    all_results = []
    for kw in candidates_keywords:
        all_results.extend(fetch_from_dorar(kw))

    all_results = deduplicate_results(all_results)

    if not all_results:
        raise HTTPException(status_code=404, detail="No matching hadiths found")

    target = normalize_arabic(user_input)

    scored_results = []

    for item in all_results:
        text = normalize_arabic(item.get("text", ""))
        similarity = SequenceMatcher(None, target, text).ratio()
        rel = relevance_score(user_input, item.get("text", ""))
        grade_score = grade_priority(item.get("grade", ""))

        final_score = (similarity * 0.65) + (rel * 0.03) + (grade_score * 0.08)

        enriched = dict(item)
        enriched["match_score"] = round(similarity, 4)
        enriched["final_score"] = round(final_score, 4)
        scored_results.append(enriched)

    scored_results.sort(
        key=lambda x: (x["final_score"], grade_priority(x.get("grade", ""))),
        reverse=True
    )

    return scored_results[0]