from openai import OpenAI
from app.config import OPENAI_API_KEY

openai_client = OpenAI(api_key=OPENAI_API_KEY) if OPENAI_API_KEY else None


def build_context(hadiths):
    chunks = []
    for i, h in enumerate(hadiths, start=1):
        chunks.append(
            f"""[{i}]
نص الحديث: {h.get("text", "")}
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

    return (
        f"السؤال: {question}\n\n"
        f"الجواب المختصر:\n"
        f"تم العثور على أحاديث مرتبطة بالسؤال. راجعي الأحاديث المعتمدة أدناه."
    )


def llm_answer(question: str, hadiths):
    if not hadiths:
        return "لم أجد في النتائج المسترجعة أحاديث مقبولة تجيب مباشرة على هذا السؤال."

    if not openai_client:
        return template_answer(question, hadiths)

    context = build_context(hadiths[:5])

    prompt = f"""
أنت مساعد يجيب فقط من الأحاديث المعطاة.

تعليمات صارمة:
- لا تضف أي معلومة من عندك.
- إذا لم تجد جواباً واضحاً قل: لم أجد في الأحاديث المسترجعة جواباً مباشراً.
- اكتب أولاً جواباً مختصراً بصياغة واضحة.
- بعد ذلك اكتب عنوان: الأحاديث المعتمدة

السؤال:
{question}

الأحاديث:
{context}
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