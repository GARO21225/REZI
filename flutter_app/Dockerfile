# ── Étape 1 : build Flutter Web ──
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get
COPY . .
RUN flutter build web --release \
    --dart-define=API_BASE_URL=http://204.168.229.74:8081/api

# ── Étape 2 : servir le build statique ──
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
