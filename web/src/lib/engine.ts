import { and, desc, eq, inArray, sql } from "drizzle-orm";
import { randomUUID } from "node:crypto";

import { db } from "@/db";
import { lessonProgress, mistakes, profiles, xpEvents } from "@/db/schema";
import type { LessonProgressRow, ProfileRow } from "@/db/schema";
import {
  ALL_LESSONS,
  CARD_BY_ID,
  HINT_COST,
  LESSON_PATH,
  PATHS,
  XP_PER_CORRECT,
  type LearningPath,
} from "@/lib/curriculum";
import type {
  Achievement,
  AppState,
  LessonState,
  PathProgress,
  ProfileView,
  ReviewCard,
} from "@/lib/types";

export type HintTier = "small" | "medium" | "large";

export type AnswerPayload = {
  cardId: string;
  correct: boolean;
  hint: HintTier | null;
};

export type LessonResultPayload = {
  lessonId: string;
  answers: AnswerPayload[];
};

const LESSON_ORDER: Record<string, string[]> = {};
for (const path of PATHS) {
  LESSON_ORDER[path.id] = path.units.flatMap((u) => u.lessons.map((l) => l.id));
}

function todayUtc(): string {
  return new Date().toISOString().slice(0, 10);
}

function yesterdayUtc(): string {
  const d = new Date(Date.now() - 86400000);
  return d.toISOString().slice(0, 10);
}

export async function ensureProfile(handle: string, displayName?: string): Promise<ProfileRow> {
  const existing = await db.select().from(profiles).where(eq(profiles.handle, handle)).limit(1);
  if (existing[0]) return existing[0];

  const row: ProfileRow = {
    id: randomUUID(),
    handle,
    displayName: displayName?.trim().slice(0, 24) || "Learner",
    theme: "light",
    dailyGoal: 10,
    xpEarned: 0,
    xpSpent: 0,
    hintsUsed: 0,
    correctAnswers: 0,
    wrongAnswers: 0,
    xpToday: 0,
    streak: 0,
    longestStreak: 0,
    lastActiveDate: null,
    createdAt: new Date(),
    updatedAt: new Date(),
  };
  await db.insert(profiles).values(row);
  return row;
}

export async function getProfileById(id: string): Promise<ProfileRow | undefined> {
  const rows = await db.select().from(profiles).where(eq(profiles.id, id)).limit(1);
  return rows[0];
}

function toProfileView(p: ProfileRow): ProfileView {
  const answered = p.correctAnswers + p.wrongAnswers;
  const balance = Math.max(0, p.xpEarned - p.xpSpent);
  return {
    id: p.id,
    displayName: p.displayName,
    theme: (p.theme === "dark" ? "dark" : "light") as "light" | "dark",
    dailyGoal: p.dailyGoal,
    xpEarned: p.xpEarned,
    xpSpent: p.xpSpent,
    xpBalance: balance,
    xpToday: p.xpToday,
    hintsUsed: p.hintsUsed,
    correctAnswers: p.correctAnswers,
    wrongAnswers: p.wrongAnswers,
    accuracy: answered === 0 ? 0 : Math.round((p.correctAnswers / answered) * 100),
    streak: p.streak,
    longestStreak: p.longestStreak,
    goalDone: p.xpToday >= p.dailyGoal,
    joinedAt: p.createdAt.toISOString(),
  };
}

function pathUnlock(path: LearningPath, index: number, rows: LessonProgressRow[]) {
  if (index === 0) return { locked: false, label: undefined, done: 1, need: 1 };

  const completedIn = (pid: string) => rows.filter((r) => r.pathId === pid && r.status === "completed");
  const accuracyIn = (pid: string) => {
    const set = rows.filter((r) => r.pathId === pid);
    const total = set.reduce((s, r) => s + r.total, 0);
    const correct = set.reduce((s, r) => s + r.correct, 0);
    return total === 0 ? 0 : Math.round((correct / total) * 100);
  };
  const percentIn = (pid: string) => {
    const total = LESSON_ORDER[pid]?.length ?? 0;
    return total === 0 ? 0 : Math.round((completedIn(pid).length / total) * 100);
  };

  if (path.id === "p-words") {
    const done = completedIn("p-hangul").some((r) => r.lessonId === "h-test") ? 1 : 0;
    const alt = percentIn("p-hangul") >= 70 ? 1 : 0;
    const ok = done === 1 || alt === 1;
    return {
      locked: !ok,
      label: "Pass the Hangul Mastery Test (or finish 70% of Hangul Foundations)",
      done: ok ? 1 : Math.min(1, percentIn("p-hangul") / 70),
      need: 1,
    };
  }

  const rule = path.unlock;
  if (!rule) {
    const prev = PATHS[index - 1];
    const ok = completedIn(prev.id).length > 0;
    return {
      locked: !ok,
      label: `Start by completing a lesson in ${prev.title}`,
      done: ok ? 1 : 0,
      need: 1,
    };
  }

  const completed = completedIn(rule.pathId).length;
  const acc = accuracyIn(rule.pathId);
  const ok = completed >= rule.completedLessons && acc >= rule.minAccuracy;
  return {
    locked: !ok,
    label: rule.label,
    done: completed,
    need: rule.completedLessons,
  };
}

function buildAchievements(
  p: ProfileRow,
  rows: LessonProgressRow[],
  masteredCount: number,
): Achievement[] {
  const completed = rows.filter((r) => r.status === "completed");
  const hangulTest = rows.find((r) => r.lessonId === "h-test");
  const vocabCompleted = completed.filter((r) => r.pathId === "p-words").length;
  const grammarCompleted = completed.filter((r) => r.pathId === "p-grammar").length;
  const perfect = completed.filter((r) => r.bestScore === 100).length;

  const mk = (
    id: string,
    title: string,
    desc: string,
    icon: string,
    progress: number,
    target: number,
  ): Achievement => ({
    id,
    title,
    desc,
    icon,
    progress: Math.min(progress, target),
    target,
    earned: progress >= target,
  });

  return [
    mk("first-steps", "First Steps", "Complete your first lesson", "🌱", completed.length, 1),
    mk("hangul-reader", "Hangul Reader", "Score 70+ on the Hangul Mastery Test", "🔤", hangulTest?.bestScore ?? 0, 70),
    mk("word-collector", "Word Collector", "Complete 6 Essential Word lessons", "📚", vocabCompleted, 6),
    mk("grammar-engine", "Grammar Engine", "Complete 3 grammar lessons", "⚙️", grammarCompleted, 3),
    mk("xp-100", "Century", "Earn 100 XP in total", "💯", p.xpEarned, 100),
    mk("streak-7", "On Fire", "Keep a 7-day streak", "🔥", p.longestStreak, 7),
    mk("flawless", "Flawless", "Finish a lesson with 100%", "✨", perfect, 1),
    mk("comeback", "Comeback Kid", "Master 10 words in the Review Deck", "🩹", masteredCount, 10),
  ];
}

export async function loadState(profile: ProfileRow): Promise<AppState> {
  const [progressRows, mistakeRows] = await Promise.all([
    db.select().from(lessonProgress).where(eq(lessonProgress.profileId, profile.id)),
    db
      .select()
      .from(mistakes)
      .where(eq(mistakes.profileId, profile.id))
      .orderBy(desc(mistakes.wrongCount))
      .limit(60),
  ]);

  const byLesson = new Map(progressRows.map((r) => [r.lessonId, r]));

  const paths: PathProgress[] = PATHS.map((path, index) => {
    const order = LESSON_ORDER[path.id] ?? [];
    const rows = order.map((id) => byLesson.get(id)).filter(Boolean) as LessonProgressRow[];
    const completed = rows.filter((r) => r.status === "completed").length;
    const totalQ = rows.reduce((s, r) => s + r.total, 0);
    const correctQ = rows.reduce((s, r) => s + r.correct, 0);
    const unlock = pathUnlock(path, index, progressRows);
    const firstAvailable = order.find((id) => {
      const i = order.indexOf(id);
      const prevDone = i === 0 ? true : byLesson.get(order[i - 1])?.status === "completed";
      return prevDone && byLesson.get(id)?.status !== "completed";
    });

    return {
      id: path.id,
      title: path.title,
      tagline: path.tagline,
      stage: path.stage,
      color: path.color,
      locked: unlock.locked,
      unlockLabel: unlock.label,
      unlockDone: Math.round(unlock.done * 10) / 10,
      unlockNeed: unlock.need,
      completedLessons: completed,
      totalLessons: order.length,
      percent: order.length ? Math.round((completed / order.length) * 100) : 0,
      accuracy: totalQ ? Math.round((correctQ / totalQ) * 100) : 0,
      firstAvailableLessonId: unlock.locked ? undefined : firstAvailable,
    };
  });

  const lessons: Record<string, LessonState> = {};
  for (const path of PATHS) {
    const order = LESSON_ORDER[path.id] ?? [];
    const pathIndex = PATHS.indexOf(path);
    const pathLocked = paths[pathIndex].locked;
    for (let i = 0; i < order.length; i++) {
      const id = order[i];
      const row = byLesson.get(id);
      const prevDone = i === 0 ? !pathLocked : byLesson.get(order[i - 1])?.status === "completed";
      const status: LessonState["status"] = row?.status === "completed"
        ? "completed"
        : prevDone && !pathLocked
          ? "available"
          : "locked";
      const lesson = ALL_LESSONS.find((l) => l.id === id)!;
      const unit = path.units.find((u) => u.lessons.some((l) => l.id === id))!;
      lessons[id] = {
        id,
        pathId: path.id,
        unitId: unit.id,
        unitTitle: unit.title,
        status,
        bestScore: row?.bestScore ?? 0,
        attempts: row?.attempts ?? 0,
      };
    }
  }

  const review: ReviewCard[] = mistakeRows
    .filter((m) => !m.mastered && CARD_BY_ID[m.cardId])
    .slice(0, 40)
    .map((m) => {
      const card = CARD_BY_ID[m.cardId];
      return {
        cardId: m.cardId,
        lessonId: m.lessonId,
        ko: card.ko,
        rom: card.rom,
        en: card.en,
        wrongCount: m.wrongCount,
        mastered: m.mastered,
      };
    });

  const masteredCount = mistakeRows.filter((m) => m.mastered).length;
  const totalLessons = ALL_LESSONS.length;
  const totalCompleted = paths.reduce((s, p) => s + p.completedLessons, 0);

  return {
    ready: true,
    profile: toProfileView(profile),
    paths,
    lessons,
    review,
    achievements: buildAchievements(profile, progressRows, masteredCount),
    overallPercent: Math.round((totalCompleted / totalLessons) * 100),
    hintCosts: { ...HINT_COST },
    xpPerCorrect: XP_PER_CORRECT,
  };
}

async function touchActivity(profile: ProfileRow, xpGained: number) {
  const today = todayUtc();
  let streak = profile.streak;
  let xpToday = profile.xpToday;

  if (profile.lastActiveDate === today) {
    xpToday += xpGained;
  } else if (profile.lastActiveDate === yesterdayUtc()) {
    streak += 1;
    xpToday = xpGained;
  } else {
    streak = 1;
    xpToday = xpGained;
  }

  const longestStreak = Math.max(profile.longestStreak, streak);
  await db
    .update(profiles)
    .set({
      streak,
      longestStreak,
      xpToday,
      lastActiveDate: today,
      xpEarned: profile.xpEarned + xpGained,
      updatedAt: new Date(),
    })
    .where(eq(profiles.id, profile.id));

  if (xpGained > 0) {
    await db.insert(xpEvents).values({
      id: randomUUID(),
      profileId: profile.id,
      amount: xpGained,
      kind: "answer",
      note: `+${xpGained} XP`,
    });
  }
}

/** Persist one finished lesson run. The server is the source of truth for XP. */
export async function recordLessonResult(profile: ProfileRow, payload: LessonResultPayload) {
  const lesson = ALL_LESSONS.find((l) => l.id === payload.lessonId);
  if (!lesson) throw new Error("unknown lesson");

  const answers = payload.answers.slice(0, 60);
  const total = answers.length;
  const correct = answers.filter((a) => a.correct).length;
  // XP: 1 per correct answer, but a hinted answer earns nothing (hints are costly).
  const xpGained = answers.filter((a) => a.correct && !a.hint).length * XP_PER_CORRECT;
  const score = total === 0 ? 0 : Math.round((correct / total) * 100);
  const passed = score >= lesson.passScore;
  const pathId = LESSON_PATH[lesson.id] ?? "p-hangul";

  const existing = await db
    .select()
    .from(lessonProgress)
    .where(and(eq(lessonProgress.profileId, profile.id), eq(lessonProgress.lessonId, lesson.id)))
    .limit(1);
  const row = existing[0];

  if (row) {
    await db
      .update(lessonProgress)
      .set({
        bestScore: Math.max(row.bestScore, score),
        attempts: row.attempts + 1,
        correct: row.correct + correct,
        total: row.total + total,
        xpEarned: row.xpEarned + xpGained,
        status: passed ? "completed" : row.status,
        completedAt: passed ? new Date() : row.completedAt,
        updatedAt: new Date(),
      })
      .where(eq(lessonProgress.id, row.id));
  } else {
    await db.insert(lessonProgress).values({
      id: randomUUID(),
      profileId: profile.id,
      lessonId: lesson.id,
      pathId,
      status: passed ? "completed" : "unlocked",
      bestScore: score,
      attempts: 1,
      correct,
      total,
      xpEarned: xpGained,
      completedAt: passed ? new Date() : null,
      updatedAt: new Date(),
    });
  }

  // mistakes / review deck bookkeeping
  const wrongCards = answers.filter((a) => !a.correct).map((a) => a.cardId);
  const rightCards = answers.filter((a) => a.correct).map((a) => a.cardId);

  if (wrongCards.length) {
    const existingMistakes = await db
      .select()
      .from(mistakes)
      .where(
        and(
          eq(mistakes.profileId, profile.id),
          inArray(mistakes.cardId, Array.from(new Set(wrongCards))),
        ),
      );
    const map = new Map(existingMistakes.map((m) => [m.cardId, m]));
    const counts = new Map<string, number>();
    for (const c of wrongCards) counts.set(c, (counts.get(c) ?? 0) + 1);

    for (const [cardId, add] of counts) {
      const found = map.get(cardId);
      if (found) {
        await db
          .update(mistakes)
          .set({
            wrongCount: found.wrongCount + add,
            rightSince: 0,
            mastered: false,
            lastSeenAt: new Date(),
          })
          .where(eq(mistakes.id, found.id));
      } else {
        await db.insert(mistakes).values({
          id: randomUUID(),
          profileId: profile.id,
          cardId,
          lessonId: lesson.id,
          wrongCount: add,
          rightSince: 0,
          mastered: false,
          lastSeenAt: new Date(),
        });
      }
    }
  }

  if (rightCards.length) {
    const found = await db
      .select()
      .from(mistakes)
      .where(
        and(
          eq(mistakes.profileId, profile.id),
          inArray(mistakes.cardId, Array.from(new Set(rightCards))),
        ),
      );
    for (const m of found) {
      const next = m.rightSince + 1;
      await db
        .update(mistakes)
        .set({ rightSince: next, mastered: next >= 3, lastSeenAt: new Date() })
        .where(eq(mistakes.id, m.id));
    }
  }

  await db
    .update(profiles)
    .set({
      correctAnswers: profile.correctAnswers + correct,
      wrongAnswers: profile.wrongAnswers + (total - correct),
      updatedAt: new Date(),
    })
    .where(eq(profiles.id, profile.id));

  await touchActivity(profile, xpGained);

  const refreshed = (await getProfileById(profile.id))!;
  return {
    score,
    passed,
    correct,
    total,
    xpGained,
    state: await loadState(refreshed),
  };
}

export async function spendHint(profile: ProfileRow, tier: HintTier) {
  const cost = HINT_COST[tier];
  const balance = profile.xpEarned - profile.xpSpent;
  if (balance < cost) {
    return { ok: false as const, error: `You need ${cost} XP for this hint (balance ${balance}).`, cost };
  }
  await db
    .update(profiles)
    .set({
      xpSpent: profile.xpSpent + cost,
      hintsUsed: profile.hintsUsed + 1,
      updatedAt: new Date(),
    })
    .where(eq(profiles.id, profile.id));
  await db.insert(xpEvents).values({
    id: randomUUID(),
    profileId: profile.id,
    amount: -cost,
    kind: "hint",
    note: `${tier} hint`,
  });
  const refreshed = (await getProfileById(profile.id))!;
  return { ok: true as const, cost, state: await loadState(refreshed) };
}

export async function patchProfile(
  profile: ProfileRow,
  patch: { displayName?: string; theme?: "light" | "dark"; dailyGoal?: number },
) {
  const next: Partial<ProfileRow> = { updatedAt: new Date() };
  if (patch.displayName?.trim()) next.displayName = patch.displayName.trim().slice(0, 24);
  if (patch.theme === "light" || patch.theme === "dark") next.theme = patch.theme;
  if (typeof patch.dailyGoal === "number") {
    next.dailyGoal = Math.max(5, Math.min(50, Math.round(patch.dailyGoal)));
  }
  await db.update(profiles).set(next).where(eq(profiles.id, profile.id));
  const refreshed = (await getProfileById(profile.id))!;
  return loadState(refreshed);
}

/** Review Deck drill: no lesson progress, but it still pays XP and heals mistakes. */
export async function recordReview(
  profile: ProfileRow,
  entries: { cardId: string; correct: boolean }[],
) {
  const clean = entries.filter((e) => CARD_BY_ID[e.cardId]).slice(0, 60);
  if (!clean.length) return loadState(profile);

  const correct = clean.filter((e) => e.correct).length;
  const xpGained = correct * XP_PER_CORRECT;

  for (const entry of clean) {
    const found = await db
      .select()
      .from(mistakes)
      .where(and(eq(mistakes.profileId, profile.id), eq(mistakes.cardId, entry.cardId)))
      .limit(1);
    const row = found[0];
    if (entry.correct) {
      const next = (row?.rightSince ?? 0) + 1;
      if (row) {
        await db
          .update(mistakes)
          .set({ rightSince: next, mastered: next >= 3, lastSeenAt: new Date() })
          .where(eq(mistakes.id, row.id));
      } else {
        await db.insert(mistakes).values({
          id: randomUUID(),
          profileId: profile.id,
          cardId: entry.cardId,
          lessonId: "",
          wrongCount: 0,
          rightSince: next,
          mastered: next >= 3,
          lastSeenAt: new Date(),
        });
      }
    } else if (row) {
      await db
        .update(mistakes)
        .set({
          wrongCount: row.wrongCount + 1,
          rightSince: 0,
          mastered: false,
          lastSeenAt: new Date(),
        })
        .where(eq(mistakes.id, row.id));
    } else {
      await db.insert(mistakes).values({
        id: randomUUID(),
        profileId: profile.id,
        cardId: entry.cardId,
        lessonId: "",
        wrongCount: 1,
        rightSince: 0,
        mastered: false,
        lastSeenAt: new Date(),
      });
    }
  }

  await db
    .update(profiles)
    .set({
      correctAnswers: profile.correctAnswers + correct,
      wrongAnswers: profile.wrongAnswers + (clean.length - correct),
      updatedAt: new Date(),
    })
    .where(eq(profiles.id, profile.id));

  await touchActivity(profile, xpGained);
  const refreshed = (await getProfileById(profile.id))!;
  return loadState(refreshed);
}

export async function resetProgress(profile: ProfileRow) {
  await db.delete(lessonProgress).where(eq(lessonProgress.profileId, profile.id));
  await db.delete(mistakes).where(eq(mistakes.profileId, profile.id));
  await db.delete(xpEvents).where(eq(xpEvents.profileId, profile.id));
  await db
    .update(profiles)
    .set({
      xpEarned: 0,
      xpSpent: 0,
      hintsUsed: 0,
      correctAnswers: 0,
      wrongAnswers: 0,
      xpToday: 0,
      streak: 0,
      longestStreak: 0,
      lastActiveDate: null,
      updatedAt: new Date(),
    })
    .where(eq(profiles.id, profile.id));
  const refreshed = (await getProfileById(profile.id))!;
  return loadState(refreshed);
}

export async function leaderboard() {
  const rows = await db
    .select({
      displayName: profiles.displayName,
      xpEarned: profiles.xpEarned,
      streak: profiles.streak,
      correctAnswers: profiles.correctAnswers,
      wrongAnswers: profiles.wrongAnswers,
      id: profiles.id,
    })
    .from(profiles)
    .orderBy(desc(sql`${profiles.xpEarned} - ${profiles.xpSpent}`))
    .limit(20);
  return rows;
}
