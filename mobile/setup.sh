#!/usr/bin/env bash
# One-time setup for Hangul Quest (macOS / Linux).
set -e
cd "$(dirname "$0")"

echo "[1/3] Creating platform folders..."
flutter create . --project-name hangul_quest --org com.hangulquest --platforms android,ios

echo "[2/3] Fetching packages..."
flutter pub get

echo "[3/3] Patching AndroidManifest.xml for text-to-speech..."
M=android/app/src/main/AndroidManifest.xml
if ! grep -q TTS_SERVICE "$M"; then
  python3 - "$M" <<'EOF'
import re, sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
q = ('    <queries>\n        <intent>\n'
     '            <action android:name="android.intent.action.TTS_SERVICE" />\n'
     '        </intent>\n    </queries>\n')
s = re.sub(r'(<manifest[^>]*>\s*)', lambda m: m.group(1) + q, s, count=1)
open(p, "w", encoding="utf-8").write(s)
print("Manifest patched.")
EOF
else
  echo "Manifest already patched."
fi

echo
echo "Done. Start an emulator or plug in a phone, then run:  flutter run"
