# Roadmap

Working plan for the next month, written so that progress is visible from the commit history:
every item below is a real, runnable increment. Dates are targets, not promises — the point is
that each week ends with something a reviewer can open and try.

**Guiding rule:** a small change that works, is tested and is documented beats a large change that
is half-finished.

## Week 1 — hardening what exists

- [ ] Server-side answer validation: the client submits card ids only, the server rebuilds the
      session from `lessonId:attempt` and judges correctness (`web/src/lib/quiz.ts` is already pure,
      so this is mostly a new `engine.ts` entry point).
- [ ] Playwright end-to-end smoke suite: roadmap → lesson → results → review, run in CI against a
      throwaway Postgres service container.
- [ ] Raise hint-effect refactors: move hint presses into the question component so
      `react-hooks/set-state-in-effect` can be re-enabled project-wide.
- [ ] Fill in the reference table on `/alphabet` with the remaining compound vowels and batchim.

## Week 2 — depth and polish

- [ ] Real spaced repetition: replace the fixed "three correct recalls" rule with an SM-2 style
      scheduler (intervals per card, stored in `mistakes.next_due_at`).
- [ ] Per-card analytics on the profile page: accuracy heat map per unit, hardest cards.
- [ ] Accessibility pass: focus rings, `aria-live` on quiz feedback, screen-reader labels on the
      syllable builder, reduced-motion support.
- [ ] Offline-first web: service worker + IndexedDB queue for lesson submissions.

## Week 3 — the mobile client

- [ ] Flutter widget tests for the quiz engine, unlock rules and the mastery calculation.
- [ ] Optional cloud sync: `AppState` talks to `/api/action` when a handle is configured, falling
      back to `shared_preferences` when offline (the seam already exists).
- [ ] Screenshots of the Android build in `docs/screenshots/` next to the web ones.
- [ ] CI job that runs `flutter analyze` and `flutter test`.

## Week 4 — presentation and review

- [ ] Deploy the web app (see [`DEPLOYMENT.md`](DEPLOYMENT.md)) and link the live demo in the repo
      description and README.
- [ ] Write `docs/CURRICULUM.md`: how the 39 lessons were sequenced, the mastery rule and the hint
      economy, with the reasoning behind the numbers.
- [ ] Record a 60–90 second screen capture of a full lesson and embed it in the README.
- [ ] Reviewer pass: read every file as if seeing it for the first time, delete anything unused,
      and make sure the README claims match the code.

## Definition of done (for any item)

1. The change is implemented and runs locally without manual fixes.
2. Tests cover the new logic, or the PR explains why they cannot.
3. `npm run lint && npm run typecheck && npm run test && npm run build` is green.
4. Documentation (README, ARCHITECTURE or the file's own comments) matches what changed.

## Commit conventions

Short imperative subject lines with a type prefix, one idea per commit:

```
feat(web): validate lesson answers on the server
fix(web): keep the results screen after a submitted attempt
test(web): cover romanisation matching edge cases
docs: describe the hint economy
chore(ci): cache npm dependencies
```

## Before sharing the link

- [ ] CI is green on the default branch.
- [ ] `README.md` matches the code (counts, commands, screenshots).
- [ ] No secrets in the working tree or history (`git log -p -- .env` must be empty).
- [ ] Repository description and topics are filled in on GitHub.
- [ ] The live demo link works from a phone, not just from your laptop.
