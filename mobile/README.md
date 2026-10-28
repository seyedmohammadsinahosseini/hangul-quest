# Hangul Quest — Flutter app

Learn Korean from absolute zero, in English. Mobile-first, fully offline.

> This is the mobile client of [Hangul Quest](../README.md). It carries the same curriculum and the
> same rules as the [web app](../web) and runs without a network connection.

* **4-stage roadmap** – Hangul → Essential Words → Grammar Engine → Real Conversations (39 lessons, 247 cards)
* **8 exercise types** – flashcards, Korean→English, English→Korean, romanization, listening (Korean TTS), typing,
  **Syllable Builder** (assemble jamo into real blocks), **Matching game**, **Sentence Builder**
* **70 % mastery rule** – a lesson only counts as passed at ≥70 %; the next lesson (and next stage) unlocks only then.
  Grammar opens after 4 vocabulary lessons at ≥70 % accuracy; Conversations after 3 grammar lessons.
* **Hard XP economy** – 1 XP per un-hinted correct answer. Small hint = 6 XP, Coach hint = 12 XP, Reveal = 18 XP.
  A hinted question never pays XP.
* **Progress percentages** everywhere – overall, per stage (`x % complete · n lessons remaining`) and per unit.
* Review Deck (spaced repetition, 3 recalls = mastered), daily streak & goal, 8 achievements, light/dark theme.

## Requirements

* Flutter **3.27 or newer** (`flutter --version`)
* Android Studio / Xcode toolchain for the platform you want to run on

## Run it

```bash
cd mobile

# 1) generate the android/ and ios/ platform folders (keeps all existing files)
flutter create . --project-name hangul_quest --org com.hangulquest --platforms android,ios

# 2) fetch dependencies
flutter pub get

# 3) run on a connected phone / emulator
flutter run
```

`setup.sh` / `setup.bat` do all three steps in one go, patch `AndroidManifest.xml` for
text-to-speech and then run `flutter analyze` + `flutter test`.

Release build:

```bash
flutter build apk --release        # Android
flutter build ipa --release        # iOS (needs signing)
```

## Checking it

```bash
flutter analyze    # must stay clean
flutter test       # layout + audio regression tests
```

## Troubleshooting audio

The audio buttons use the platform speech engine (`flutter_tts`) and speak `ko-KR`. If a tap shows
a hint instead of speaking, the engine is fine but the device has no Korean voice:

* **Android** — Settings → System → Languages & input → Text-to-speech → install the Korean voice
  data. On Android 11+ the app also needs the `TTS_SERVICE` `<queries>` entry in
  `AndroidManifest.xml`; `mobile/setup.sh` adds it and verifies it, and the app cannot see any TTS
  engine without it.
* **iOS** — Settings → Accessibility → Spoken Content → Voices → Korean. `lib/services/tts.dart`
  sets the `.playback` audio session category, so the app speaks even with the ring/silent switch
  on silent.
* **Emulators** frequently ship without a Korean voice. Install it in the emulator's system
  settings, or test on a real phone.

`Tts.status` and `Tts.lastError` expose exactly what the engine reported, which is what the in-app
hint is built from.

## Project layout

```
lib/
  main.dart                  app entry, theme switching, AppScope (InheritedNotifier)
  theme.dart                 light/dark themes + HQColors extension
  models/curriculum.dart     KCard / Lesson / Unit / LearningPath, hint costs
  data/curriculum_data.dart  ALL lesson content (edit here to add lessons)
  logic/quiz_engine.dart     deterministic question generator (8 exercise types)
  logic/hangul.dart          jamo → syllable composition (U+AC00 maths)
  state/app_state.dart       progress, XP, unlock rules, streaks, achievements, persistence
  services/tts.dart          Korean text-to-speech (flutter_tts)
  widgets/ui.dart            Panel, Bar, Ring, Pill, SpeakerButton …
  screens/                   home (roadmap), path map, lesson player, alphabet, review, profile
```

Progress is stored on-device with `shared_preferences`. Delete the app or use **You → Reset all progress** to start over.

## Adding content

Open `lib/data/curriculum_data.dart` and add a `Lesson(...)` to any unit. Use:

* `_j(id, ko, rom, en, [note])` – a letter
* `_syl(id, ko, rom, en, [jamo…], [note])` – a syllable block (enables the Builder game)
* `_w(id, ko, rom, en, ex: Example(...), note: ...)` – a word
* `_s(id, ko, rom, en, [chunks…], [note])` – a sentence (enables the Sentence Builder)

Unlock rules, percentages and XP are computed automatically from the data.

## Optional: sync with the web backend

The [`web/`](../web) folder contains a Next.js + PostgreSQL version with the same rules and a JSON API
(`/api/state`, `/api/action`, `/api/leaderboard`). The Flutter app is self-contained and does not need it,
but `AppState` is the single place to swap local persistence for HTTP calls if you want cloud sync or a leaderboard.
