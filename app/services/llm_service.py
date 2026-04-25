import json
from openai import OpenAI
from app.config import OPENAI_API_KEY

openai_client = OpenAI(api_key=OPENAI_API_KEY) if OPENAI_API_KEY else None


def route_question_plan(question: str):
    if not openai_client:
        return {
            "mode": "general",
            "hadith_queries": [],
            "quran_queries": [],
            "dua_query": None,
            "emotion": None
        }

    prompt = f"""
أنت Router ذكي لتطبيق إسلامي اسمه هداي.

مهمتك:
افهم كلام المستخدم.
حدد نوع الطلب المناسب.
استخرج query مناسبة لكل مصدر متاح.

الخدمات المتاحة:
verify_hadith
memory
fiqh
tafsir
support
general

نطاق التطبيق:
هداي يجيب فقط على الأسئلة الدينية التي يمكن خدمتها من:
القرآن وتفسيره
الحديث
الأحكام الشرعية
التحقق من الحديث
المرافقة الروحانية

قاعدة التصنيف العامة:
إذا كان السؤال متعلقًا بالدين أو القرآن أو السنة أو العبادات أو الأخلاق أو الدعاء أو المعاني الإيمانية، فلا تجعله general.
اختر أقرب mode من:
tafsir أو fiqh أو verify_hadith أو memory أو support.

استخدم general فقط إذا كان السؤال خارج النطاق الديني تمامًا، مثل الأفلام أو التقنية أو الرياضة أو الأخبار أو الطبخ أو السفر أو معلومات عامة لا علاقة لها بالدين.

تعريف الخدمات:
tafsir:
أي سؤال يطلب معنى أو تفسير أو شرح أو مقارنة أو فرق أو علاقة بين آيات أو سور أو ألفاظ قرآنية.

fiqh:
أي سؤال يطلب حكمًا شرعيًا أو يتضمن ألفاظًا مثل حكم، يجوز، حرام، مكروه، واجب، سنة، بدعة، هل يصح، هل يجوز.

verify_hadith:
إذا كان السؤال عن صحة حديث أو درجته أو هل هو صحيح أو ضعيف.

memory:
إذا كان المستخدم يذكر جزءًا من حديث ويريد الوصول إلى النص الأقرب.

support:
إذا كان المستخدم يفضفض أو يعبّر عن شعور أو يطلب طمأنينة أو دعاء.
يشمل المشاعر الإيجابية والسلبية مثل الحزن، القلق، الضيق، الخوف، الفرح، النجاح، الشكر، الامتنان، الحيرة، التوبة، الغضب.

قواعد الإخراج:
أعد JSON فقط بدون شرح.
لا تكتب أي نص خارج JSON.
mode يجب أن يكون واحدًا من الخدمات المتاحة فقط.
quran_queries تكون قائمة.
hadith_queries تكون قائمة.
dua_query تكون نصًا أو null.
emotion تكون نصًا أو null.

قواعد quran_queries:
إذا كان السؤال عن آية محددة وتعرف رقمها، أعدها بصيغة 113:1.
إذا كان السؤال عن سورة كاملة، أعدها بصيغة surah:number.
إذا لم تعرف الرقم، أعد عبارة قرآنية قصيرة مناسبة للبحث.
إذا كان السؤال tafsir، لا تترك quran_queries فارغة.
إذا كان السؤال fiqh، أعد quran_queries مرتبطة بنفس موضوع الحكم.

قواعد hadith_queries:
اكتب عبارات قصيرة مناسبة للبحث في الدرر.
في fiqh يجب أن تخدم hadith_queries نفس موضوع السؤال.
لا تستخدم كلمة مجردة إذا كانت تحتمل أكثر من معنى.
استخدم عبارة سياقية واضحة.

التدقيق الدلالي:
ميّز بين الكلمات المتشابهة في الرسم والمختلفة في المعنى.
السِّحر = عمل محرم وشعوذة.
السَّحَر = وقت قبل الفجر.
السحور = طعام قبل الصيام.
إذا كان السؤال عن السحر المحرم، فلا تستخدم query قد تجلب أحاديث السحور أو وقت السحر.
إذا كان السؤال عن كلمة لها أكثر من معنى، اجعل query شارحة للسياق.

وحدة الموضوع:
quran_queries و hadith_queries يجب أن تخدم نفس موضوع السؤال.
لا تخلط بين أدلة من موضوعات مختلفة.
إذا لم تجد query حديثية واضحة لنفس المعنى، اجعل hadith_queries فارغة.
إذا لم تجد query قرآنية واضحة لنفس المعنى، اجعل quran_queries فارغة، إلا في fiqh إذا كان للموضوع أصل قرآني واضح.

قواعد support:
إذا كان mode = support، اختر emotion الأقرب من معنى كلام المستخدم.
dua_query يجب أن يشير للحالة الروحية المناسبة.
إذا كان المستخدم فرحانًا أو ممتنًا، اجعل dua_query عن الشكر أو الامتنان.
إذا كان المستخدم حزينًا أو قلقًا، اجعل dua_query عن الهم أو الكرب أو الطمأنينة.
إذا كان المستخدم غاضبًا أو معصبًا، اجعل dua_query عن الغضب.
لا تجعل support فقط للمشاعر السلبية.

أمثلة:

السؤال: حاسه بضيق فجأة
{{
  "mode": "support",
  "hadith_queries": ["تفريج الكرب"],
  "quran_queries": ["ألا بذكر الله تطمئن القلوب"],
  "dua_query": "دعاء الكرب",
  "emotion": "ضيق"
}}

السؤال: معصبة مرة
{{
  "mode": "support",
  "hadith_queries": ["الغضب"],
  "quran_queries": [],
  "dua_query": "دعاء الغضب",
  "emotion": "غضب"
}}

السؤال: أنا مره فرحانة خلصت مشروعي
{{
  "mode": "support",
  "hadith_queries": ["شكر النعمة"],
  "quran_queries": ["لئن شكرتم لأزيدنكم"],
  "dua_query": "الشكر",
  "emotion": "سعادة"
}}

السؤال: ايش تفسير لم يلد ولم يولد
{{
  "mode": "tafsir",
  "hadith_queries": [],
  "quran_queries": ["112:3"],
  "dua_query": null,
  "emotion": null
}}

السؤال: وش تفسير قل أعوذ برب الفلق
{{
  "mode": "tafsir",
  "hadith_queries": [],
  "quran_queries": ["113:1"],
  "dua_query": null,
  "emotion": null
}}

السؤال: ايش تفسير سورة الفلق
{{
  "mode": "tafsir",
  "hadith_queries": [],
  "quran_queries": ["surah:113"],
  "dua_query": null,
  "emotion": null
}}

السؤال: ما الفرق بين أعوذ برب الناس وأعوذ برب الفلق
{{
  "mode": "tafsir",
  "hadith_queries": [],
  "quran_queries": ["114:1", "113:1"],
  "dua_query": null,
  "emotion": null
}}

السؤال: ايش حكم السحر
{{
  "mode": "fiqh",
  "hadith_queries": ["اجتنبوا السبع الموبقات السحر", "حكم ممارسة السحر"],
  "quran_queries": ["واتبعوا ما تتلو الشياطين على ملك سليمان"],
  "dua_query": null,
  "emotion": null
}}

السؤال: هل حديث كل مما يليك صحيح
{{
  "mode": "verify_hadith",
  "hadith_queries": ["كل مما يليك"],
  "quran_queries": [],
  "dua_query": null,
  "emotion": null
}}

السؤال:
{question}

الإخراج:
{{
  "mode": "",
  "hadith_queries": [],
  "quran_queries": [],
  "dua_query": null,
  "emotion": null
}}
"""

    try:
        response = openai_client.chat.completions.create(
            model="gpt-4o-mini",
            temperature=0,
            messages=[{"role": "user", "content": prompt}],
        )
        return json.loads(response.choices[0].message.content.strip())

    except Exception:
        return {
            "mode": "general",
            "hadith_queries": [],
            "quran_queries": [],
            "dua_query": None,
            "emotion": None
        }


def build_hadith_context(hadiths):
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


def build_quran_context(verses):
    chunks = []

    for i, v in enumerate(verses, start=1):
        chunks.append(
            f"""آية {i}:
الموضع: {v.get("verse_key", "")}
النص: {v.get("text", "")}
التفسير: {v.get("tafsir", "")}
المصدر: {v.get("tafsir_name", "")}
المفسر: {v.get("author", "")}
"""
        )

    return "\n".join(chunks)


def general_text_answer(question: str):
    return (
        "هداي مخصص للأسئلة المتعلقة بالقرآن، الحديث، الأحكام الشرعية، "
        "والدعم الروحاني.\n\n"
        "اكتب سؤالك ضمن هذه المجالات، وسأساعدك بإذن الله."
    )

def tafsir_answer(question: str, verses):
    if not verses:
        return "لم يتم العثور على تفسير مناسب."

    tafsir_name = verses[0].get("tafsir_name", "")
    author = verses[0].get("author", "")

    context = ""

    for i, verse in enumerate(verses, start=1):
        context += f"""
النص {i}:
الآية: {verse.get("text", "")}
التفسير: {verse.get("tafsir", "")}
الموضع: {verse.get("verse_key", "")}
"""

    if not openai_client:
        return context

    prompt = f"""
أنت مساعد تفسير قرآني.

سؤال المستخدم:
{question}

المصدر:
{tafsir_name}
المفسر:
{author}

النصوص المسترجعة من القرآن وتفسير السعدي:
{context}

المطلوب:
افهم قصد المستخدم من السؤال بنفسك.
إذا كان يريد تفسيرًا، اشرح التفسير.
إذا كان يريد مقارنة، قارن بين النصوص المسترجعة.
إذا كان يريد معنى لفظ، اشرح اللفظ من التفسير المتاح.
إذا كان يريد سورة كاملة، لخص معنى السورة من الآيات المسترجعة.
لا تخترع آيات.
لا تخترع تفسيرًا.
استخدم فقط النصوص المسترجعة.
لا تستخدم markdown.
اكتب بلغة عربية واضحة ومختصرة.
اذكر المصدر والمفسر في نهاية الرد.

الرد:
"""

    try:
        response = openai_client.chat.completions.create(
            model="gpt-4o-mini",
            temperature=0.2,
            messages=[{"role": "user", "content": prompt}],
        )
        return response.choices[0].message.content.strip()

    except Exception:
        return context
    

def fiqh_quran_sunnah_answer(question: str, verses, hadiths):
    if not verses and not hadiths:
        return "لم أجد في النتائج المسترجعة ما يكفي لإعطاء جواب مباشر من القرآن والسنة."

    if not openai_client:
        return "تم العثور على نصوص مرتبطة بالسؤال من القرآن والسنة."

    quran_context = build_quran_context(verses[:5])
    hadith_context = build_hadith_context(hadiths[:5])

    prompt = f"""
أنت مساعد يجيب على الأسئلة الفقهية اعتمادًا على القرآن والسنة فقط.

السؤال:
{question}

آيات القرآن وتفسير السعدي:
{quran_context}

الأحاديث:
{hadith_context}

التعليمات:
ابدأ بعبارة: الحكم الظاهر من القرآن والسنة هو...
لا تصدر فتوى مطلقة إذا كانت الأدلة غير كافية.
إذا لم تكف النصوص المسترجعة قل ذلك بوضوح.
اعتمد فقط على الآيات وتفسير السعدي والأحاديث المعطاة.
لا تضف معلومات من خارج النصوص.
إذا وجدت آيات مناسبة اكتب: الدليل من القرآن.
إذا لم توجد آيات مناسبة لا تذكر القرآن.
إذا وجدت أحاديث مناسبة اكتب: الدليل من السنة.
اذكر الراوي والمحدث والدرجة عند الاستدلال بالحديث.
لا تستخدم markdown.

الإجابة:
"""

    try:
        response = openai_client.chat.completions.create(
            model="gpt-4o-mini",
            temperature=0.1,
            messages=[{"role": "user", "content": prompt}],
        )
        return response.choices[0].message.content.strip()

    except Exception:
        return "حدث خطأ أثناء توليد الجواب."


def verify_hadith_answer(question: str, hadith):
    if not hadith:
        return "لم يتم العثور على حديث مطابق للسؤال."

    text = hadith.get("text", "")
    score = hadith.get("score", 0)

    # 🔴 فلتر قوة المطابقة
    if score < 5 or len(text) < 20:
        return "لم يتم العثور على حديث مطابق بشكل موثوق."

    return f"""

إذا لم يكن الحديث مطابقًا بوضوح، لا تحاول التخمين.
لا تذكر أحاديث مشابهة.
لا تكمل من عندك.
أعد رسالة تفيد بعدم العثور على حديث مطابق.

نص الحديث:
{text}

الراوي: {hadith.get("narrator", "")}
المصدر: {hadith.get("source", "")}
الدرجة: {hadith.get("grade", "")}
"""


def support_reflection_answer(user_input: str, support_case: dict):
    emotion = support_case.get("emotion", "")
    dua_text = support_case.get("dua", "")
    verse_text = support_case.get("verse", "")
    verse_ref = support_case.get("verse_ref", "")
    hadith_text = support_case.get("hadith", "")

    if not openai_client:
        return (
            f"أفهم شعورك.\n\n"
            f"آية مناسبة:\n{verse_text}\n{verse_ref}\n\n"
            f"حديث مناسب:\n{hadith_text}\n\n"
            f"دعاء مناسب:\n{dua_text}"
        )

    prompt = f"""
أنت "هداي"، مساعد ذكي يتمتع بذكاء عاطفي عميق ورزانة في الطرح.
مهمتك تقديم المواساة والسكينة للمستخدم بناءً على الوحيين: القرآن والسنة.

كلام المستخدم:
{user_input}

الحالة المكتشفة:
{emotion}

المصادر المسموح استخدامها فقط:

الآية:
{verse_text}
المرجع:
{verse_ref}

الحديث:
{hadith_text}

الدعاء:
{dua_text}

المهام:
استشعر الحالة الوجدانية للمستخدم من كلماته.
قدّم مواساة أو مشاركة شعورية متناغمة.
لا تسرد الآية والحديث والدعاء كقائمة جافة.
انسج الآية أو الحديث داخل الكلام بحيث تكون روح الجملة.
اختم بالدعاء كرسالة طمأنينة أخيرة.

قواعد صارمة:
استخدم فقط الآية والحديث والدعاء المكتوبة أعلاه.
لا تخترع آية.
لا تخترع حديث.
لا تخترع دعاء.
لا تغيّر نص الآية أو الحديث أو الدعاء.
لا تضف مصدرًا غير موجود.
لا تستخدم markdown.
لا تستخدم أقواس كثيرة.
لا تبدأ بكلمة "الإجابة".

قواعد الصياغة:
ابدأ دائمًا بعبارة تلمس شعور المستخدم.
مثال:اتفهم شعورك.
مثال: ما أجمل هذا الاستبشار.
اجعل الانتقال بين كلامك والآية أو الحديث انسيابيًا.
مثال: وتذكّر دائمًا أن...
مثال: وكما علّمنا النبي ﷺ في قوله...
اختم بالدعاء كرسالة طمأنينة أخيرة.

اكتب الرد النهائي فقط.
"""

    try:
        response = openai_client.chat.completions.create(
            model="gpt-4o-mini",
            temperature=0.35,
            messages=[{"role": "user", "content": prompt}],
        )
        return response.choices[0].message.content.strip()

    except Exception:
        return (
            f"أفهم شعورك.\n\n"
            f"آية مناسبة:\n{verse_text}\n{verse_ref}\n\n"
            f"حديث مناسب:\n{hadith_text}\n\n"
            f"دعاء مناسب:\n{dua_text}"
        )
    
