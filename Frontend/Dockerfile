# Stage 1: Flutter build
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

ARG API_BASE_URL=http://localhost:8000
ARG EMAILJS_SERVICE_ID=
ARG EMAILJS_TEMPLATE_ID=
ARG EMAILJS_TEMPLATE_ID_PASSWORD=
ARG EMAILJS_PUBLIC_KEY=

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

RUN flutter build web --release \
    --dart-define=API_BASE_URL=${API_BASE_URL} \
    --dart-define=EMAILJS_SERVICE_ID=${EMAILJS_SERVICE_ID} \
    --dart-define=EMAILJS_TEMPLATE_ID=${EMAILJS_TEMPLATE_ID} \
    --dart-define=EMAILJS_TEMPLATE_ID_PASSWORD=${EMAILJS_TEMPLATE_ID_PASSWORD} \
    --dart-define=EMAILJS_PUBLIC_KEY=${EMAILJS_PUBLIC_KEY}

# Stage 2: Caddy to serve the built web app
FROM caddy:alpine AS runtime

COPY --from=builder /app/build/web /srv
COPY Caddyfile /etc/caddy/Caddyfile
