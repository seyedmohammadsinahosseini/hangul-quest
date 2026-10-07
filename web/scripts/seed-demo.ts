import "dotenv/config";
import { randomUUID } from "node:crypto";
import { eq } from "drizzle-orm";

import { db, pool } from "@/db";
import { lessonProgress, mistakes, profiles, xpEvents } from "@/db/schema";
import { getLesson } from "@/lib/curriculum";

/**
 * Seeds a single, deterministic demo learner so the app can be explored (and
 * screenshotted) without playing through the whole course first.
 *
 *   npm run db:seed
 *
 * The script is idempotent: running it twice resets the same profile.
 */

const HANDLE = "demo-learner";
const DISPLAY_NAME = "Sina";

/** Lessons the demo learner has already passed, with a plausible score. */
const COMPLETED: { lessonId: string; pathId: string; score: number; attempts: number }[] = [
  // Path 1 — Hangul Foundations (finished, so the roadmap shows a green stage)
  { lessonId: "h-v1", pathId: "p-hangul", score: 100, attempts: 1 },
  { lessonId: "h-v2", pathId: "p-hangul", score: 80, attempts: 2 },
  { lessonId: "h-c1", pathId: "p-hangul", score: 100, attempts: 1 },
  { lessonId: "h-c2", pathId: "p-hangul", score: 80, attempts: 1 },
  { lessonId: "h-c3", pathId: "p-hangul", score: 80, attempts: 2 },
  { lessonId: "h-b1", pathId: "p-hangul", score: 83, attempts: 1 },
  { lessonId: "h-b2", pathId: "p-hangul", score: 80, attempts: 1 },
  { lessonId: "h-b3", pathId: "p-hangul", score: 71, attempts: 3 },
  { lessonId: "h-d1", pathId: "p-hangul", score: 80, attempts: 1 },
  { lessonId: "h-d2", pathId: "p-hangul", score: 86, attempts: 1 },
  { lessonId: "h-test", pathId: "p-hangul", score: 90, attempts: 1 },
  // Path 2 — Essential Words (5 lessons in, so Path 3 is unlocked at 70%+)
  { lessonId: "w-s1", pathId: "p-words", score: 100, attempts: 1 },
  { lessonId: "w-s2", pathId: "p-words", score: 83, attempts: 1 },
  { lessonId: "w-s3", pathId: "p-words", score: 80, attempts: 2 },
  { lessonId: "w-p1", pathId: "p-words", score: 88, attempts: 1 },
  { lessonId: "w-f1", pathId: "p-words", score: 86, attempts: 1 },
];

/** Cards still sitting in the Review Deck, ordered by how often they were missed. */
const WEAK_CARDS: { lessonId: string; index: number; wrongCount: number }[] = [
  { lessonId: "w-s3", index: 0, wrongCount: 3 },
  { lessonId: "w-s3", index: 2, wrongCount: 2 },
  { lessonId: "w-s2", index: 1, wrongCount: 2 },
  { lessonId: "w-p1", index: 3, wrongCount: 2 },
  { lessonId: "w-f1", index: 4, wrongCount: 1 },
  { lessonId: "w-f1", index: 1, wrongCount: 1 },
  { lessonId: "h-b3", index: 2, wrongCount: 1 },
  { lessonId: "h-d2", index: 5, wrongCount: 1 },
];

/** Already recalled three times in a row -> counts toward the "Comeback Kid" badge. */
const MASTERED: { lessonId: string; index: number }[] = [
  { lessonId: "h-v2", index: 0 },
  { lessonId: "h-v2", index: 3 },
  { lessonId: "h-c2", index: 1 },
  { lessonId: "h-c3", index: 4 },
  { lessonId: "h-b1", index: 1 },
  { lessonId: "h-b1", index: 4 },
  { lessonId: "h-d1", index: 2 },
  { lessonId: "w-s1", index: 0 },
  { lessonId: "w-s1", index: 2 },
  { lessonId: "w-s2", index: 4 },
];

function cardIdAt(lessonId: string, index: number): string | null {
  const lesson = getLesson(lessonId);
  const card = lesson?.cards[index];
  return card ? card.id : null;
}

function today(): string {
  return new Date().toISOString().slice(0, 10);
}

async function main() {
  const existing = await db.select({ id: profiles.id }).from(profiles).where(eq(profiles.handle, HANDLE));
  if (existing.length > 0) {
    await db.delete(profiles).where(eq(profiles.id, existing[0].id)); // cascades to progress/mistakes/events
  }

  const profileId = randomUUID();
  const xpEarned = 612;
  const xpSpent = 54;

  await db.insert(profiles).values({
    id: profileId,
    handle: HANDLE,
    displayName: DISPLAY_NAME,
    theme: "light",
    dailyGoal: 30,
    xpEarned,
    xpSpent,
    hintsUsed: 9,
    correctAnswers: 254,
    wrongAnswers: 38,
    xpToday: 34,
    streak: 6,
    longestStreak: 9,
    lastActiveDate: today(),
  });

  await db.insert(lessonProgress).values(
    COMPLETED.map((l) => {
      const lesson = getLesson(l.lessonId);
      const total = lesson ? Math.min(10, Math.max(6, lesson.cards.length)) : 10;
      const correct = Math.round((l.score / 100) * total);
      return {
        id: randomUUID(),
        profileId,
        lessonId: l.lessonId,
        pathId: l.pathId,
        status: "completed" as const,
        bestScore: l.score,
        attempts: l.attempts,
        correct,
        total,
        xpEarned: correct,
        completedAt: new Date(Date.now() - l.attempts * 86_400_000),
      };
    }),
  );

  const mistakeRows = [
    ...WEAK_CARDS.map((c) => ({ ...c, mastered: false, rightSince: 0 })),
    ...MASTERED.map((c) => ({ ...c, wrongCount: 1, mastered: true, rightSince: 3 })),
  ]
    .map((c) => {
      const cardId = cardIdAt(c.lessonId, c.index);
      if (!cardId) {
        console.warn(`! skipped ${c.lessonId}[${c.index}] — card not found`);
        return null;
      }
      return {
        id: randomUUID(),
        profileId,
        cardId,
        lessonId: c.lessonId,
        wrongCount: c.wrongCount,
        rightSince: c.rightSince,
        mastered: c.mastered,
        lastSeenAt: new Date(Date.now() - 3_600_000),
      };
    })
    .filter((row): row is NonNullable<typeof row> => row !== null);

  await db.insert(mistakes).values(mistakeRows);

  await db.insert(xpEvents).values([
    { id: randomUUID(), profileId, amount: xpEarned, kind: "answer", note: "seeded lesson answers" },
    { id: randomUUID(), profileId, amount: -xpSpent, kind: "hint", note: "seeded hint spending" },
  ]);

  console.log(
    `Seeded profile "${DISPLAY_NAME}" (handle: ${HANDLE}) — ${COMPLETED.length} lessons, ` +
      `${mistakeRows.length} review cards, ${xpEarned} XP earned.`,
  );
  console.log("Open the app with cookie hq_handle=demo-learner to see it.");
}

main()
  .catch((err) => {
    console.error(err);
    process.exitCode = 1;
  })
  .finally(() => pool.end());
