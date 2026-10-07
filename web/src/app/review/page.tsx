"use client";

import Link from "next/link";
import { useMemo, useState } from "react";

import { SectionTitle } from "@/components/Shell";
import { IconBolt, IconCheck, IconHeart, IconX } from "@/components/icons";
import { Bar, Btn, EmptyState, Panel, Pill, Ring, Speaker } from "@/components/ui";
import { speak, useApp } from "@/lib/store";

export default function ReviewPage() {
  const { state, recordReview } = useApp();
  const deck = state?.review ?? [];
  const [index, setIndex] = useState(0);
  const [revealed, setRevealed] = useState(false);
  const [entries, setEntries] = useState<{ cardId: string; correct: boolean }[]>([]);
  const [done, setDone] = useState(false);
  const [busy, setBusy] = useState(false);

  const card = deck[index];
  const correctCount = useMemo(() => entries.filter((e) => e.correct).length, [entries]);

  if (done) {
    return (
      <div className="space-y-4">
        <Panel className="anim-pop p-6 text-center">
          <Ring value={(correctCount / Math.max(1, entries.length)) * 100} size={120} stroke={11} color="var(--good)">
            <div>
              <div className="text-2xl font-black leading-none">
                {correctCount}/{entries.length}
              </div>
              <div className="text-[10px] font-bold uppercase text-muted">recalled</div>
            </div>
          </Ring>
          <h2 className="mt-4 text-lg font-black">Review session finished</h2>
          <p className="mt-1 text-sm text-muted">
            You earned <b className="text-brand">{correctCount} XP</b>. Words you recalled 3 times are marked as
            mastered and drop out of the deck.
          </p>
          <div className="mt-4 space-y-2">
            <Btn
              block
              onClick={() => {
                setDone(false);
                setEntries([]);
                setIndex(0);
                setRevealed(false);
              }}
            >
              Drill again
            </Btn>
            <Link href="/" className="block">
              <Btn block variant="ghost">
                Back to roadmap
              </Btn>
            </Link>
          </div>
        </Panel>
      </div>
    );
  }

  if (!state) {
    return <div className="h-64 animate-pulse rounded-3xl border border-line bg-surface" />;
  }

  if (!deck.length) {
    return (
      <div className="space-y-4">
        <EmptyState
          icon="🌱"
          title="Your review deck is empty"
          body="Words you answer incorrectly during lessons land here. Go play a lesson and this deck will fill up automatically."
        />
        <Link href="/">
          <Btn block>Start a lesson</Btn>
        </Link>
      </div>
    );
  }

  if (!card) {
    return (
      <Panel className="p-6 text-center">
        <p className="text-sm text-muted">Deck finished.</p>
      </Panel>
    );
  }

  const answer = async (correct: boolean) => {
    const next = [...entries, { cardId: card.cardId, correct }];
    setEntries(next);
    if (index + 1 >= deck.length) {
      setBusy(true);
      setDone(true);
      try {
        await recordReview(next);
      } finally {
        setBusy(false);
      }
      return;
    }
    setIndex((i) => i + 1);
    setRevealed(false);
  };

  return (
    <div className="space-y-3">
      <Panel className="p-4">
        <SectionTitle
          icon={<IconHeart className="h-4 w-4" />}
          title="Review Deck"
          sub={`${deck.length} word${deck.length === 1 ? "" : "s"} waiting`}
          right={
            <Pill tone="brand">
              <IconBolt className="h-3 w-3" /> {state.profile.xpBalance} XP
            </Pill>
          }
        />
        <Bar value={(index / deck.length) * 100} color="var(--good)" />
        <p className="mt-2 text-[11px] text-muted">
          Card {index + 1} of {deck.length} · asked wrong {card.wrongCount} time{card.wrongCount === 1 ? "" : "s"}
        </p>
      </Panel>

      <Panel className="anim-rise p-6">
        <div className="flex flex-col items-center gap-3">
          <span className="hangul text-[52px] font-bold leading-none">{card.ko}</span>
          <Speaker text={card.ko} size="lg" />
          <button
            type="button"
            onClick={() => {
              setRevealed(true);
              speak(card.ko);
            }}
            className="w-full rounded-2xl border border-dashed border-line bg-surface2 px-4 py-3 text-center transition hover:border-brand"
          >
            {revealed ? (
              <>
                <span className="block text-base font-extrabold text-brand">{card.rom}</span>
                <span className="block text-sm font-semibold">{card.en}</span>
              </>
            ) : (
              <span className="text-sm font-bold text-muted">Think first, then tap to reveal</span>
            )}
          </button>
        </div>
      </Panel>

      {revealed ? (
        <div className="grid grid-cols-2 gap-2">
          <Btn variant="danger" size="lg" onClick={() => void answer(false)} disabled={busy}>
            <IconX className="h-4 w-4" /> Still learning
          </Btn>
          <Btn variant="good" size="lg" onClick={() => void answer(true)} disabled={busy}>
            <IconCheck className="h-4 w-4" /> I knew it
          </Btn>
        </div>
      ) : (
        <Btn block size="lg" variant="soft" onClick={() => setRevealed(true)}>
          Reveal meaning
        </Btn>
      )}
    </div>
  );
}
