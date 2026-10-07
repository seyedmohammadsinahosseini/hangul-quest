"use client";

import Link from "next/link";
import { useParams } from "next/navigation";

import { LessonPlayer } from "@/components/LessonPlayer";
import { IconLock, IconTarget } from "@/components/icons";
import { Btn, EmptyState, Panel, Pill } from "@/components/ui";
import { LESSON_PATH, getLesson } from "@/lib/curriculum";
import { useApp } from "@/lib/store";

const MODE_HELP: Record<string, string> = {
  flashcards: "Learn the cards, then answer a mixed quiz.",
  quiz: "Mixed multiple choice, listening and typing.",
  builder: "Assemble jamo into real syllable blocks.",
  match: "Match Korean with English as fast as you can.",
  sentences: "Build whole Korean sentences chunk by chunk.",
  test: "No warm-up. A blind mixed test.",
};

export default function LearnPage() {
  const { lessonId } = useParams<{ lessonId: string }>();
  const lesson = getLesson(lessonId);
  const { state, loading } = useApp();

  if (!lesson) {
    return <EmptyState icon="🧩" title="Lesson not found" body="Pick a lesson from your roadmap." />;
  }

  const pathId = LESSON_PATH[lesson.id] ?? "p-hangul";
  const st = state?.lessons[lesson.id];
  const locked = st?.status === "locked";

  // The player is keyed by lesson id only (not by the attempts counter), so a
  // submitted run stays on its results screen instead of remounting from scratch.
  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between gap-2 px-1">
        <div className="min-w-0">
          <div className="flex items-center gap-2">
            <h1 className="truncate text-lg font-black tracking-tight">{lesson.title}</h1>
            <Pill tone="brand">{lesson.cards.length} cards</Pill>
          </div>
          <p className="truncate text-xs text-muted">{MODE_HELP[lesson.mode]}</p>
        </div>
        <Pill tone="neutral">
          <IconTarget className="h-3 w-3" /> pass {lesson.passScore}%
        </Pill>
      </div>

      {loading && !state ? (
        <div className="h-64 animate-pulse rounded-3xl border border-line bg-surface" />
      ) : locked ? (
        <Panel className="p-6 text-center">
          <span className="mx-auto mb-3 flex h-14 w-14 items-center justify-center rounded-2xl bg-warnsoft text-warn">
            <IconLock className="h-6 w-6" />
          </span>
          <h2 className="text-lg font-black">This lesson is still locked</h2>
          <p className="mx-auto mt-1 max-w-[40ch] text-sm text-muted">
            Finish the lesson before it and score at least 70% to open this one.
          </p>
          <Link href={`/path/${pathId}`} className="mt-4 inline-block">
            <Btn>Open the roadmap</Btn>
          </Link>
        </Panel>
      ) : (
        <LessonPlayer key={lesson.id} lesson={lesson} />
      )}
    </div>
  );
}
