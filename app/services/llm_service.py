from openai import OpenAI
from app.config import OPENAI_API_KEY

openai_client = OpenAI(api_key=OPENAI_API_KEY) if OPENAI_API_KEY else None


def build_context(hadiths):
    chunks = []
    for i, h in enumerate(hadiths, start=1):
        chunks.append(
            f"""حديث {i}:
النص: {h.get("text", "")}
الراوي: {h.get("narrator", "")}
المحدث: {h.get("scholar", "")}
المصدر: {h.get("source", "")}
الصفحة: {h.get("page", "")}
الدرجة: {h.get("grade", "")}
"""
        )
    return "\n".join(chunks)


def template_answer(question: str, hadiths):
    if not hadiths:
        return "لم أجد في النتائج المسترجعة أحاديث مقبولة تجيب مباشرة على هذا السؤال."

    lines = [
        f"السؤال: {question}",
        "",
        "الجواب المختصر:",
        "تم العثور على أحاديث مرتبطة بالسؤال.",
        "",
        "الدليل:"
    ]

    for i, h in enumerate(hadiths[:3], start=1):
        lines.append(f"{i}- {h.get('text', '')}")
        lines.append(
            f"الراوي: {h.get('narrator', '')} | "
            f"المحدث: {h.get('scholar', '')} | "
            f"المصدر: {h.get('source', '')} | "
            f"الدرجة: {h.get('grade', '')}"
        )
        lines.append("")

    return "\n".join(lines)


def verify_template_answer(user_input: str, hadith: dict):
    if not hadith:
        return "لم أتمكن من التحقق من الحديث."

    grade = hadith.get("grade", "")
    text = hadith.get("text", "")
    narrator = hadith.get("narrator", "")
    scholar = hadith.get("scholar", "")
    source = hadith.get("source", "")
    page = hadith.get("page", "")
    match_score = hadith.get("match_score", None)

    opening = f"هذا الحديث {grade}." if grade else "تم العثور على أقرب حديث مطابق."

    note = ""
    if match_score is not None and match_score < 0.70:
        note = "\nملاحظة: تم عرض أقرب حديث مطابق، وقد تكون الصيغة المدخلة مختلفة عن النص الأصلي."

    return (
        f"{opening}\n\n"
        f"التفاصيل:\n"
        f"نص الحديث: {text}\n"
        f"الراوي: {narrator}\n"
        f"المحدث: {scholar}\n"
        f"المصدر: {source}\n"
        f"الصفحة: {page}\n"
        f"الدرجة: {grade}"
        f"{note}"
    )


def llm_answer(question: str, hadiths):
    if not hadiths:
        return "لم أجد في النتائج المسترجعة أحاديث مقبولة تجيب مباشرة على هذا السؤال."

    if not openai_client:
        return template_answer(question, hadiths)

    context = build_context(hadiths[:5])

    prompt = f"""
أنت مساعد متخصص في الأحاديث النبوية.

السؤال:
{question}

الأحاديث:
{context}

التعليمات:

1) ابدأ بجواب مختصر وواضح (سطرين كحد أقصى) مبني فقط على الأحاديث  
2) ثم اكتب: "الدليل:"  
3) اعرض الأحاديث من الأقرب إلى الأقل صلة  
4) لا تكرر نفس الحديث  
5) لا تضف أي معلومة من خارج الأحاديث  
6) إذا وُجد أكثر من حديث، اختم بجملة قصيرة توضح العلاقة بينها  
7) إذا لم تجد جواباً مباشراً، قل ذلك بوضوح  
8) استخدم لغة عربية فصيحة واضحة ومباشرة  

الإجابة:
"""

    try:
        response = openai_client.chat.completions.create(
            model="gpt-4o-mini",
            temperature=0.1,
            messages=[{"role": "user", "content": prompt}]
        )
        return response.choices[0].message.content.strip()
    except Exception:
        return template_answer(question, hadiths)


def verify_hadith_answer(user_input: str, hadith: dict):
    if not hadith:
        return "لم أتمكن من التحقق من الحديث."

    grade = hadith.get("grade", "")
    text = hadith.get("text", "")
    narrator = hadith.get("narrator", "")
    scholar = hadith.get("scholar", "")
    source = hadith.get("source", "")
    page = hadith.get("page", "")
    match_score = hadith.get("match_score", None)

    opening = f"هذا الحديث {grade}." if grade else "تم العثور على أقرب حديث مطابق."

    note = ""
    if match_score is not None and match_score < 0.70:
        note = "\n\nملاحظة: تم عرض أقرب حديث مطابق، وقد تكون الصيغة المدخلة مختلفة عن النص الأصلي."

    if not openai_client:
        return (
            f"{opening}\n\n"
            f"التفاصيل:\n"
            f"نص الحديث: {text}\n"
            f"الراوي: {narrator}\n"
            f"المحدث: {scholar}\n"
            f"المصدر: {source}\n"
            f"الصفحة: {page}\n"
            f"الدرجة: {grade}"
            f"{note}"
        )

    prompt = f"""
أنت مساعد متخصص في التحقق من صحة الأحاديث.

المدخل الذي كتبه المستخدم:
{user_input}

الحديث الأقرب المطابق:
النص: {text}
الراوي: {narrator}
المحدث: {scholar}
المصدر: {source}
الصفحة: {page}
الدرجة: {grade}
نسبة المطابقة: {match_score}

التعليمات:
- اكتب الإجابة بلغة عربية واضحة ومباشرة.
- لا تستخدم markdown.
- لا تبدأ بشرطات أو نجوم.
- لا تضف أي معلومة من خارج البيانات المعطاة.
- ابدأ بجملة قصيرة جدًا مثل:
  هذا الحديث صحيح.
  أو
  هذا الحديث حسن.
  أو
  هذا الحديث ضعيف.
- بعد ذلك اكتب كلمة: التفاصيل
- ثم اعرض الحقول كسطور عادية بهذا الشكل:
  نص الحديث: ...
  الراوي: ...
  المحدث: ...
  المصدر: ...
  الصفحة: ...
  الدرجة: ...
- إذا كانت نسبة المطابقة منخفضة، أضف في النهاية:
  ملاحظة: تم عرض أقرب حديث مطابق، وقد تكون الصيغة المدخلة مختلفة عن النص الأصلي.
"""

    try:
        response = openai_client.chat.completions.create(
            model="gpt-4o-mini",
            temperature=0.1,
            messages=[{"role": "user", "content": prompt}]
        )
        return response.choices[0].message.content.strip()
    except Exception:
        return (
            f"{opening}\n\n"
            f"التفاصيل:\n"
            f"نص الحديث: {text}\n"
            f"الراوي: {narrator}\n"
            f"المحدث: {scholar}\n"
            f"المصدر: {source}\n"
            f"الصفحة: {page}\n"
            f"الدرجة: {grade}"
            f"{note}"
        )
    
def support_answer(user_input: str, support: dict, hadiths):
    dua = support.get("dua", "")
    verse = support.get("verse", "")
    verse_ref = support.get("verse_ref", "")

    if not openai_client:
        lines = [
            "أفهم من كلامك أنك تمر بوقت صعب.",
            "حاول تأخذ الأمور خطوة خطوة، ومع الدعاء بيكون عندك راحة أكثر.",
            "",
            "دعاء مناسب:",
            dua,
            "",
            f"آية مناسبة:",
            f"{verse}",
            f"المرجع: {verse_ref}",
        ]

        if hadiths:
            h = hadiths[0]
            lines += [
                "",
                "حديث مناسب:",
                h.get("text", ""),
                f"الراوي: {h.get('narrator', '')}",
                f"المصدر: {h.get('source', '')}",
                f"الدرجة: {h.get('grade', '')}",
            ]

        return "\n".join(lines)

    context = build_context(hadiths[:1]) if hadiths else ""

    prompt = f"""
أنت مساعد دعم روحاني إسلامي.

المدخل:
{user_input}

الدعاء المناسب:
{dua}

الآية المناسبة:
{verse}
المرجع:
{verse_ref}

الأحاديث:
{context}

التعليمات:
- ابدأ بجملة قصيرة فيها تعاطف بدون مبالغة
- أضف جملة بسيطة تشجع على الهدوء مثل: خذ الأمور خطوة خطوة
- لا تستخدم أي markdown مثل ** أو *
- لا تستخدم شرطات في البداية
- اكتب النص بشكل طبيعي فقط
- بعد ذلك اكتب: دعاء مناسب
- ثم اكتب الدعاء
- ثم اكتب: آية مناسبة
- ثم اكتب الآية مع المرجع
- ثم اكتب: حديث مناسب
- ثم اعرض حديثًا واحدًا فقط إن وُجد
- لا تضف أي نصائح طبية أو تشخيص
- لا تدعو على أي شخص حتى لو طلب المستخدم
- استخدم لغة عربية بسيطة وواضحة

الإجابة:
"""

    try:
        response = openai_client.chat.completions.create(
            model="gpt-4o-mini",
            temperature=0.2,
            messages=[{"role": "user", "content": prompt}]
        )
        return response.choices[0].message.content.strip()
    except Exception:
        lines = [
            "أفهم من كلامك أنك تمر بوقت صعب.",
            "حاول تأخذ الأمور خطوة خطوة، ومع الدعاء بيكون عندك راحة أكثر.",
            "",
            "دعاء مناسب:",
            dua,
            "",
            "آية مناسبة:",
            verse,
            f"المرجع: {verse_ref}",
        ]

        if hadiths:
            h = hadiths[0]
            lines += [
                "",
                "حديث مناسب:",
                h.get("text", ""),
                f"الراوي: {h.get('narrator', '')}",
                f"المصدر: {h.get('source', '')}",
                f"الدرجة: {h.get('grade', '')}",
            ]

        return "\n".join(lines)