# Architecture

Two clients, one set of rules. The web client talks to a PostgreSQL-backed API; the Flutter client
re-implements the same domain rules on-device so it can run with no network at all.

```
        Browser (mobile-first)                      Phone (offline)
┌──────────────────────────────────┐       ┌──────────────────────────────┐
│  app/*/page.tsx   ("use client") │       │  screens/*.dart              │
│         │                        │       │         │                    │
│         ▼                        │       │         ▼                    │
│  lib/store.tsx   (AppProvider)   │       │  state/app_state.dart        │
│         │  fetch /api/*          │       │  (ChangeNotifier)            │
└─────────┼────────────────────────┘       │         │                    │
          │                                │         ▼                    │
          ▼                                │  logic/quiz_engine.dart      │
┌──────────────────────────────────┐       │  logic/hangul.dart           │
│  app/api/**/route.ts             │       │  services/tts.dart           │
│         │                        │       └──────────────────────────────┘
│         ▼                        │
│  lib/engine.ts   (domain rules)  │
│         │                        │
│         ▼                        │
│  db/index.ts → Drizzle → Postgres│
└──────────────────────────────────┘
```

## Web modules

| Module | Responsibility |
|---|---|
| `src/lib/curriculum.ts` | All content as typed literals: `PATHS → units → lessons → cards`, plus `LESSON_PATH`, `CARD_BY_ID`, `siblingCards()` for distractors and the `HINT_COST` / `XP_PER_CORRECT` / `DEFAULT_PASS_SCORE` constants. Content, not code: adding a lesson needs no UI change. |
| `src/lib/quiz.ts` | The question generator. Seeded `mulberry32` RNG + FNV-style string hash keyed by `lessonId:attempt`, romanisation matching (`normalizeRoman`, `isRomanAccepted`), distractor selection and `buildSession(lesson, attempt)` which returns an ordered list of questions (8 types) plus match rounds. |
| `src/lib/engine.ts` | Server-only domain rules: `ensureProfile`, `loadState`, `recordLessonResult`, `recordReview`, `spendHint`, `patchProfile`, `resetProgress`, `leaderboard`, `buildAchievements`. This is the only place XP, pass/fail, unlocks and streaks change. |
| `src/db/` | `schema.ts` (four tables) and `index.ts` (a pooled Drizzle client, cached on `globalThis` outside production). |
| `src/lib/store.tsx` | React context: loads `/api/state` on mount, exposes `submitLesson`, `buyHint`, `setTheme`, `saveProfile`, `reset`, and applies the theme. |
| `src/components/` | `Shell` (app chrome + tab bar), `ui.tsx` (Panel, Bar, Ring, Pill, Btn, Speaker), `icons.tsx` (inline SVG set) and `LessonPlayer` (learn → practice → results state machine). |
| `src/app/*/page.tsx` | One screen per route: roadmap `/`, `/path/[pathId]`, `/learn/[lessonId]`, `/alphabet`, `/review`, `/profile`. They are thin: they read `useApp()` and render. |

## Data model

| Table | Key | Notes |
|---|---|---|
| `profiles` | unique `handle` | One row per learner. Auth-less: the server issues an `hq_handle` cookie and upserts a profile per handle. Holds XP earned/spent, hint count, correct/wrong answers, today's XP, streak and longest streak. |
| `lesson_progress` | unique (`profile_id`, `lesson_id`) | `status` (`unlocked` \| `completed`), `best_score`, `attempts`, cumulative correct/total, XP from the lesson. Cascades on profile delete. |
| `mistakes` | unique (`profile_id`, `card_id`) | The review deck: `wrong_count`, `right_since`, `mastered`. Cascades on profile delete. |
| `xp_events` | — | Append-only ledger (`answer`, `hint`, `bonus`, `reset`) so the economy is auditable rather than just a number. |

Migrations live in `web/drizzle/` and are committed; `npm run db:migrate` applies them.

## Domain rules

**XP.** One point per *un-hinted* correct answer (`XP_PER_CORRECT`). Hints are bought before a
question is answered: Small 6 XP, Coach 12 XP, Reveal 18 XP; a hint purchase is rejected when the
balance is short, is recorded in `xp_events`, and the question it unblocks earns nothing.

**Pass and unlock.** A lesson run scores `round(correct / total × 100)` and only passes at
`≥ passScore` (70 for every lesson today). Lesson order inside a path is sequential — the next
lesson opens when the previous one is completed. Paths gate themselves:

- *Essential Words* — pass the Hangul Mastery Test, or reach 70 % of *Hangul Foundations*.
- *Grammar Engine* — 4 *Essential Words* lessons completed with ≥ 70 % accuracy.
- *Real Conversations* — 3 *Grammar Engine* lessons completed with ≥ 70 % accuracy.

**Review deck.** Missing a card increments `wrong_count` and resets `right_since` to zero. Each
correct recall in a review session increments `right_since`; at 3 in a row the card is retired as
`mastered` and stops appearing. Review answers earn the same 1 XP as lesson answers.

**Streak.** Activity on the same UTC day accumulates `xp_today`; activity the day after the last
active day increments the streak; a longer gap resets it to 1 — i.e. a one-day grace window.
`longest_streak` is kept for achievements.

**Leaderboard.** Top 20 profiles ordered by net XP (`xp_earned - xp_spent`), with accuracy and the
caller's own rank.

## Determinism

Question generation is deliberately seed-driven: `hash(lessonId:attempt)` feeds a small PRNG, so
the same attempt always produces the same questions (fair retries, debuggable sessions) while a new
attempt reshuffles them. Because the generator is pure, it is unit-tested directly — see
`web/tests/quiz.test.ts`.

## Flutter client

`mobile/lib/` mirrors the same concepts by name: `data/curriculum_data.dart` (content),
`logic/quiz_engine.dart` (question generation), `logic/hangul.dart` (jamo → syllable composition via
the U+AC00 arithmetic), `state/app_state.dart` (progress, XP, unlocks, streaks, achievements,
`shared_preferences` persistence), `services/tts.dart` (Korean text-to-speech) and `screens/*`
(roadmap, path map, lesson player, alphabet chart, review, profile).

## Known trade-offs

- **Client-reported correctness.** The server owns the economy (score, XP, unlocks) but trusts the
  `correct` flag sent by the client. Signing sessions or validating answers server-side is the first
  step towards a real multiplayer build — tracked in [`ROADMAP.md`](ROADMAP.md).
- **Auth-less handles.** A cookie identifies a learner. Fine for a personal course app; a real
  account system would replace `ensureProfile` and add migrations for credentials.
- **Hint state is a UI trigger.** The lesson player reacts to hint presses through effects; the
  refactor to an event-driven question component is on the roadmap, and the ESLint rule is scoped
  down (with a comment) until then.
