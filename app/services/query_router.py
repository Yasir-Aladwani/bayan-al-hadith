from app.services.retrieval_service import (
    build_search_queries,
    retrieve_hadiths_for_question,
)
from app.services.memory_service import (
    search_closest_hadith,
    search_best_verified_hadith,
)
from app.services.llm_service import (
    llm_answer,
    verify_hadith_answer,
    support_answer,
    fiqh_answer,
)
from app.services.support_service import (
    detect_support_mode,
    detect_emotion,
    get_spiritual_support,
)


def detect_verify_mode(question: str) -> bool:
    q = question.strip()

    verify_signals = [
        "هل هذا الحديث صحيح",
        "هل الحديث صحيح",
        "هل حديث",
        "تحقق من الحديث",
        "تحقق من هذا الحديث",
        "ما درجة هذا الحديث",
        "ما صحة هذا الحديث",
        "حديث منتشر",
        "سمعت حديث",
        "هل هذا حديث",
        "هل هذا الحديث ضعيف",
        "هل هذا الحديث موضوع",
        "صحيح ولا لا",
        "صحيح أم لا",
        "هل هو صحيح",
    ]

    return any(signal in q for signal in verify_signals)


def detect_memory_mode(question: str) -> bool:
    q = question.strip()

    memory_signals = [
        "اكمل الحديث",
        "أكمل الحديث",
        "وش الحديث",
        "ما هو الحديث",
        "حديث يقول",
        "حديث فيه",
        "ناسي الحديث",
        "مو متذكر الحديث",
        "اتذكر حديث",
        "أتذكر حديث",
    ]

    return any(signal in q for signal in memory_signals)


def detect_fiqh_mode(question: str) -> bool:
    q = question.strip()

    fiqh_signals = [
        "ما حكم",
        "حكم",
        "هل يجوز",
        "يجوز",
        "لا يجوز",
        "هل يصح",
        "هل يجب",
        "هل تبطل",
        "يبطل",
        "في الصلاة",
        "في السجود",
        "في الركوع",
        "في الوضوء",
        "في الصيام",
        "في الحج",
    ]

    return any(signal in q for signal in fiqh_signals)


def route_question(question: str):
    question = question.strip()

    # 1) تحقق من صحة حديث
    if detect_verify_mode(question):
        try:
            best_match = search_best_verified_hadith(question)
            answer = verify_hadith_answer(question, best_match)

            return {
                "mode": "verify_hadith",
                "search_queries": [],
                "answer": answer,
                "hadiths": [best_match],
                "support": None,
            }
        except Exception:
            pass

    # 2) حديث من الذاكرة
    if detect_memory_mode(question):
        try:
            best_match = search_closest_hadith(question)

            return {
                "mode": "memory",
                "search_queries": [],
                "answer": "تم العثور على أقرب حديث مطابق لما أدخله المستخدم.",
                "hadiths": [best_match],
                "support": None,
            }
        except Exception:
            pass

    # 3) سؤال فقهي / حكم
    if detect_fiqh_mode(question):
        search_queries = build_search_queries(question)
        hadiths = retrieve_hadiths_for_question(question)

        if not hadiths:
            return {
                "mode": "fiqh",
                "search_queries": search_queries,
                "answer": "لم يتم العثور على أحاديث مناسبة لهذا السؤال.",
                "hadiths": [],
                "support": None,
            }

        top_hadiths = hadiths[:3]
        answer = fiqh_answer(question, top_hadiths)

        return {
            "mode": "fiqh",
            "search_queries": search_queries,
            "answer": answer,
            "hadiths": top_hadiths,
            "support": None,
        }

    # 4) فضفضة / دعم روحاني
    if detect_support_mode(question):
        emotion = detect_emotion(question)
        support = get_spiritual_support(emotion)

        hadiths = retrieve_hadiths_for_question(support["hadith_topic"])
        top_hadiths = hadiths[:2]

        answer = support_answer(question, support, top_hadiths)

        return {
            "mode": "support",
            "search_queries": [support["hadith_topic"]],
            "answer": answer,
            "hadiths": top_hadiths,
            "support": {
                "emotion": support["emotion"],
                "dua": support["dua"],
                "verse": support["verse"],
                "verse_ref": support["verse_ref"],
            },
        }

    # 5) سؤال عام
    search_queries = build_search_queries(question)
    hadiths = retrieve_hadiths_for_question(question)

    if not hadiths:
        return {
            "mode": "general",
            "search_queries": search_queries,
            "answer": "لم يتم العثور على أحاديث مناسبة لهذا السؤال.",
            "hadiths": [],
            "support": None,
        }

    top_hadiths = hadiths[:5]
    answer = llm_answer(question, top_hadiths)

    return {
        "mode": "general",
        "search_queries": search_queries,
        "answer": answer,
        "hadiths": top_hadiths,
        "support": None,
    }