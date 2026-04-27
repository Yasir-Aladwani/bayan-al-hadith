# Stage 1: Flutter build
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

ARG API_BASE_URL=http://localhost:8000

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

# Stage 2: Caddy to serve the built web app
FROM caddy:alpine AS runtime

COPY --from=builder /app/build/web /srv
COPY Caddyfile /etc/caddy/Caddyfile
