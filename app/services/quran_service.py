import requests
from bs4 import BeautifulSoup
import re

TAFSIR_ID = 91


def get_tafsir_info() -> dict:
    try:
        response = requests.get(
            "https://api.quran.com/api/v4/resources/tafsirs",
            timeout=15
        )

        if response.status_code == 200:
            for tafsir in response.json().get("tafsirs", []):
                if tafsir.get("id") == TAFSIR_ID:
                    return {
                        "id": TAFSIR_ID,
                        "name": tafsir.get("name", "تفسير السعدي"),
                        "author": tafsir.get("author_name", "عبدالرحمن السعدي"),
                    }
    except Exception:
        pass

    return {
        "id": TAFSIR_ID,
        "name": "تفسير السعدي",
        "author": "عبدالرحمن بن ناصر السعدي",
    }


TAFSIR_INFO = get_tafsir_info()


def get_tafsir_text(verse_key: str):
    url = f"https://api.quran.com/api/v4/tafsirs/{TAFSIR_ID}/by_ayah/{verse_key}"

    try:
        response = requests.get(url, timeout=15)

        if response.status_code != 200:
            return ""

        data = response.json()

        tafsirs = data.get("tafsirs", [])
        if tafsirs:
            text = tafsirs[0].get("text", "")
            return BeautifulSoup(text, "html.parser").get_text(" ", strip=True)

        tafsir = data.get("tafsir", {})
        if tafsir:
            text = tafsir.get("text", "")
            return BeautifulSoup(text, "html.parser").get_text(" ", strip=True)

        return ""

    except Exception:
        return ""


def get_verse_with_tafsir(surah: int, ayah: int):
    verse_key = f"{surah}:{ayah}"

    verse_url = f"https://api.quran.com/api/v4/verses/by_key/{verse_key}"
    verse_params = {
        "language": "ar",
        "fields": "text_uthmani",
    }

    try:
        verse_response = requests.get(
            verse_url,
            params=verse_params,
            timeout=15
        )

        if verse_response.status_code != 200:
            return None

        verse_data = verse_response.json().get("verse", {})
        tafsir_text = get_tafsir_text(verse_key)

        return {
            "verse_key": verse_data.get("verse_key", verse_key),
            "text": verse_data.get("text_uthmani", ""),
            "tafsir": tafsir_text,
            "tafsir_name": TAFSIR_INFO["name"],
            "author": TAFSIR_INFO["author"],
        }

    except Exception:
        return None


def normalize_query(text: str):
    text = text.strip()
    text = text.replace("أ", "ا")
    text = text.replace("إ", "ا")
    text = text.replace("آ", "ا")
    text = text.replace("ٱ", "ا")
    text = text.replace("َ", "")
    text = text.replace("ُ", "")
    text = text.replace("ِ", "")
    text = text.replace("ْ", "")
    text = text.replace("ّ", "")
    text = text.replace("ً", "")
    text = text.replace("ٌ", "")
    text = text.replace("ٍ", "")
    return text


def search_quran(keyword: str):
    url = "https://api.quran.com/api/v4/search"

    normalized = normalize_query(keyword)

    try:
        response = requests.get(
            url,
            params={
                "q": keyword,
                "size": 3,
                "language": "ar",
            },
            timeout=15,
        )

        results = []

        if response.status_code == 200:
            for item in response.json().get("search", {}).get("results", []):
                key = item.get("verse_key", "")

                if ":" not in key:
                    continue

                surah, ayah = key.split(":")
                verse = get_verse_with_tafsir(int(surah), int(ayah))

                if verse:
                    results.append(verse)

        if not results:
            if "الفلق" in normalized:
                verse = get_verse_with_tafsir(113, 1)
                if verse:
                    results.append(verse)

            elif "الناس" in normalized:
                verse = get_verse_with_tafsir(114, 1)
                if verse:
                    results.append(verse)

            elif "لم يلد ولم يولد" in normalized:
                verse = get_verse_with_tafsir(112, 3)
                if verse:
                    results.append(verse)

        return results

    except Exception:
        return []
    

def retrieve_quran_by_queries(queries):
    if not queries:
        return [], []

    all_verses = []
    used_queries = []

    for query in queries:
        q = query.strip()
        if not q:
            continue

        used_queries.append(q)

        # سورة كاملة مثل surah:113
        if q.startswith("surah:"):
            surah_number = int(q.replace("surah:", ""))

            for ayah in range(1, 20):
                verse = get_verse_with_tafsir(surah_number, ayah)

                if not verse:
                    break

                if not verse.get("text"):
                    break

                all_verses.append(verse)

            continue

        # آية محددة مثل 113:1
        if re.match(r"^\d+:\d+$", q):
            surah, ayah = q.split(":")
            verse = get_verse_with_tafsir(int(surah), int(ayah))

            if verse:
                all_verses.append(verse)

            continue

        # بحث عادي
        all_verses.extend(search_quran(q))

    unique = {}

    for verse in all_verses:
        if verse:
            unique[verse["verse_key"]] = verse

    return list(unique.values()), used_queries