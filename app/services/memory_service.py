from difflib import SequenceMatcher
from fastapi import HTTPException
from app.services.dorar_client import fetch_from_dorar
from app.services.retrieval_service import deduplicate_results, keyword_from_question, normalize_arabic, relevance_score


def search_closest_hadith(user_memory_text: str):
    candidates_keywords = keyword_from_question(user_memory_text)
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