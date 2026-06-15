#!/usr/bin/env bash
set -eu
git clone https://github.com/flutter/flutter.git --depth 1 -b stable /tmp/flutter
export PATH=/tmp/flutter/bin:
flutter config --enable-web
flutter precache --web
flutter pub get
flutter build web --release --pwa-strategy=none --base-href /
