#!/usr/bin/env bash
# One-time setup for Hangul Quest (macOS / Linux).
#
# Generates the android/ + ios/ folders, fetches packages and patches
# AndroidManifest.xml so the Korean text-to-speech engine is visible on
# Android 11+. The patch is verified afterwards: without it the audio buttons
# stay silent with no error at all.
set -e
cd "$(dirname "$0")"

MANIFEST=android/app/src/main/AndroidManifest.xml

echo "[1/4] Creating platform folders..."
flutter create . --project-name hangul_quest --org com.hangulquest --platforms android,ios

echo "[2/4] Patching AndroidManifest.xml for text-to-speech..."
if grep -q "android.intent.action.TTS_SERVICE" "$MANIFEST"; then
  echo "      already patched."
else
  python3 - "$MANIFEST" <<'EOF'
import re, sys

path = sys.argv[1]
xml = open(path, encoding="utf-8").read()
queries = (
    "    <!-- Required on Android 11+ so the app can see the TTS engine. -->\n"
    "    <queries>\n"
    "        <intent>\n"
    '            <action android:name="android.intent.action.TTS_SERVICE" />\n'
    "        </intent>\n"
    "    </queries>\n"
)
xml, count = re.subn(r"(<manifest[^>]*>\s*)", lambda m: m.group(1) + queries, xml, count=1)
if count != 1:
    sys.exit("could not find the <manifest> tag in " + path)
open(path, "w", encoding="utf-8").write(xml)
print("      patched.")
EOF
fi

# Fail loudly instead of shipping an app with silent audio.
if ! grep -q "android.intent.action.TTS_SERVICE" "$MANIFEST"; then
  echo "ERROR: AndroidManifest.xml still has no <queries> block for TTS." >&2
  echo "       Add it by hand, or the audio buttons will do nothing on Android 11+." >&2
  exit 1
fi

echo "[3/4] Fetching packages..."
flutter pub get

echo "[4/4] Sanity checks..."
flutter analyze
flutter test

echo
echo "Done. Start an emulator or plug in a phone, then run:  flutter run"
echo
echo "Note: the emulator usually ships without a Korean voice. If the audio"
echo "buttons show a hint instead of speaking, install the language pack:"
echo "  Android: Settings > System > Languages & input > Text-to-speech > install Korean"
echo "  iOS:     Settings > Accessibility > Spoken Content > Voices > Korean"
echo "(iOS audio-session setup is handled in lib/services/tts.dart.)"
