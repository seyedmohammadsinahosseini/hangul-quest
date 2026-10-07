"use client";

import Link from "next/link";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";

import {
  IconArrowLeft,
  IconBolt,
  IconCheck,
  IconPlay,
  IconSparkle,
  IconVolume,
  IconX,
} from "@/components/icons";
import { Bar, Btn, Panel, Pill, Ring, Speaker } from "@/components/ui";
import { ALL_LESSONS, getLesson, type Card, type Lesson } from "@/lib/curriculum";
import { buildSession, isRomanAccepted, type Question } from "@/lib/quiz";
import { speak, useApp, useKoreanVoice, type HintTier, type LessonAnswer } from "@/lib/store";

type Phase = "learn" | "practice" | "results";

const INITIALS = ["ㄱ","ㄲ","ㄴ","ㄷ","ㄸ","ㄹ","ㅁ","ㅂ","ㅃ","ㅅ","ㅆ","ㅇ","ㅈ","ㅉ","ㅊ","ㅋ","ㅌ","ㅍ","ㅎ"];
const MEDIALS = ["ㅏ","ㅐ","ㅑ","ㅒ","ㅓ","ㅔ","ㅕ","ㅖ","ㅗ","ㅘ","ㅙ","ㅚ","ㅛ","ㅜ","ㅝ","ㅞ","ㅟ","ㅠ","ㅡ","ㅢ","ㅣ"];
const FINALS = ["","ㄱ","ㄲ","ㄳ","ㄴ","ㄵ","ㄶ","ㄷ","ㄹ","ㄺ","ㄻ","ㄼ","ㄽ","ㄾ","ㄿ","ㅀ","ㅁ","ㅂ","ㅄ","ㅅ","ㅆ","ㅇ","ㅈ","ㅊ","ㅋ","ㅌ","ㅍ","ㅎ"];

/** Live-compose jamo into a real Hangul syllable block (U+AC00 maths). */
function composeSyllable(pieces: string[]): string {
  const i = INITIALS.indexOf(pieces[0] ?? "");
  const m = MEDIALS.indexOf(pieces[1] ?? "");
  if (i < 0 || m < 0) return pieces.join("");
  const f = pieces[2] ? FINALS.indexOf(pieces[2]) : 0;
  if (pieces[2] && f < 0) return pieces.join("");
  return String.fromCharCode(0xac00 + (i * 21 + m) * 28 + Math.max(0, f));
}

function shuffle<T>(arr: T[]): T[] {
  const out = [...arr];
  for (let i = out.length - 1; i > 0; i--) {
    const k = Math.floor(Math.random() * (i + 1));
    [out[i], out[k]] = [out[k], out[i]];
  }
  return out;
}

export function LessonPlayer({ lesson }: { lesson: Lesson }) {
  const { state, buyHint, submitLesson } = useApp();
  const [attempt, setAttempt] = useState(1);
  const session = useMemo(() => buildSession(lesson, attempt), [lesson, attempt]);
  const questions = useMemo(
    () => [...session.matchRounds, ...session.questions],
    [session],
  );

  const isTest = lesson.mode === "test";
  const [phase, setPhase] = useState<Phase>(isTest ? "practice" : "learn");
  const [learnIndex, setLearnIndex] = useState(0);
  const [revealLearn, setRevealLearn] = useState(false);
  const [qIndex, setQIndex] = useState(0);
  const [answers, setAnswers] = useState<LessonAnswer[]>([]);
  const [hints, setHints] = useState<{ small: boolean; medium: boolean; large: boolean }>({
    small: false,
    medium: false,
    large: false,
  });
  const [busy, setBusy] = useState(false);
  const [toast, setToast] = useState<string | null>(null);
  const [result, setResult] = useState<{
    score: number;
    passed: boolean;
    correct: number;
    total: number;
    xpGained: number;
  } | null>(null);

  const question = questions[qIndex];
  const xpBalance = state?.profile.xpBalance ?? 0;

  const resetHints = () => setHints({ small: false, medium: false, large: false });

  const flash = (msg: string) => {
    setToast(msg);
    window.setTimeout(() => setToast(null), 1200);
  };

  const finish = useCallback(
    async (finalAnswers: LessonAnswer[]) => {
      setBusy(true);
      try {
        const res = await submitLesson(lesson.id, finalAnswers);
        setResult(res);
        setPhase("results");
      } catch (e) {
        flash(e instanceof Error ? e.message : "Could not save your run");
      } finally {
        setBusy(false);
      }
    },
    [lesson.id, submitLesson],
  );

  const recordAnswer = (correct: boolean, hint: HintTier | null) => {
    const entry: LessonAnswer = { cardId: question.cardId, correct, hint };
    const next = [...answers, entry];
    setAnswers(next);
    return next;
  };

  const nextQuestion = (finalAnswers?: LessonAnswer[]) => {
    const list = finalAnswers ?? answers;
    if (qIndex + 1 >= questions.length) {
      void finish(list);
      return;
    }
    setQIndex((i) => i + 1);
    resetHints();
  };

  const useHint = async (tier: HintTier) => {
    const cost = state?.hintCosts[tier] ?? 6;
    if (xpBalance < cost) {
      flash(`You need ${cost} XP for this hint`);
      return;
    }
    setBusy(true);
    const res = await buyHint(tier);
    setBusy(false);
    if (!res.ok) {
      flash(res.error ?? "Could not buy hint");
      return;
    }
    setHints((h) => ({ ...h, [tier]: true }));
    flash(`-${cost} XP · hint unlocked`);
  };

  const retry = () => {
    setAttempt((a) => a + 1);
    setAnswers([]);
    setQIndex(0);
    setLearnIndex(0);
    setResult(null);
    resetHints();
    setPhase(isTest ? "practice" : "learn");
  };

  if (phase === "learn") {
    return (
      <LearnPhase
        lesson={lesson}
        index={learnIndex}
        reveal={revealLearn}
        onReveal={() => setRevealLearn(true)}
        onNext={() => {
          setRevealLearn(false);
          if (learnIndex + 1 >= lesson.cards.length) setPhase("practice");
          else setLearnIndex((i) => i + 1);
        }}
        onBack={() => setLearnIndex((i) => Math.max(0, i - 1))}
        onSkip={() => setPhase("practice")}
        onQuit={() => window.history.back()}
      />
    );
  }

  if (phase === "results" && result) {
    const order = ALL_LESSONS.map((l) => l.id);
    const startIdx = order.indexOf(lesson.id);
    const nextLessonId = order
      .slice(startIdx + 1)
      .find((id) => (state?.lessons[id]?.status ?? "locked") !== "locked");
    return (
      <ResultsPhase
        lesson={lesson}
        result={result}
        answers={answers}
        busy={busy}
        nextLessonId={nextLessonId}
        onRetry={retry}
      />
    );
  }

  if (!question) {
    return (
      <Panel className="p-6 text-center">
        <p className="text-sm text-muted">Nothing to practise here yet.</p>
        <Link href="/" className="mt-3 inline-block">
          <Btn>Back to roadmap</Btn>
        </Link>
      </Panel>
    );
  }

  const progress = (qIndex / questions.length) * 100;

  return (
    <div className="space-y-3">
      {/* HUD */}
      <div className="flex items-center gap-3">
        <button
          type="button"
          onClick={() => window.history.back()}
          aria-label="Quit lesson"
          className="flex h-9 w-9 items-center justify-center rounded-full border border-line bg-surface text-muted transition hover:text-fg"
        >
          <IconX className="h-4 w-4" />
        </button>
        <Bar value={progress} className="flex-1" />
        <span className="text-xs font-black text-muted">
          {qIndex + 1}/{questions.length}
        </span>
        <span className="inline-flex items-center gap-1 rounded-full border border-line bg-surface px-2.5 py-1.5 text-xs font-black text-brand">
          <IconBolt className="h-3.5 w-3.5" />
          {xpBalance}
        </span>
      </div>

      <QuestionView
        key={question.id}
        question={question}
        hints={hints}
        onAnswered={recordAnswer}
        onNext={() => nextQuestion()}
        busy={busy}
        xpBalance={xpBalance}
        onHint={useHint}
        hintCosts={state?.hintCosts ?? { small: 6, medium: 12, large: 18 }}
        toast={toast}
      />
    </div>
  );
}



/* ------------------------------------------------------------------ */
/* Learn phase                                                         */
/* ------------------------------------------------------------------ */

function LearnPhase({
  lesson,
  index,
  reveal,
  onReveal,
  onNext,
  onBack,
  onSkip,
  onQuit,
}: {
  lesson: Lesson;
  index: number;
  reveal: boolean;
  onReveal: () => void;
  onNext: () => void;
  onBack: () => void;
  onSkip: () => void;
  onQuit: () => void;
}) {
  const card = lesson.cards[index];
  useEffect(() => {
    if (card) speak(card.ko);
  }, [card]);

  if (!card) return null;

  return (
    <div className="space-y-3">
      <div className="flex items-center gap-3">
        <button
          type="button"
          onClick={onQuit}
          aria-label="Quit lesson"
          className="flex h-9 w-9 items-center justify-center rounded-full border border-line bg-surface text-muted"
        >
          <IconX className="h-4 w-4" />
        </button>
        <Bar value={((index + 1) / lesson.cards.length) * 100} className="flex-1" color="var(--good)" />
        <span className="text-xs font-black text-muted">
          {index + 1}/{lesson.cards.length}
        </span>
      </div>

      <Panel className="anim-rise overflow-hidden p-5">
        <p className="text-center text-[11px] font-black uppercase tracking-[0.18em] text-muted">
          New card · {lesson.title}
        </p>
        <div className="mt-4 flex flex-col items-center gap-3">
          <div className="hangul text-[64px] font-bold leading-none text-fg">{card.ko}</div>
          <Speaker text={card.ko} size="lg" />
          <button
            type="button"
            onClick={onReveal}
            className="rounded-2xl border border-dashed border-line bg-surface2 px-4 py-2 text-center transition hover:border-brand"
          >
            {reveal ? (
              <>
                <span className="block text-lg font-extrabold text-brand">{card.rom}</span>
                <span className="block text-sm font-semibold text-fg">{card.en}</span>
              </>
            ) : (
              <span className="text-sm font-bold text-muted">Tap to reveal meaning</span>
            )}
          </button>
          {card.jamo ? (
            <div className="flex items-center gap-1.5 text-sm font-bold text-muted">
              {card.jamo.map((piece, i) => (
                <span key={i} className="hangul rounded-lg bg-surface2 px-2 py-1 text-fg">
                  {piece}
                </span>
              ))}
            </div>
          ) : null}
          {card.note ? <p className="max-w-[38ch] text-center text-xs text-muted">{card.note}</p> : null}
          {card.example ? (
            <div className="w-full rounded-2xl bg-surface2 p-3">
              <div className="flex items-start justify-between gap-2">
                <div>
                  <p className="hangul text-sm font-bold">{card.example.ko}</p>
                  <p className="text-[11px] text-muted">{card.example.rom}</p>
                  <p className="mt-1 text-xs font-semibold text-fg">{card.example.en}</p>
                </div>
                <Speaker text={card.example.ko} size="sm" />
              </div>
            </div>
          ) : null}
        </div>
      </Panel>

      <div className="flex gap-2">
        <Btn variant="soft" onClick={onBack} disabled={index === 0}>
          <IconArrowLeft className="h-4 w-4" /> Back
        </Btn>
        <Btn className="flex-1" onClick={onNext}>
          {index + 1 === lesson.cards.length ? "Start the quiz" : "Next card"}
        </Btn>
      </div>
      <button type="button" onClick={onSkip} className="w-full text-center text-xs font-bold text-muted hover:text-fg">
        I know these — skip to the quiz
      </button>
    </div>
  );
}

/* ------------------------------------------------------------------ */
/* Question view                                                       */
/* ------------------------------------------------------------------ */

function QuestionView({
  question,
  hints,
  onAnswered,
  onNext,
  busy,
  xpBalance,
  onHint,
  hintCosts,
  toast,
}: {
  question: Question;
  hints: { small: boolean; medium: boolean; large: boolean };
  onAnswered: (correct: boolean, hint: HintTier | null) => LessonAnswer[];
  onNext: (answers?: LessonAnswer[]) => void;
  busy: boolean;
  xpBalance: number;
  onHint: (tier: HintTier) => void;
  hintCosts: { small: number; medium: number; large: number };
  toast: string | null;
}) {
  const [answered, setAnswered] = useState(false);
  const [correct, setCorrect] = useState(false);
  const [shake, setShake] = useState(false);
  const [xpPop, setXpPop] = useState(false);
  const usedHint: HintTier | null = hints.large ? "large" : hints.medium ? "medium" : hints.small ? "small" : null;

  const settle = (isCorrect: boolean, list?: LessonAnswer[]) => {
    setCorrect(isCorrect);
    setAnswered(true);
    if (isCorrect) {
      setXpPop(true);
      window.setTimeout(() => setXpPop(false), 900);
    } else {
      setShake(true);
      window.setTimeout(() => setShake(false), 450);
    }
    const next = list ?? onAnswered(isCorrect, usedHint);
    if (question.type === "listen" && question.reveal) speak(question.reveal);
    return next;
  };

  return (
    <>
      <Panel className={`p-4 ${shake ? "anim-shake" : "anim-rise"}`}>
        <div className="flex items-start justify-between gap-2">
          <p className="text-[11px] font-black uppercase tracking-[0.16em] text-brand">
            {question.instruction}
          </p>
          {xpPop ? <span className="anim-xp text-xs font-black text-good">+1 XP</span> : null}
        </div>

        {question.type === "match" ? (
          <MatchRound question={question} onSettle={settle} answered={answered} />
        ) : question.type === "builder" ? (
          <BuilderRound question={question} onSettle={settle} answered={answered} hints={hints} />
        ) : question.type === "order" ? (
          <OrderRound question={question} onSettle={settle} answered={answered} hints={hints} />
        ) : question.type === "type-rom" ? (
          <TypeRound question={question} onSettle={settle} answered={answered} hints={hints} />
        ) : (
          <ChoiceRound question={question} onSettle={settle} answered={answered} hints={hints} />
        )}

        {hints.medium ? (
          <div className="mt-3 rounded-2xl border border-brand/30 bg-brandsoft/50 p-3">
            <p className="text-[10px] font-black uppercase tracking-wide text-brand">Coach hint</p>
            <p className="hangul mt-1 text-sm font-bold">{question.rom}</p>
            {question.note ? <p className="mt-0.5 text-xs text-muted">{question.note}</p> : null}
          </div>
        ) : null}

        {answered ? (
          <div
            className={`mt-3 rounded-2xl border p-3 ${
              correct ? "border-good/40 bg-goodsoft/60" : "border-bad/40 bg-badsoft/60"
            }`}
          >
            <div className="flex items-center gap-2">
              <span
                className={`flex h-6 w-6 items-center justify-center rounded-full text-white ${
                  correct ? "bg-good" : "bg-bad"
                }`}
              >
                {correct ? <IconCheck className="h-3.5 w-3.5" /> : <IconX className="h-3.5 w-3.5" />}
              </span>
              <span className="text-sm font-extrabold">
                {correct ? "Correct!" : `Answer: ${question.type === "order" ? question.order?.join(" ") : question.prompt || question.en}`}
              </span>
            </div>
            <div className="mt-2 flex items-start justify-between gap-2">
              <div>
                <p className="hangul text-base font-bold">{answerText(question)}</p>
                <p className="text-xs text-muted">
                  {question.rom} · {question.en}
                </p>
                {question.note ? <p className="mt-1 text-[11px] text-muted">{question.note}</p> : null}
              </div>
              {answerText(question) ? <Speaker text={answerText(question)} /> : null}
            </div>
            {usedHint ? (
              <p className="mt-2 text-[11px] font-bold text-warn">
                Hint used — this question pays no XP.
              </p>
            ) : null}
          </div>
        ) : null}

        {answered ? (
          <Btn block size="lg" className="mt-3" onClick={() => onNext()} disabled={busy}>
            {busy ? "Saving…" : "Continue"}
          </Btn>
        ) : null}
      </Panel>

      {!answered ? (
        <HintBar
          xpBalance={xpBalance}
          costs={hintCosts}
          hints={hints}
          onHint={onHint}
          disabled={busy}
        />
      ) : null}

      {toast ? (
        <div className="pointer-events-none fixed inset-x-0 bottom-24 z-40 flex justify-center px-4">
          <span className="anim-pop rounded-full bg-fg px-4 py-2 text-xs font-bold text-bg shadow-card">
            {toast}
          </span>
        </div>
      ) : null}
    </>
  );
}

function answerText(q: Question): string {
  if (q.type === "order") return q.order?.join(" ") ?? q.en;
  if (q.type === "builder") return composeSyllable(q.targetJamo ?? []);
  if (q.type === "listen") return q.reveal ?? q.en;
  if (q.type === "mc-en-ko") return q.options?.find((o) => o.correct)?.text ?? q.en;
  return q.prompt || q.en;
}

/* ---------------- choice ---------------- */

function ChoiceRound({
  question,
  onSettle,
  answered,
  hints,
}: {
  question: Question;
  onSettle: (correct: boolean) => void;
  answered: boolean;
  hints: { small: boolean; large: boolean };
}) {
  const [picked, setPicked] = useState<string | null>(null);
  const options = question.options ?? [];
  const eliminated = useMemo(() => {
    if (!hints.small || answered) return null;
    const wrong = options.filter((o) => !o.correct);
    return wrong.length ? wrong[0].key : null;
  }, [hints.small, answered, options]);

  const koVoice = useKoreanVoice();
  const revealedKey = hints.large ? options.find((o) => o.correct)?.key ?? null : null;
  const replayText = question.type === "listen" ? question.reveal ?? "" : question.prompt;

  useEffect(() => {
    if (question.type === "listen") {
      if (question.reveal) speak(question.reveal, 0.8);
    } else if (question.promptIsKorean) {
      speak(question.prompt);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (!hints.large || answered) return;
    const key = options.find((o) => o.correct)?.key;
    if (key) {
      setPicked(key);
      onSettle(true);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [hints.large]);

  const choose = (key: string) => {
    if (answered) return;
    setPicked(key);
    const opt = options.find((o) => o.key === key);
    onSettle(Boolean(opt?.correct));
  };

  const twoCol = question.type !== "mc-rom" && options.every((o) => o.text.length <= 14);

  return (
    <div className="mt-3">
      {question.type === "listen" && koVoice ? (
        <div className="flex flex-col items-center gap-2 py-4">
          <button
            type="button"
            onClick={() => speak(replayText, 0.8)}
            className="flex h-20 w-20 items-center justify-center rounded-3xl bg-brand text-white transition active:scale-95"
            aria-label="Play audio again"
          >
            <IconVolume className="h-8 w-8" />
          </button>
          <p className="text-xs font-semibold text-muted">Tap to replay the audio</p>
        </div>
      ) : question.type === "listen" ? (
        <div className="flex flex-col items-center gap-1 py-3">
          <span className="hangul text-[38px] font-bold leading-none">{replayText}</span>
          <p className="text-[11px] text-muted">
            No Korean voice in this browser — read the word instead of listening.
          </p>
        </div>
      ) : (
        <div className="flex items-center justify-center gap-3 py-3">
          <span className={`hangul text-center font-bold ${question.prompt.length > 8 ? "text-2xl" : "text-[40px]"}`}>
            {question.prompt}
          </span>
          {question.promptIsKorean ? <Speaker text={question.prompt} /> : null}
        </div>
      )}

      <div className={`grid gap-2 ${twoCol ? "grid-cols-2" : "grid-cols-1"}`}>
        {options.map((o) => {
          if (eliminated === o.key) return <div key={o.key} className="rounded-2xl border border-dashed border-line bg-surface2/40 p-3 text-center text-xs text-muted">removed</div>;
          const isPicked = picked === o.key;
          const isRight = answered && o.correct;
          const isWrongPick = answered && isPicked && !o.correct;
          return (
            <button
              key={o.key}
              type="button"
              disabled={answered}
              onClick={() => choose(o.key)}
              className={`rounded-2xl border px-3 py-3 text-center text-sm font-bold transition active:scale-[0.98]
                ${isRight ? "border-good bg-goodsoft text-good" : ""}
                ${isWrongPick ? "border-bad bg-badsoft text-bad" : ""}
                ${!isRight && !isWrongPick ? (revealedKey === o.key ? "border-warn bg-warnsoft text-warn" : "border-line bg-surface2 hover:border-brand hover:bg-brandsoft/40") : ""}
                ${answered && !isRight && !isWrongPick ? "opacity-60" : ""}`}
            >
              <span className={question.type === "mc-en-ko" ? "hangul" : ""}>{o.text}</span>
            </button>
          );
        })}
      </div>
    </div>
  );
}

/* ---------------- typing ---------------- */

function TypeRound({
  question,
  onSettle,
  answered,
  hints,
}: {
  question: Question;
  onSettle: (correct: boolean) => void;
  answered: boolean;
  hints: { small: boolean; large: boolean };
}) {
  const [value, setValue] = useState("");
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    speak(question.prompt);
    inputRef.current?.focus();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (hints.large && !answered) onSettle(true);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [hints.large]);

  const check = () => {
    if (answered || !value.trim()) return;
    onSettle(isRomanAccepted(value, question.rom));
  };

  const preview = hints.small ? `${question.rom.slice(0, Math.max(1, Math.floor(question.rom.length / 2)))}…` : null;

  return (
    <div className="mt-3 space-y-3">
      <div className="flex items-center justify-center gap-3 py-2">
        <span className="hangul text-[42px] font-bold">{question.prompt}</span>
        <Speaker text={question.prompt} />
      </div>
      <div className="flex gap-2">
        <input
          ref={inputRef}
          value={value}
          disabled={answered}
          onChange={(e) => setValue(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && check()}
          placeholder="Type the romanization…"
          autoCapitalize="off"
          autoCorrect="off"
          className="flex-1 rounded-2xl border border-line bg-surface2 px-4 py-3 text-sm font-semibold outline-none transition focus:border-brand"
        />
        {!answered ? (
          <Btn onClick={check} disabled={!value.trim()}>
            Check
          </Btn>
        ) : null}
      </div>
      {preview && !answered ? (
        <p className="text-center text-xs font-bold text-warn">
          Starts with “{preview}”
        </p>
      ) : null}
      {hints.large && !answered ? (
        <p className="text-center text-sm font-black text-warn">{question.rom}</p>
      ) : null}
      <p className="text-center text-[11px] text-muted">Spaces and hyphens are ignored.</p>
    </div>
  );
}

/* ---------------- syllable builder ---------------- */

function BuilderRound({
  question,
  onSettle,
  answered,
  hints,
}: {
  question: Question;
  onSettle: (correct: boolean) => void;
  answered: boolean;
  hints: { small: boolean; large: boolean };
}) {
  const target = question.targetJamo ?? [];
  const choices = useMemo(() => shuffle(question.jamoChoices ?? []), [question]);
  const [pickedKeys, setPickedKeys] = useState<string[]>([]);
  const picked = pickedKeys
    .map((k) => choices.find((c) => c.key === k)?.text ?? "")
    .filter(Boolean);

  const remaining = target.length - picked.length;

  useEffect(() => {
    if (!hints.small || pickedKeys.length || !target.length) return;
    const first = choices.find((c) => c.correct && c.text === target[0]);
    if (first) setPickedKeys([first.key]);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [hints.small]);

  useEffect(() => {
    if (!hints.large || answered) return;
    const keys = target
      .map((t) => choices.find((c) => c.correct && c.text === t)?.key)
      .filter((k): k is string => Boolean(k));
    setPickedKeys(keys);
    onSettle(true);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [hints.large]);

  useEffect(() => {
    if (answered || picked.length === 0 || picked.length !== target.length) return;
    onSettle(picked.join("") === target.join(""));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [pickedKeys]);

  const preview = picked.length ? composeSyllable(picked) : "";

  return (
    <div className="mt-3 space-y-4">
      <div className="flex flex-col items-center gap-1">
        <p className="text-xs font-semibold text-muted">Build the block that sounds like</p>
        <p className="text-2xl font-black text-brand">{question.en}</p>
        <p className="text-xs text-muted">/{question.rom}/</p>
      </div>

      <div className="flex min-h-[84px] items-center justify-center gap-2 rounded-3xl border-2 border-dashed border-line bg-surface2/60 p-3">
        {preview ? (
          <span className="hangul anim-pop text-[52px] font-bold leading-none">{preview}</span>
        ) : (
          <span className="text-xs font-bold text-muted">Tap the letters in order</span>
        )}
        {Array.from({ length: Math.max(0, remaining) }).map((_, i) => (
          <span key={i} className="h-9 w-7 rounded-lg border border-dashed border-line" />
        ))}
      </div>

      <div className="grid grid-cols-5 gap-2">
        {choices.map((c) => {
          const used = pickedKeys.includes(c.key);
          return (
            <button
              key={c.key}
              type="button"
              disabled={answered || used}
              onClick={() => setPickedKeys((p) => [...p, c.key])}
              className={`hangul rounded-2xl border py-3 text-xl font-bold transition active:scale-95
                ${used ? "border-line bg-surface2 text-muted opacity-40" : "border-line bg-surface hover:border-brand hover:bg-brandsoft/40"}`}
            >
              {c.text}
            </button>
          );
        })}
      </div>

      {!answered && picked.length ? (
        <Btn variant="ghost" size="sm" block onClick={() => setPickedKeys([])}>
          Clear
        </Btn>
      ) : null}
    </div>
  );
}

/* ---------------- sentence order ---------------- */

function OrderRound({
  question,
  onSettle,
  answered,
  hints,
}: {
  question: Question;
  onSettle: (correct: boolean) => void;
  answered: boolean;
  hints: { small: boolean; large: boolean };
}) {
  const target = question.order ?? [];
  const [chips] = useState(() => shuffle(target));
  const [picked, setPicked] = useState<string[]>([]);

  useEffect(() => {
    if (hints.small && picked.length === 0 && target.length) setPicked([target[0]]);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [hints.small]);

  useEffect(() => {
    if (hints.large && !answered) {
      setPicked(target);
      onSettle(true);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [hints.large]);

  const check = () => {
    if (answered || picked.length !== target.length) return;
    onSettle(picked.join(" ") === target.join(" "));
  };

  return (
    <div className="mt-3 space-y-3">
      <div className="rounded-2xl bg-surface2 p-3 text-center">
        <p className="text-xs font-semibold text-muted">Translate into Korean</p>
        <p className="mt-1 text-lg font-extrabold">{question.en}</p>
        <p className="text-[11px] text-muted">{question.rom}</p>
      </div>

      <div className="flex min-h-[62px] flex-wrap items-center gap-2 rounded-2xl border-2 border-dashed border-line bg-surface2/50 p-3">
        {picked.length === 0 ? (
          <span className="text-xs font-bold text-muted">Tap the chunks in the right order…</span>
        ) : (
          picked.map((p, i) => (
            <button
              key={`${p}-${i}`}
              type="button"
              disabled={answered}
              onClick={() => setPicked((list) => list.filter((_, idx) => idx !== i))}
              className="hangul anim-pop rounded-xl border border-brand/40 bg-brandsoft px-3 py-2 text-sm font-bold text-brandfg"
            >
              {p}
            </button>
          ))
        )}
      </div>

      <div className="flex flex-wrap gap-2">
        {chips.map((c, i) => {
          const usedCount = picked.filter((p) => p === c).length;
          const chipCount = chips.filter((x) => x === c).length;
          const disabled = usedCount >= chipCount;
          return (
            <button
              key={`${c}-${i}`}
              type="button"
              disabled={answered || disabled}
              onClick={() => setPicked((list) => [...list, c])}
              className={`hangul rounded-xl border px-3 py-2 text-sm font-bold transition active:scale-95
                ${disabled ? "border-line bg-surface2 text-muted opacity-40" : "border-line bg-surface hover:border-brand"}`}
            >
              {c}
            </button>
          );
        })}
      </div>

      {!answered ? (
        <Btn block size="lg" onClick={check} disabled={picked.length !== target.length}>
          Check sentence
        </Btn>
      ) : null}
    </div>
  );
}

/* ---------------- matching game ---------------- */

function MatchRound({
  question,
  onSettle,
  answered,
}: {
  question: Question;
  onSettle: (correct: boolean) => void;
  answered: boolean;
}) {
  const pairs = question.pairs ?? [];
  const [ko] = useState(() => shuffle(pairs.map((p) => p.ko)));
  const [en] = useState(() => shuffle(pairs.map((p) => p.en)));
  const [selKo, setSelKo] = useState<string | null>(null);
  const [selEn, setSelEn] = useState<string | null>(null);
  const [matched, setMatched] = useState<string[]>([]);
  const [errors, setErrors] = useState(0);
  const [wrongPair, setWrongPair] = useState<[string, string] | null>(null);

  useEffect(() => {
    if (!selKo || !selEn || answered) return;
    const pair = pairs.find((p) => p.ko === selKo);
    if (pair?.en === selEn) {
      const next = [...matched, selKo];
      setMatched(next);
      speak(selKo);
      setSelKo(null);
      setSelEn(null);
      if (next.length === pairs.length) onSettle(errors <= 1);
    } else {
      setErrors((e) => e + 1);
      setWrongPair([selKo, selEn]);
      window.setTimeout(() => {
        setWrongPair(null);
        setSelKo(null);
        setSelEn(null);
      }, 550);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selKo, selEn]);

  return (
    <div className="mt-3 space-y-3">
      <div className="flex items-center justify-between text-xs font-bold text-muted">
        <span>
          {matched.length}/{pairs.length} pairs
        </span>
        <span className={errors > 1 ? "text-bad" : ""}>{errors} mistake{errors === 1 ? "" : "s"}</span>
      </div>
      <div className="grid grid-cols-2 gap-2">
        <div className="space-y-2">
          {ko.map((k) => {
            const done = matched.includes(k);
            const wrong = wrongPair?.[0] === k;
            return (
              <button
                key={k}
                type="button"
                disabled={answered || done}
                onClick={() => setSelKo(k)}
                className={`hangul w-full rounded-2xl border px-2 py-3 text-sm font-bold transition active:scale-95
                  ${done ? "border-good bg-goodsoft text-good" : ""}
                  ${wrong ? "anim-shake border-bad bg-badsoft text-bad" : ""}
                  ${!done && !wrong ? (selKo === k ? "border-brand bg-brandsoft text-brandfg" : "border-line bg-surface2") : ""}
                  ${done ? "opacity-60" : ""}`}
              >
                {k}
              </button>
            );
          })}
        </div>
        <div className="space-y-2">
          {en.map((e) => {
            const done = pairs.some((p) => p.en === e && matched.includes(p.ko));
            const wrong = wrongPair?.[1] === e;
            return (
              <button
                key={e}
                type="button"
                disabled={answered || done}
                onClick={() => setSelEn(e)}
                className={`w-full rounded-2xl border px-2 py-3 text-left text-xs font-bold transition active:scale-95
                  ${done ? "border-good bg-goodsoft text-good" : ""}
                  ${wrong ? "anim-shake border-bad bg-badsoft text-bad" : ""}
                  ${!done && !wrong ? (selEn === e ? "border-brand bg-brandsoft text-brandfg" : "border-line bg-surface2") : ""}
                  ${done ? "opacity-60" : ""}`}
              >
                {e}
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}

/* ---------------- hint bar ---------------- */

function HintBar({
  xpBalance,
  costs,
  hints,
  onHint,
  disabled,
}: {
  xpBalance: number;
  costs: { small: number; medium: number; large: number };
  hints: { small: boolean; medium: boolean; large: boolean };
  onHint: (tier: HintTier) => void;
  disabled: boolean;
}) {
  const items: { tier: HintTier; cost: number; label: string; desc: string; used: boolean }[] = [
    { tier: "small", cost: costs.small, label: "50 / 50", desc: "remove a wrong option", used: hints.small },
    { tier: "medium", cost: costs.medium, label: "Coach", desc: "sound + note", used: hints.medium },
    { tier: "large", cost: costs.large, label: "Reveal", desc: "show the answer", used: hints.large },
  ];
  return (
    <Panel className="p-3">
      <div className="mb-2 flex items-center justify-between">
        <span className="inline-flex items-center gap-1.5 text-[11px] font-black uppercase tracking-wide text-muted">
          <IconSparkle className="h-3.5 w-3.5 text-brand" /> Hints
        </span>
        <Pill tone="brand">
          <IconBolt className="h-3 w-3" /> {xpBalance} XP available
        </Pill>
      </div>
      <div className="grid grid-cols-3 gap-2">
        {items.map((h) => {
          const afford = xpBalance >= h.cost;
          return (
            <button
              key={h.tier}
              type="button"
              disabled={disabled || h.used || !afford}
              onClick={() => onHint(h.tier)}
              className={`rounded-2xl border p-2.5 text-left transition active:scale-[0.97] disabled:opacity-45
                ${afford && !h.used ? "border-brand/40 bg-brandsoft/40 hover:bg-brandsoft/70" : "border-line bg-surface2"}`}
            >
              <span className="flex items-center gap-1 text-[11px] font-black text-brand">
                <IconBolt className="h-3 w-3" />
                {h.cost} XP
              </span>
              <span className="mt-0.5 block text-sm font-extrabold">{h.used ? "Used" : h.label}</span>
              <span className="block text-[10px] leading-tight text-muted">{h.desc}</span>
            </button>
          );
        })}
      </div>
      <p className="mt-2 text-center text-[10px] text-muted">
        Earn 1 XP per correct answer · a hinted question pays nothing
      </p>
    </Panel>
  );
}

/* ---------------- results ---------------- */

function ResultsPhase({
  lesson,
  result,
  answers,
  busy,
  nextLessonId,
  onRetry,
}: {
  lesson: Lesson;
  result: { score: number; passed: boolean; correct: number; total: number; xpGained: number };
  answers: LessonAnswer[];
  busy: boolean;
  nextLessonId?: string;
  onRetry: () => void;
}) {
  const missedCards = useMemo(() => {
    const ids = answers.filter((a) => !a.correct).map((a) => a.cardId);
    const unique = Array.from(new Set(ids));
    return unique
      .map((id) => ALL_LESSONS.flatMap((l) => l.cards).find((c: Card) => c.id === id))
      .filter(Boolean) as Card[];
  }, [answers]);

  const nextLesson = result.passed && nextLessonId ? getLesson(nextLessonId) : undefined;

  return (
    <div className="space-y-4">
      <Panel className="anim-pop p-6 text-center">
        <Ring value={result.score} size={132} stroke={12} color={result.passed ? "var(--good)" : "var(--bad)"}>
          <div>
            <div className="text-3xl font-black leading-none">{result.score}%</div>
            <div className="text-[10px] font-bold uppercase tracking-wide text-muted">
              {result.correct}/{result.total} correct
            </div>
          </div>
        </Ring>

        <h2 className="mt-4 text-xl font-black tracking-tight">
          {result.passed ? "Lesson passed!" : "Not yet — 70% needed"}
        </h2>
        <p className="mx-auto mt-1 max-w-[42ch] text-sm text-muted">
          {result.passed
            ? `You scored ${result.score}% on “${lesson.title}”. The next lesson is unlocked.`
            : `You scored ${result.score}%. Replay this lesson and reach ${lesson.passScore}% to unlock what comes next.`}
        </p>

        <div className="mt-4 flex items-center justify-center gap-2">
          <Pill tone="brand">
            <IconBolt className="h-3 w-3" /> +{result.xpGained} XP earned
          </Pill>
          <Pill tone={result.passed ? "good" : "bad"}>
            {result.passed ? <IconCheck className="h-3 w-3" /> : <IconX className="h-3 w-3" />}
            {result.passed ? "unlocked" : "locked"}
          </Pill>
        </div>
      </Panel>

      {missedCards.length ? (
        <Panel className="p-4">
          <p className="mb-2 text-[11px] font-black uppercase tracking-wide text-muted">
            Words to review ({missedCards.length})
          </p>
          <div className="space-y-2">
            {missedCards.slice(0, 8).map((c) => (
              <div key={c.id} className="flex items-center justify-between gap-2 rounded-2xl bg-surface2 px-3 py-2">
                <div className="min-w-0">
                  <p className="hangul truncate text-sm font-bold">{c.ko}</p>
                  <p className="truncate text-[11px] text-muted">
                    {c.rom} · {c.en}
                  </p>
                </div>
                <Speaker text={c.ko} size="sm" />
              </div>
            ))}
          </div>
          <Link href="/review" className="mt-3 block">
            <Btn variant="soft" block>
              Open the Review Deck
            </Btn>
          </Link>
        </Panel>
      ) : (
        <Panel className="p-4 text-center">
          <p className="text-sm font-extrabold text-good">Perfect run — nothing to review.</p>
        </Panel>
      )}

      <div className="space-y-2">
        {nextLesson ? (
          <Link href={`/learn/${nextLesson.id}`} className="block">
            <Btn block size="lg">
              <IconPlay className="h-4 w-4" /> Next: {nextLesson.title}
            </Btn>
          </Link>
        ) : null}
        <Btn block variant={nextLesson ? "soft" : "primary"} size="lg" onClick={onRetry} disabled={busy}>
          Retry “{lesson.title}”
        </Btn>
        <Link href={`/path/${guessPathId(lesson.id)}`} className="block">
          <Btn block variant="ghost">
            Back to the roadmap
          </Btn>
        </Link>
      </div>
    </div>
  );
}

function guessPathId(lessonId: string): string {
  if (lessonId.startsWith("h-")) return "p-hangul";
  if (lessonId.startsWith("w-")) return "p-words";
  if (lessonId.startsWith("g-")) return "p-grammar";
  return "p-talk";
}
