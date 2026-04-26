# HudAI 🕌
### Arabic Hadith-based Question Answering System

> يعتمد النظام حصرياً على الأحاديث الصحيحة من موقع الدرر السنية

---

## Architecture

```
User Question (Arabic)
        ↓
① Keyword Extraction  ──── Claude Haiku (fast, cheap)
        ↓
② Dorar.net API       ──── https://dorar.net/dorar_api.json
        ↓
③ HTML Parsing        ──── BeautifulSoup4
        ↓
④ Grade Filtering     ──── Rule-based (صحيح / حسن / ثابت)
        ↓
⑤ Prompt Construction ──── Few-shot strict prompt
        ↓
⑥ Answer Generation   ──── Claude Sonnet (temperature=0.1)
        ↓
Final Answer + Sources
```

---

## Project Structure

```
hudai/
├── backend/
│   ├── main.py          # FastAPI app + routes
│   ├── pipeline.py      # Full 8-step RAG pipeline
│   ├── requirements.txt
│   ├── Dockerfile
│   └── .env.example
├── flutter_app/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   └── chat_screen.dart
│   │   ├── widgets/
│   │   │   └── hadith_source_card.dart
│   │   ├── models/
│   │   │   └── answer_response.dart
│   │   ├── providers/
│   │   │   └── chat_provider.dart
│   │   └── services/
│   │       └── api_service.dart
│   └── pubspec.yaml
├── evaluation/
│   └── evaluate.py      # RAGAS evaluation script
└── docker-compose.yml
```

---

## Backend Setup

```bash
cd backend
pip install -r requirements.txt

# Create .env file
cp .env.example .env
# Edit .env and add: ANTHROPIC_API_KEY=your_key_here

# Run
uvicorn main:app --reload --port 8000
```

### API Endpoint

```
POST /ask
Content-Type: application/json

{
  "question": "ما فضل الصلاة في أول وقتها؟"
}
```

**Response:**
```json
{
  "answer": "الإجابة:\n...\n\nالدليل:\n- الحديث: ...",
  "sources": [
    {
      "text": "...",
      "narrator": "...",
      "source": "...",
      "grade": "صحيح"
    }
  ],
  "keyword_used": "الصلاة",
  "total_retrieved": 20,
  "total_after_filter": 8
}
```

---

## Flutter App Setup

```bash
cd flutter_app
flutter pub get

# Update API URL in lib/services/api_service.dart
# Change: static const String baseUrl = 'http://YOUR_BACKEND_URL:8000';

flutter run
```

---

## Docker Deployment

```bash
# Create .env file
echo "ANTHROPIC_API_KEY=your_key" > .env

# Build and run
docker-compose up --build
```

---

## Evaluation (RAGAS)

```bash
cd evaluation

pip install ragas datasets langchain-anthropic

# Edit evaluate.py to add ANTHROPIC_API_KEY
python evaluate.py
```

### Metrics
| Metric | Description |
|--------|-------------|
| Faithfulness | Answer only uses retrieved context |
| Answer Relevancy | Answer addresses the question |
| Context Precision | Retrieved Hadith are relevant |

---

## Accepted Hadith Grades

The system only uses Hadith with these authenticity grades:
- `صحيح` (Sahih / Authentic)
- `حسن` (Hasan / Good)
- `ثابت` (Established)
- `صحيح لغيره` (Sahih due to supporting narrations)
- `حسن لغيره` (Hasan due to supporting narrations)
- `صحيح الإسناد` (Sound chain)
- `حسن الإسناد` (Good chain)

---

## Design Decisions

- **Temperature 0.1**: Minimizes hallucination in answers
- **Few-shot prompting**: Forces the model to follow exact output format
- **Strict system prompt**: Explicitly prohibits external knowledge
- **Grade filtering**: Only trusted Hadith grades are included
- **Keyword extraction**: Lightweight model (Haiku) extracts single keyword for API efficiency

---

## Notes

- The Dorar API returns Arabic HTML content; BeautifulSoup handles parsing
- CORS proxy may be needed in browser-only deployments (see demo HTML)
- For production, run the FastAPI backend and point Flutter/web clients to it
