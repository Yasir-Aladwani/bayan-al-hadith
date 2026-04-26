# Plan: Link Frontend & Backend for Railway Deployment

## Context
The project has a Flutter web frontend (`Frontend/`) and a FastAPI Python backend (`Backend/`). They need to be deployed as two Railway services. Currently: (1) the Flutter app's API URL is hardcoded to `localhost:8000`, (2) the Flutter response model reads the wrong JSON key (`sources` but backend sends `hadiths`), (3) the backend has no Dockerfile, and (4) the existing `Frontend/Dockerfile` builds the wrong thing (an old Python server).

## Architecture
- **Service 1 — Backend**: Python FastAPI in `Backend/`, deployed first to get its Railway URL
- **Service 2 — Frontend**: Flutter web app built into static files, served by nginx in `Frontend/`
- The backend URL is injected into the Flutter build at compile time via `--dart-define=API_BASE_URL=...` passed as a Docker build arg, which Railway populates from the service's `API_BASE_URL` environment variable

---

## Files to Create / Modify

### 1. `Backend/Dockerfile` — CREATE
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8000
CMD uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}
```
Note: Shell form `CMD` (not exec form `["uvicorn", ...]`) so Railway's `$PORT` env var is evaluated at runtime.

---

### 2. `Backend/railway.json` — CREATE
```json
{
  "$schema": "https://railway.app/railway-schema.json",
  "build": {
    "builder": "DOCKERFILE",
    "dockerfilePath": "Dockerfile"
  },
  "deploy": {
    "startCommand": "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}",
    "healthcheckPath": "/",
    "healthcheckTimeout": 30,
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 3
  }
}
```
Health check uses `GET /` (the only root endpoint in `Backend/app/main.py`).

---

### 3. `Frontend/lib/services/api_service.dart` — MODIFY
Two changes:
- Line 7: change hardcoded `baseUrl` to `String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8000')`
- Line 32: change `GET /health` → `GET /` (backend has no `/health` route, only `GET /`)

---

### 4. `Frontend/lib/models/answer_response.dart` — MODIFY
Three changes:
- **`HadithSource`**: add `scholar` field with `this.scholar = ''` default (so existing mock call sites in `chat_provider.dart` don't break), and read `json['scholar']` in `fromJson`
- **`AnswerResponse.fromJson`**: change `json['sources']` → `json['hadiths'] as List? ?? json['sources'] as List? ?? []` (the fallback to `sources` preserves backward-compat for Firestore-persisted messages)
- **`AnswerResponse` constructor**: make `keywordUsed`, `totalRetrieved`, `totalAfterFilter` optional with defaults (`= ''`, `= 0`, `= 0`) since the backend never sends them and mock `AnswerResponse(answer:..., sources:[...])` calls in `chat_provider.dart` omit them

---

### 5. `Frontend/Dockerfile` — COMPLETE REWRITE
Current file builds the old Python backend. Rewrite as two-stage Flutter web + nginx build:
```dockerfile
# Stage 1: Flutter build
FROM ghcr.io/cirruslabs/flutter:stable AS builder
WORKDIR /app
ARG API_BASE_URL=http://localhost:8000
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

# Stage 2: nginx
FROM nginx:alpine AS runtime
RUN rm -rf /usr/share/nginx/html/*
COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
EXPOSE 80
ENTRYPOINT ["/docker-entrypoint.sh"]
```

---

### 6. `Frontend/nginx.conf` — CREATE
```nginx
server {
    listen NGINX_PORT_PLACEHOLDER;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    gzip on;
    gzip_types text/plain text/css application/javascript application/json application/wasm font/woff2;
    gzip_min_length 1024;
    gzip_vary on;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location ~* \.(js|css|wasm|png|jpg|ico|svg|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }

    location = /index.html {
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }
}
```
`NGINX_PORT_PLACEHOLDER` is replaced at container startup by `docker-entrypoint.sh`.

---

### 7. `Frontend/docker-entrypoint.sh` — CREATE
```sh
#!/bin/sh
set -e
PORT="${PORT:-80}"
sed -i "s/NGINX_PORT_PLACEHOLDER/${PORT}/g" /etc/nginx/conf.d/default.conf
exec nginx -g "daemon off;"
```
Uses `exec` so nginx is PID 1 and receives Railway's SIGTERM for graceful shutdown.

---

### 8. `Frontend/railway.json` — CREATE
```json
{
  "$schema": "https://railway.app/railway-schema.json",
  "build": {
    "builder": "DOCKERFILE",
    "dockerfilePath": "Dockerfile",
    "buildArgs": {
      "API_BASE_URL": "$API_BASE_URL"
    }
  },
  "deploy": {
    "healthcheckPath": "/",
    "healthcheckTimeout": 60,
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 3
  }
}
```

---

## Railway Deployment Steps (after code changes)

1. **Deploy backend first** (root dir = `Backend/`), set vars: `OPENAI_API_KEY`, `HF_TOKEN`
2. Copy the backend's Railway public URL (e.g. `https://hudai-backend-xxxx.up.railway.app`)
3. **Deploy frontend** (root dir = `Frontend/`), set var: `API_BASE_URL=https://hudai-backend-xxxx.up.railway.app`
4. In Firebase Console → Authentication → Authorized Domains → add the frontend Railway domain (required for Firebase Auth to work on the deployed URL)

---

## Critical Files
- `Backend/app/main.py` — FastAPI entry point, CORS config, `GET /` health route
- `Backend/requirements.txt` — Python deps (fastapi, uvicorn, requests, bs4, openai, python-multipart)
- `Frontend/lib/services/api_service.dart` — API base URL, `POST /ask`, health check
- `Frontend/lib/models/answer_response.dart` — JSON parsing, `sources` vs `hadiths` mismatch
- `Frontend/lib/providers/chat_provider.dart` — uses `AnswerResponse`/`HadithSource` (read-only, no changes needed)

## Verification
1. `curl https://backend-url.railway.app/` → `{"message":"Hadith backend is running"}`
2. `curl -X POST https://backend-url.railway.app/ask -H "Content-Type: application/json" -d '{"question":"ما حكم الصلاة؟"}'` → JSON with `answer` and `hadiths` array
3. Open frontend Railway URL in browser → app loads, submit a question → gets a response with hadith sources
4. Firebase login works (if authorized domain is added)
