import re
import requests
from bs4 import BeautifulSoup
from fastapi import HTTPException
from app.config import DORAR_API_URL, HEADERS


def extract_value(subtitle_span) -> str:
    node = subtitle_span.next_sibling

    while node:
        if isinstance(node, str):
            text = node.strip().strip("-").strip()
            if text:
                return text

        elif hasattr(node, "get"):
            classes = node.get("class", [])
            if "info-subtitle" in classes:
                break
            text = node.get_text(strip=True)
            if text:
                return text

        node = node.next_sibling

    return ""


def parse_single_hadith(hadith_div, info_div):
    item = {}

    raw_text = hadith_div.get_text(separator=" ").strip()
    if "-" in raw_text[:8]:
        raw_text = raw_text.split("-", 1)[-1].strip()

    item["text"] = " ".join(raw_text.split())
    if not item["text"]:
        return None

    for subtitle in info_div.find_all("span", class_="info-subtitle"):
        label = subtitle.get_text(strip=True).replace(":", "").strip()
        value = extract_value(subtitle)

        if "الراوي" in label and "خلاصة" not in label:
            item["narrator"] = value
        elif "المحدث" in label and "خلاصة" not in label:
            item["scholar"] = value
        elif "المصدر" in label:
            item["source"] = value
        elif "الصفحة" in label:
            item["page"] = value
        elif "خلاصة" in label:
            item["grade"] = value

    item.setdefault("narrator", "")
    item.setdefault("scholar", "")
    item.setdefault("source", "")
    item.setdefault("page", "")
    item.setdefault("grade", "")

    return item


def parse_html(full_html: str):
    soup = BeautifulSoup(full_html, "html.parser")
    hadith_divs = soup.find_all("div", class_="hadith")
    info_divs = soup.find_all("div", class_="hadith-info")

    results = []
    for hadith_div, info_div in zip(hadith_divs, info_divs):
        parsed = parse_single_hadith(hadith_div, info_div)
        if parsed:
            results.append(parsed)

    return results


def fetch_from_dorar(keyword: str):
    try:
        response = requests.get(
            DORAR_API_URL,
            params={"skey": keyword},
            headers=HEADERS,
            timeout=15
        )
        response.raise_for_status()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Dorar request failed: {e}")

    data = response.json()
    ahadith_data = data.get("ahadith", {})

    if isinstance(ahadith_data, dict):
        if "result" in ahadith_data and isinstance(ahadith_data["result"], str):
            html = ahadith_data["result"]
        else:
            html = " ".join([v for v in ahadith_data.values() if isinstance(v, str)])
    elif isinstance(ahadith_data, list):
        html = " ".join([x for x in ahadith_data if isinstance(x, str)])
    else:
        html = ""

    if not html.strip():
        return []

    return parse_html(html)