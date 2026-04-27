from app.services.llm_service import (
    route_question_plan,
    general_text_answer,
    support_reflection_answer,
    fiqh_quran_sunnah_answer,
    tafsir_answer,
    verify_hadith_answer,
)
from app.services.retrieval_service import (
    retrieve_hadiths_by_queries,
    filter_wrong_meaning,
)
from app.services.quran_service import retrieve_quran_by_queries
from app.services.memory_service import search_closest_hadith, search_best_verified_hadith
from app.services.support_service import choose_support_case


def format_hadith_answer(hadith: dict):
    return (
        f"{hadith.get('text', '')}\n\n"
        f"الراوي: {hadith.get('narrator', '')}\n"
        f"المحدث: {hadith.get('scholar', '')}\n"
        f"المصدر: {hadith.get('source', '')}\n"
        f"الصفحة: {hadith.get('page', '')}\n"
        f"الدرجة: {hadith.get('grade', '')}"
    )


def route_question(question: str, history: list = []):
    question = question.strip()

    plan = route_question_plan(question, history=history)

    mode = plan.get("mode", "general")
    hadith_queries = plan.get("hadith_queries", []) or []
    quran_queries = plan.get("quran_queries", []) or []

    # ================= VERIFY HADITH =================
    if mode == "verify_hadith":
        best_match = search_best_verified_hadith(question)
        answer = verify_hadith_answer(question, best_match)

        return {
            "mode": "verify_hadith",
            "search_queries": {
                "hadith": hadith_queries,
                "quran": [],
            },
            "answer": answer,
            "support": None,
            "verses": [],
            "hadiths": [best_match] if best_match else [],
        }

    # ================= MEMORY / HADITH SEARCH =================
    if mode == "memory":
        hadiths = retrieve_hadiths_by_queries(hadith_queries)

        if not hadiths:
            best_match = search_closest_hadith(question)
            hadiths = [best_match] if best_match else []

        hadiths = filter_wrong_meaning(hadiths, question)

        if not hadiths:
            return {
                "mode": "memory",
                "search_queries": {
                    "hadith": hadith_queries,
                    "quran": [],
                },
                "answer": "لم يتم العثور على حديث مطابق بشكل موثوق.",
                "support": None,
                "verses": [],
                "hadiths": [],
            }

        best_match = hadiths[0]
        answer = format_hadith_answer(best_match)

        return {
            "mode": "memory",
            "search_queries": {
                "hadith": hadith_queries,
                "quran": [],
            },
            "answer": answer,
            "support": None,
            "verses": [],
            "hadiths": hadiths[:5],
        }

    # ================= SUPPORT =================
    if mode == "support":
        support_case = choose_support_case(question)

        answer = support_reflection_answer(
            user_input=question,
            support_case=support_case,
        )

        return {
            "mode": "support",
            "search_queries": {
                "support_case": support_case["emotion"],
                "hadith": [],
                "quran": [],
            },
            "answer": answer,
            "support": support_case,
            "verses": [],
            "hadiths": [],
        }

    # ================= TAFSIR =================
    if mode == "tafsir":
        verses, used_quran_queries = retrieve_quran_by_queries(quran_queries)
        answer = tafsir_answer(question, verses[:5], history=history)

        return {
            "mode": "tafsir",
            "search_queries": {
                "hadith": [],
                "quran": used_quran_queries,
            },
            "answer": answer,
            "support": None,
            "verses": verses[:5],
            "hadiths": [],
        }

    # ================= FIQH =================
    if mode == "fiqh":
        verses, used_quran_queries = retrieve_quran_by_queries(quran_queries)

        hadiths = retrieve_hadiths_by_queries(hadith_queries)
        hadiths = filter_wrong_meaning(hadiths, question)

        answer = fiqh_quran_sunnah_answer(
            question=question,
            verses=verses[:5],
            hadiths=hadiths[:3],
            history=history,
        )

        return {
            "mode": "fiqh",
            "search_queries": {
                "hadith": hadith_queries,
                "quran": used_quran_queries,
            },
            "answer": answer,
            "support": None,
            "verses": verses[:5],
            "hadiths": hadiths[:3],
        }

    # ================= GENERAL =================
    return {
        "mode": "general",
        "search_queries": {
            "hadith": [],
            "quran": [],
        },
        "answer": general_text_answer(question),
        "support": None,
        "verses": [],
        "hadiths": [],
    }
