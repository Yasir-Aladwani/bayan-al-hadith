import json
from pathlib import Path
from app.services.llm_service import openai_client

DATA_PATH = Path("app/data/spiritual_support.json")


def load_support_data():
    with open(DATA_PATH, "r", encoding="utf-8") as file:
        return json.load(file)


def choose_support_case(user_text: str):
    cases = load_support_data()

    if not openai_client:
        return cases[0]

    cases_text = ""
    for i, item in enumerate(cases, start=1):
        cases_text += f"""
{i}) الحالة: {item["emotion"]}
الكلمات الدالة: {", ".join(item.get("tags", []))}
"""

    prompt = f"""
اقرأ كلام المستخدم وحدد أقرب حالة مناسبة من القائمة.

كلام المستخدم:
{user_text}

القائمة:
{cases_text}

القواعد:
أعد رقم الحالة فقط.
لا تشرح.
لا تكتب أي شيء غير الرقم.
اختر حسب المعنى، وليس تطابق الكلمات فقط.
"""

    try:
        response = openai_client.chat.completions.create(
            model="gpt-4o-mini",
            temperature=0,
            messages=[{"role": "user", "content": prompt}],
        )

        index = int(response.choices[0].message.content.strip()) - 1

        if 0 <= index < len(cases):
            return cases[index]

    except Exception:
        pass

    return cases[0]