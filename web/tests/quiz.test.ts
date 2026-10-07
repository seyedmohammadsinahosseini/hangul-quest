import { describe, expect, it } from "vitest";

import {
  CARD_BY_ID,
  PATHS,
  getLesson,
  siblingCards,
  type Lesson,
} from "@/lib/curriculum";
import { buildSession, isRomanAccepted, normalizeRoman } from "@/lib/quiz";

function lesson(id: string): Lesson {
  const found = getLesson(id);
  if (!found) throw new Error(`lesson ${id} is missing from the curriculum`);
  return found;
}

describe("normalizeRoman", () => {
  it("lowercases, strips accents and punctuation", () => {
    expect(normalizeRoman("  Yeo! ")).toBe("yeo");
    expect(normalizeRoman("An-nyeong")).toBe("annyeong");
    expect(normalizeRoman("")).toBe("");
  });
});

describe("isRomanAccepted", () => {
  it("accepts an exact answer regardless of casing and spacing", () => {
    expect(isRomanAccepted("annyeong", "annyeong")).toBe(true);
    expect(isRomanAccepted("An Nyeong", "annyeong")).toBe(true);
  });

  it("tolerates the beginner eo/o and eu/u confusions", () => {
    expect(isRomanAccepted("yo", "yeo")).toBe(true);
    expect(isRomanAccepted("yu", "yeo")).toBe(true);
    expect(isRomanAccepted("u", "eu")).toBe(true);
    expect(isRomanAccepted("o", "eo")).toBe(true);
  });

  it("rejects empty input and genuinely different answers", () => {
    expect(isRomanAccepted("", "yeo")).toBe(false);
    expect(isRomanAccepted("   ", "yeo")).toBe(false);
    expect(isRomanAccepted("gamsa", "annyeong")).toBe(false);
  });
});

describe("curriculum", () => {
  it("has four gated paths with unique lesson and card ids", () => {
    expect(PATHS.map((p) => p.id)).toEqual(["p-hangul", "p-words", "p-grammar", "p-talk"]);
    expect(PATHS[2].unlock?.completedLessons).toBe(4);
    expect(PATHS[3].unlock?.completedLessons).toBe(3);

    const lessonIds = PATHS.flatMap((p) => p.units.flatMap((u) => u.lessons.map((l) => l.id)));
    expect(new Set(lessonIds).size).toBe(lessonIds.length);

    const cardIds = PATHS.flatMap((p) =>
      p.units.flatMap((u) => u.lessons.flatMap((l) => l.cards.map((c) => c.id))),
    );
    expect(new Set(cardIds).size).toBe(cardIds.length);
    expect(cardIds.length).toBeGreaterThan(200);
  });

  it("keeps every lesson pass mark at the documented 70%", () => {
    for (const path of PATHS) {
      for (const unit of path.units) {
        for (const l of unit.lessons) expect(l.passScore).toBe(70);
      }
    }
  });

  it("exposes sibling cards for distractor generation", () => {
    const lessonA = lesson("h-v1");
    const siblings = siblingCards(lessonA.id);
    // distractors are drawn from the whole unit (and fall back to the full course)
    expect(siblings.length).toBeGreaterThanOrEqual(lessonA.cards.length);
    expect(siblings).toContainEqual(lessonA.cards[0]);
    expect(siblings.every((c) => CARD_BY_ID[c.id])).toBe(true);
  });
});

describe("buildSession", () => {
  it("is deterministic for the same lesson and attempt", () => {
    const a = buildSession(lesson("w-p2"), 1);
    const b = buildSession(lesson("w-p2"), 1);
    expect(a.questions.map((q) => [q.id, q.type, q.prompt])).toEqual(
      b.questions.map((q) => [q.id, q.type, q.prompt]),
    );
  });

  it("re-seeds the session between attempts", () => {
    const first = buildSession(lesson("w-p2"), 1);
    const retry = buildSession(lesson("w-p2"), 2);
    expect(first.questions.map((q) => q.prompt)).not.toEqual(retry.questions.map((q) => q.prompt));
  });

  it("keeps the question count inside the documented range", () => {
    for (const id of ["h-v1", "w-p1", "h-test", "g-b1"]) {
      const session = buildSession(lesson(id), 1);
      const isTest = lesson(id).mode === "test";
      expect(session.questions.length).toBeGreaterThanOrEqual(6);
      expect(session.questions.length).toBeLessThanOrEqual(isTest ? 14 : 10);
    }
  });

  it("produces 4-option multiple choice questions with exactly one correct answer", () => {
    const session = buildSession(lesson("h-c1"), 1);
    const mc = session.questions.filter((q) => q.type === "mc-ko-en" || q.type === "mc-en-ko");
    expect(mc.length).toBeGreaterThan(0);
    for (const q of mc) {
      expect(q.options).toHaveLength(4);
      expect(q.options?.filter((o) => o.correct)).toHaveLength(1);
    }
  });

  it("builds match rounds in groups of six for match lessons", () => {
    const session = buildSession(lesson("w-f2"), 1);
    expect(session.matchRounds.length).toBeGreaterThan(0);
    for (const round of session.matchRounds) expect(round.pairs?.length).toBeGreaterThanOrEqual(3);
  });

  it("asks builder questions when a lesson is in builder mode", () => {
    const session = buildSession(lesson("h-b1"), 1);
    const builder = session.questions.filter((q) => q.type === "builder");
    expect(builder.length).toBeGreaterThan(0);
    for (const q of builder) expect(q.targetJamo?.length).toBeGreaterThan(0);
  });
});
