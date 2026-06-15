#!/usr/bin/env bash
set -eu

if ! command -v flutter >/dev/null 2>&1; then
  FLUTTER_HOME="/tmp/flutter"
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_HOME"
  export PATH="$FLUTTER_HOME/bin:$PATH"
  flutter config --enable-web
  flutter precache --web
fi

flutter --version
flutter pub get

if [ "${VERCEL:-}" = "1" ]; then
  flutter build web --release --pwa-strategy=none --base-href "/"
else
  flutter build web --release --pwa-strategy=none --base-href "/implant-stock/"
fi
