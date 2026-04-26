# Stage 1: Flutter build
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

ARG API_BASE_URL=http://localhost:8000

# Cache pub dependencies — only re-runs when pubspec files change
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

# Stage 2: nginx to serve the built web app
FROM nginx:alpine AS runtime

RUN rm -rf /usr/share/nginx/html/*

COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
