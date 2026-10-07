import {
  type Card,
  type Lesson,
  siblingCards,
} from "@/lib/curriculum";

export type QuestionType =
  | "mc-ko-en"
  | "mc-en-ko"
  | "mc-rom"
  | "listen"
  | "type-rom"
  | "builder"
  | "match"
  | "order";

export type Option = { key: string; text: string; correct: boolean };

export type Question = {
  id: string;
  cardId: string;
  type: QuestionType;
  instruction: string;
  prompt: string;
  promptIsKorean: boolean;
  rom: string;
  en: string;
  note?: string;
  options?: Option[];
  jamoChoices?: Option[];
  targetJamo?: string[];
  order?: string[];
  pairs?: { ko: string; en: string }[];
  /** the Korean word hidden behind a listening question, revealed in feedback */
  reveal?: string;
};

/* deterministic RNG so a retry produces a fair, reproducible session */
function mulberry32(seed: number) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function hash(str: string) {
  let h = 2166136261;
  for (let i = 0; i < str.length; i++) {
    h ^= str.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return h >>> 0;
}

function shuffle<T>(arr: T[], rnd: () => number): T[] {
  const out = [...arr];
  for (let i = out.length - 1; i > 0; i--) {
    const k = Math.floor(rnd() * (i + 1));
    [out[i], out[k]] = [out[k], out[i]];
  }
  return out;
}

function pick<T>(arr: T[], n: number, rnd: () => number): T[] {
  return shuffle(arr, rnd).slice(0, n);
}

export function normalizeRoman(input: string): string {
  return input
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]/g, "");
}

/** Loose match: ignores spaces, hyphens, apostrophes and the double-vowel 'eo' vs 'o'. */
export function isRomanAccepted(input: string, answer: string): boolean {
  const a = normalizeRoman(input);
  const b = normalizeRoman(answer);
  if (!a) return false;
  if (a === b) return true;
  // tolerate the classic beginner confusions
  const variants = new Set<string>([b]);
  variants.add(b.replace(/eo/g, "o"));
  variants.add(b.replace(/eo/g, "u"));
  variants.add(b.replace(/eu/g, "u"));
  variants.add(b.replace(/o/g, "eo"));
  return variants.has(a);
}

function buildOptions(
  card: Card,
  pool: Card[],
  field: "en" | "ko" | "rom",
  rnd: () => number,
  count = 4,
): Option[] {
  const others = pool.filter((c) => c.id !== card.id && c[field] !== card[field]);
  const wrong = pick(others, count - 1, rnd);
  const options: Option[] = [
    { key: `${card.id}-t`, text: card[field], correct: true },
    ...wrong.map((c) => ({ key: c.id, text: c[field], correct: false })),
  ];
  return shuffle(options, rnd);
}

function questionTypeFor(card: Card, mode: Lesson["mode"], rnd: () => number): QuestionType {
  if (mode === "builder" && card.jamo) return "builder";
  if (card.parts && card.parts.length > 1 && rnd() < 0.75) return "order";
  if (card.jamo && rnd() < 0.4) return "builder";

  const roll = rnd();
  if (mode === "test") {
    if (roll < 0.2) return "listen";
    if (roll < 0.4) return "mc-en-ko";
    if (roll < 0.55) return "type-rom";
    if (roll < 0.7) return "mc-rom";
    return "mc-ko-en";
  }
  if (mode === "sentences") return roll < 0.7 && card.parts ? "order" : "mc-en-ko";
  if (roll < 0.15) return "listen";
  if (roll < 0.35) return "mc-en-ko";
  if (roll < 0.5) return "mc-rom";
  if (roll < 0.62 && !card.parts) return "type-rom";
  return "mc-ko-en";
}

const INSTRUCTIONS: Record<QuestionType, string> = {
  "mc-ko-en": "What does this mean?",
  "mc-en-ko": "Choose the correct Korean.",
  "mc-rom": "How is this pronounced?",
  listen: "Listen and choose the meaning.",
  "type-rom": "Type the romanization.",
  builder: "Build the syllable block.",
  match: "Match every pair.",
  order: "Put the words in order.",
};

function makeQuestion(
  card: Card,
  pool: Card[],
  type: QuestionType,
  rnd: () => number,
  index: number,
): Question {
  const base = {
    id: `q${index}`,
    cardId: card.id,
    type,
    rom: card.rom,
    en: card.en,
    note: card.note,
  };

  switch (type) {
    case "builder": {
      const target = card.jamo ?? ["ㅇ", "ㅏ"];
      const allJamo = [
        "ㄱ", "ㄴ", "ㄷ", "ㄹ", "ㅁ", "ㅂ", "ㅅ", "ㅇ", "ㅈ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ",
        "ㅏ", "ㅑ", "ㅓ", "ㅕ", "ㅗ", "ㅛ", "ㅜ", "ㅠ", "ㅡ", "ㅣ", "ㅐ", "ㅔ",
      ];
      const decoys = pick(
        allJamo.filter((x) => !target.includes(x)),
        3,
        rnd,
      );
      const jamoChoices = shuffle(
        [
          ...target.map((t, i) => ({ key: `${card.id}-j${i}`, text: t, correct: true })),
          ...decoys.map((d, i) => ({ key: `${card.id}-d${i}`, text: d, correct: false })),
        ],
        rnd,
      );
      return {
        ...base,
        instruction: INSTRUCTIONS.builder,
        prompt: card.en,
        promptIsKorean: false,
        jamoChoices,
        targetJamo: target,
      };
    }
    case "order": {
      const parts = card.parts && card.parts.length > 1 ? card.parts : [card.ko];
      return {
        ...base,
        instruction: INSTRUCTIONS.order,
        prompt: card.en,
        promptIsKorean: false,
        order: parts,
      };
    }
    case "mc-en-ko":
      return {
        ...base,
        instruction: INSTRUCTIONS["mc-en-ko"],
        prompt: card.en,
        promptIsKorean: false,
        options: buildOptions(card, pool, "ko", rnd),
      };
    case "mc-rom":
      return {
        ...base,
        instruction: INSTRUCTIONS["mc-rom"],
        prompt: card.ko,
        promptIsKorean: true,
        options: buildOptions(card, pool, "rom", rnd),
      };
    case "type-rom":
      return {
        ...base,
        instruction: INSTRUCTIONS["type-rom"],
        prompt: card.ko,
        promptIsKorean: true,
        options: undefined,
      };
    case "listen":
      return {
        ...base,
        instruction: INSTRUCTIONS.listen,
        prompt: "",
        promptIsKorean: false,
        reveal: card.ko,
        options: buildOptions(card, pool, "en", rnd),
      };
    default:
      return {
        ...base,
        instruction: INSTRUCTIONS["mc-ko-en"],
        prompt: card.ko,
        promptIsKorean: true,
        options: buildOptions(card, pool, "en", rnd),
      };
  }
}

export type Session = {
  lessonId: string;
  attempt: number;
  matchRounds: Question[];
  questions: Question[];
  totalQuestions: number;
};

/** Learn-phase card list + practice questions for one lesson run. */
export function buildSession(lesson: Lesson, attempt = 1): Session {
  const rnd = mulberry32(hash(`${lesson.id}:${attempt}`));
  const pool = siblingCards(lesson.id);
  const questions: Question[] = [];
  const matchRounds: Question[] = [];

  if (lesson.mode === "match") {
    const groups: Card[][] = [];
    for (let i = 0; i < lesson.cards.length; i += 6) {
      groups.push(lesson.cards.slice(i, i + 6));
    }
    groups.forEach((group, gi) => {
      if (group.length < 3) return;
      matchRounds.push({
        id: `m${gi}`,
        cardId: group[0].id,
        type: "match",
        instruction: INSTRUCTIONS.match,
        prompt: "",
        promptIsKorean: false,
        rom: group.map((c) => c.rom).join(" · "),
        en: group.map((c) => c.en).join(" · "),
        pairs: shuffle(group, rnd).map((c) => ({ ko: c.ko, en: c.en })),
      });
    });
  }

  const count = lesson.mode === "test" ? Math.min(14, Math.max(8, lesson.cards.length)) : Math.min(10, Math.max(6, lesson.cards.length));
  const orderedCards = shuffle(lesson.cards, rnd);
  for (let i = 0; i < count; i++) {
    const card = orderedCards[i % orderedCards.length];
    const type = questionTypeFor(card, lesson.mode, rnd);
    questions.push(makeQuestion(card, pool, type, rnd, i));
  }

  return {
    lessonId: lesson.id,
    attempt,
    matchRounds,
    questions,
    totalQuestions: questions.length + matchRounds.length,
  };
}
