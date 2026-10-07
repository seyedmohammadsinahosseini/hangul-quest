# Changelog

All notable changes to this project are documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Server-side answer validation and signed lesson sessions
- Playwright end-to-end suite for the web client
- Flutter widget tests for the quiz engine and unlock rules
- Optional cloud sync between the web and mobile clients

## [1.0.0] — 2026-10-07

First public release.

### Added
- **Web client** (Next.js 16, React 19, TypeScript, Tailwind 4): roadmap, path map, hangul chart,
  lesson player, review deck, profile and leaderboard pages; light/dark theme.
- **Four-stage curriculum** — 39 lessons, 247 cards, 15 units across Hangul Foundations,
  Essential Words, Grammar Engine and Real Conversations, with 70 % mastery gating between stages.
- **Quiz engine with 8 exercise types** — flashcards, Korean ↔ English multiple choice,
  romanization, listening, typing, syllable builder (jamo composition), matching game and
  sentence builder — generated from a seeded PRNG so every attempt is fair and reproducible.
- **Server-side game economy** (Drizzle + PostgreSQL): XP earned/spent ledger, hint pricing,
  streaks with a one-day grace window, daily goal, 8 achievements, spaced-review deck that retires
  a card after three correct recalls, and a leaderboard.
- **REST API** — `/api/state`, `/api/action`, `/api/leaderboard`, `/api/health`.
- **Flutter client** (offline, `shared_preferences` + `flutter_tts`) sharing the same curriculum
  and rules, with on-device progress and text-to-speech for every card.
- **Tooling** — SQL migrations (Drizzle Kit), demo seed script, Vitest suite (curriculum integrity,
  pass marks, generator determinism), ESLint, strict TypeScript and a GitHub Actions CI workflow.
- **Documentation** — README with screenshots, architecture notes, roadmap and deployment guide.

### Fixed
- A submitted lesson attempt now stays on its results screen instead of remounting the lesson:
  the player is keyed by lesson id only, so a fresh attempt can no longer wipe the result.
- The display-name field derives from server state instead of mirroring it in an effect.
- Database credentials are read from `DATABASE_URL` rather than being hard-coded in the
  Drizzle configuration.

### Changed
- Repository restructured into `web/` (Next.js) and `mobile/` (Flutter) with documentation in
  `docs/`; the manually uploaded project archive was dropped in favour of tracked sources.
