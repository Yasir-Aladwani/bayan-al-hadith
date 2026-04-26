"""
HudAI Pipeline
Full 8-step RAG pipeline for Arabic Hadith QA
"""

import asyncio
import logging
import re
import os
import httpx
from bs4 import BeautifulSoup
from anthropic import Anthropic
from dataclasses import dataclass

logger = logging.getLogger("HudAI.Pipeline")

# ─────────────────────────────────────────────
# Constants
# ─────────────────────────────────────────────
DORAR_API_URL = "https://dorar.net/dorar_api.json"

ACCEPTED_GRADES = {
    "صحيح",
    "حسن",
    "ثابت",
    "صحيح لغيره",
    "حسن لغيره",
    "صحيح الإسناد",
    "حسن الإسناد",
}

MAX_HADITH_CONTEXT = 5  # Max hadiths to include in LLM prompt

# ─────────────────────────────────────────────
# Data Models
# ─────────────────────────────────────────────
@dataclass
class Hadith:
    text: str
    narrator: str
    source: str
    grade: str

    def to_dict(self) -> dict:
        return {
            "text": self.text,
            "narrator": self.narrator,
            "source": self.source,
            "grade": self.grade,
        }

# ─────────────────────────────────────────────
# Pipeline Class
# ─────────────────────────────────────────────
class HadithPipeline:
    def __init__(self):
        self.client = Anthropic()  # Uses ANTHROPIC_API_KEY env var
        logger.info("HadithPipeline initialized")

    # ─────────────────────────────────────────
    # STEP 2: Keyword Extraction
    # ─────────────────────────────────────────
    def extract_keyword(self, question: str) -> str:
        """
        Use Claude to extract a single Arabic keyword from the question.
        This keyword is used to query the Dorar API.
        """
        logger.info(f"[Step 2] Extracting keyword from: {question}")

        response = self.client.messages.create(
            model="claude-haiku-4-5-20251001",
            max_tokens=50,
            temperature=0.0,
            system=(
                "أنت نظام لاستخراج الكلمات المفتاحية من الأسئلة العربية المتعلقة بالإسلام والحديث النبوي.\n"
                "مهمتك: استخرج كلمة مفتاحية واحدة فقط (الأكثر أهمية) من السؤال المدخل.\n"
                "القواعد:\n"
                "- أجب بكلمة واحدة فقط بدون أي توضيح أو شرح.\n"
                "- اختر الكلمة التي تصف الموضوع الرئيسي للسؤال.\n"
                "- لا تضف أي نص آخر."
            ),
            messages=[{"role": "user", "content": question}],
        )

        keyword = response.content[0].text.strip()
        # Safety: take only first word
        keyword = keyword.split()[0] if keyword else "الصلاة"
        logger.info(f"[Step 2] Extracted keyword: {keyword}")
        return keyword

    # ─────────────────────────────────────────
    # STEP 3: Retrieval from Dorar API
    # ─────────────────────────────────────────
    def retrieve_hadiths(self, keyword: str) -> list[dict]:
        """
        Query Dorar.net API with the extracted keyword.
        Returns raw API results.
        """
        logger.info(f"[Step 3] Querying Dorar API with keyword: {keyword}")

        try:
            with httpx.Client(timeout=15.0) as client:
                response = client.get(
                    DORAR_API_URL,
                    params={"skey": keyword},
                    headers={
                        "User-Agent": "HudAI/1.0 (Arabic Hadith QA System)",
                        "Accept": "application/json",
                    },
                )
                response.raise_for_status()
                data = response.json()

            # Dorar API returns results in "ahadith" key
            raw_results = data.get("ahadith", {}).get("result", [])
            if isinstance(raw_results, str):
                raw_results = []

            logger.info(f"[Step 3] Retrieved {len(raw_results)} raw results")
            return raw_results

        except httpx.HTTPError as e:
            logger.error(f"[Step 3] HTTP error: {e}")
            return []
        except Exception as e:
            logger.error(f"[Step 3] Unexpected error: {e}")
            return []

    # ─────────────────────────────────────────
    # STEP 4: HTML Parsing / Cleaning
    # ─────────────────────────────────────────
    def parse_hadith(self, raw: dict) -> Hadith | None:
        """
        Parse a single raw API result into a Hadith object.
        Cleans HTML, extracts text/narrator/source/grade.
        """
        try:
            # Clean hadith text
            raw_text = raw.get("hadith", "") or ""
            text = self._clean_html(raw_text)

            # Extract fields
            narrator = self._clean_html(raw.get("rawi", "") or "")
            source = self._clean_html(raw.get("mohdith", "") or "")
            book = self._clean_html(raw.get("book", "") or "")
            grade = self._clean_html(raw.get("grade", "") or "")
            shareh = self._clean_html(raw.get("shareh", "") or "")

            # Combine source info
            full_source = source
            if book:
                full_source = f"{source} - {book}" if source else book

            # Skip if no meaningful text
            if not text or len(text) < 10:
                return None

            return Hadith(
                text=text,
                narrator=narrator or "غير محدد",
                source=full_source or "غير محدد",
                grade=grade or "غير محدد",
            )

        except Exception as e:
            logger.warning(f"[Step 4] Parse error: {e}")
            return None

    def _clean_html(self, raw: str) -> str:
        """Strip HTML tags and normalize whitespace."""
        if not raw:
            return ""
        soup = BeautifulSoup(raw, "html.parser")
        text = soup.get_text(separator=" ")
        # Normalize whitespace
        text = re.sub(r'\s+', ' ', text).strip()
        return text

    # ─────────────────────────────────────────
    # STEP 5: Filtering
    # ─────────────────────────────────────────
    def filter_hadiths(self, hadiths: list[Hadith]) -> list[Hadith]:
        """
        Keep only Hadith with accepted authenticity grades.
        Rule-based filtering using ACCEPTED_GRADES set.
        """
        logger.info(f"[Step 5] Filtering {len(hadiths)} hadiths...")

        filtered = []
        for h in hadiths:
            grade_lower = h.grade.strip()
            # Check if any accepted grade string is in the hadith's grade
            is_accepted = any(
                accepted in grade_lower
                for accepted in ACCEPTED_GRADES
            )
            if is_accepted:
                filtered.append(h)
            else:
                logger.debug(f"[Step 5] Rejected grade: '{h.grade}'")

        logger.info(f"[Step 5] Kept {len(filtered)} hadiths after filtering")
        return filtered

    # ─────────────────────────────────────────
    # STEP 6: Prompt Construction (Few-shot)
    # ─────────────────────────────────────────
    def build_prompt(self, question: str, hadiths: list[Hadith]) -> str:
        """
        Build a strict few-shot prompt that forces the LLM to answer
        ONLY based on the provided Hadith context.
        """
        # Format hadith context
        context_parts = []
        for i, h in enumerate(hadiths[:MAX_HADITH_CONTEXT], 1):
            context_parts.append(
                f"[حديث {i}]\n"
                f"النص: {h.text}\n"
                f"الراوي: {h.narrator}\n"
                f"المصدر: {h.source}\n"
                f"الدرجة: {h.grade}"
            )
        context = "\n\n".join(context_parts)

        # Few-shot example
        few_shot_example = """=== مثال توضيحي ===

السؤال: ما فضل قراءة سورة الإخلاص؟

السياق:
[حديث 1]
النص: من قرأ قل هو الله أحد عشر مرات بنى الله له بيتا في الجنة
الراوي: معاذ بن أنس الجهني
المصدر: مسند أحمد
الدرجة: حسن لغيره

الإجابة:
إن سورة الإخلاص من السور العظيمة التي حثّ النبي ﷺ على قراءتها، فمن قرأها عشر مرات بنى الله له بيتاً في الجنة.

الدليل:
- الحديث: من قرأ قل هو الله أحد عشر مرات بنى الله له بيتا في الجنة
- الراوي: معاذ بن أنس الجهني
- المصدر: مسند أحمد
- الدرجة: حسن لغيره

=== نهاية المثال ==="""

        prompt = f"""{few_shot_example}

الآن أجب على السؤال التالي بناءً فقط على الأحاديث المتوفرة:

السؤال: {question}

السياق (الأحاديث المسترجعة):
{context if context else "لا توجد أحاديث متاحة."}

التعليمات الصارمة:
1. أجب فقط بناءً على الأحاديث الواردة في السياق أعلاه.
2. لا تستخدم أي معلومات خارجية أو معرفة شخصية.
3. إذا لم تكن الأحاديث كافية للإجابة، قل: "لا توجد معلومات كافية في الأحاديث المتاحة للإجابة على هذا السؤال."
4. اذكر الدليل من الأحاديث بشكل واضح في نهاية إجابتك.
5. الإجابة يجب أن تكون باللغة العربية الفصحى.

الإجابة:"""

        return prompt

    # ─────────────────────────────────────────
    # STEP 7: Answer Generation
    # ─────────────────────────────────────────
    def generate_answer(self, prompt: str) -> str:
        """
        Call Claude with the constructed prompt.
        Low temperature to minimize hallucination.
        """
        logger.info("[Step 7] Generating answer with LLM...")

        response = self.client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=1500,
            temperature=0.1,  # Low temp = less hallucination
            system=(
                "أنت نظام إجابة إسلامي متخصص يعتمد حصراً على الأحاديث النبوية الصحيحة. "
                "مهمتك الوحيدة هي الإجابة بناءً على الأحاديث المُقدَّمة لك فقط. "
                "لا تضف أي معلومات من عندك. "
                "إذا لم تكف الأحاديث، صرّح بذلك صراحةً."
            ),
            messages=[{"role": "user", "content": prompt}],
        )

        answer = response.content[0].text.strip()
        logger.info("[Step 7] Answer generated successfully")
        return answer

    # ─────────────────────────────────────────
    # STEP 8: Run Full Pipeline
    # ─────────────────────────────────────────
    async def run(self, question: str) -> dict:
        """
        Orchestrate the full 8-step pipeline.
        Returns structured response with answer + sources.
        """
        # Step 2: Extract keyword
        keyword = self.extract_keyword(question)

        # Step 3: Retrieve from Dorar
        raw_results = self.retrieve_hadiths(keyword)
        total_retrieved = len(raw_results)

        # Step 4: Parse HTML content
        parsed = [self.parse_hadith(r) for r in raw_results]
        hadiths = [h for h in parsed if h is not None]

        # Step 5: Filter by grade
        filtered = self.filter_hadiths(hadiths)
        total_after_filter = len(filtered)

        # Step 6: Build prompt
        prompt = self.build_prompt(question, filtered)

        # Step 7: Generate answer
        answer = self.generate_answer(prompt)

        # Step 8: Return structured result
        return {
            "answer": answer,
            "sources": [h.to_dict() for h in filtered[:MAX_HADITH_CONTEXT]],
            "keyword_used": keyword,
            "total_retrieved": total_retrieved,
            "total_after_filter": total_after_filter,
        }
