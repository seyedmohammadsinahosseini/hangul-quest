"use client";

import Link from "next/link";
import { useParams } from "next/navigation";

import {
  IconArrowLeft,
  IconCheck,
  IconLock,
  IconPlay,
  IconTarget,
} from "@/components/icons";
import { Bar, Btn, EmptyState, Panel, Pill } from "@/components/ui";
import { PATHS, getPath, type LessonMode } from "@/lib/curriculum";
import { useApp } from "@/lib/store";

const MODE_LABEL: Record<LessonMode, string> = {
  flashcards: "Learn",
  quiz: "Quiz",
  builder: "Game",
  match: "Game",
  sentences: "Build",
  test: "Test",
};

export default function PathPage() {
  const params = useParams<{ pathId: string }>();
  const { state, loading } = useApp();
  const path = getPath(params.pathId);

  if (!path) {
    return (
      <EmptyState
        icon="🧭"
        title="Unknown path"
        body="That learning path does not exist. Head back to the roadmap."
      />
    );
  }
  if (loading && !state) {
    return <div className="h-64 animate-pulse rounded-3xl border border-line bg-surface" />;
  }

  const progress = state?.paths.find((p) => p.id === path.id);
  const index = PATHS.findIndex((p) => p.id === path.id);
  const remaining = (progress?.totalLessons ?? 0) - (progress?.completedLessons ?? 0);

  return (
    <div className="space-y-5">
      <Link
        href="/"
        className="inline-flex items-center gap-1.5 text-xs font-bold text-muted transition hover:text-fg"
      >
        <IconArrowLeft className="h-4 w-4" /> All paths
      </Link>

      <Panel className="p-4">
        <div className="flex items-start justify-between gap-3">
          <div>
            <div className="flex items-center gap-2">
              <span className="h-2.5 w-2.5 rounded-full" style={{ background: path.color }} />
              <span className="text-[10px] font-black uppercase tracking-[0.16em] text-muted">
                Stage {index + 1} of {PATHS.length}
              </span>
            </div>
            <h1 className="mt-1 text-2xl font-black tracking-tight">{path.title}</h1>
            <p className="text-sm text-muted">{path.tagline}</p>
          </div>
          {progress?.locked ? (
            <Pill tone="warn">
              <IconLock className="h-3 w-3" /> Locked
            </Pill>
          ) : null}
        </div>

        <div className="mt-4">
          <div className="mb-1.5 flex items-center justify-between text-xs font-bold">
            <span style={{ color: path.color }}>{progress?.percent ?? 0}% complete</span>
            <span className="text-muted">
              {remaining === 0 ? "nothing left" : `${remaining} lesson${remaining === 1 ? "" : "s"} remaining`}
            </span>
          </div>
          <Bar value={progress?.percent ?? 0} color={path.color} height={10} />
          <div className="mt-2 flex items-center gap-3 text-[11px] text-muted">
            <span className="inline-flex items-center gap-1">
              <IconCheck className="h-3 w-3 text-good" /> {progress?.completedLessons ?? 0}/
              {progress?.totalLessons ?? 0} passed
            </span>
            <span className="inline-flex items-center gap-1">
              <IconTarget className="h-3 w-3 text-brand" /> {progress?.accuracy ?? 0}% accuracy
            </span>
          </div>
        </div>

        {progress?.locked ? (
          <div className="mt-4 rounded-2xl border border-warn/40 bg-warnsoft/50 p-3">
            <p className="text-[11px] font-black uppercase tracking-wide text-warn">How to unlock</p>
            <p className="mt-1 text-sm font-semibold">{progress.unlockLabel}</p>
            <p className="mt-1 text-[11px] text-muted">
              {progress.unlockDone}/{progress.unlockNeed} done · pass score is always 70%
            </p>
            <Link href={`/path/${PATHS[Math.max(0, index - 1)].id}`} className="mt-3 inline-block">
              <Btn size="sm">Go to the previous stage</Btn>
            </Link>
          </div>
        ) : null}
      </Panel>

      {path.units.map((unit, ui) => {
        const unitDone = unit.lessons.filter(
          (l) => state?.lessons[l.id]?.status === "completed",
        ).length;
        return (
          <div key={unit.id}>
            <div className="mb-2 flex items-end justify-between gap-2 px-1">
              <div>
                <h2 className="text-sm font-black uppercase tracking-[0.14em] text-muted">
                  Unit {ui + 1} · {unit.title}
                </h2>
                <p className="text-xs text-muted">{unit.focus}</p>
              </div>
              <Pill tone={unitDone === unit.lessons.length ? "good" : "neutral"}>
                {unitDone}/{unit.lessons.length}
              </Pill>
            </div>

            <div className="relative pl-6">
              <span
                className="absolute left-[15px] top-2 bottom-2 w-[3px] rounded-full opacity-30"
                style={{ background: path.color }}
              />
              <div className="space-y-2.5">
                {unit.lessons.map((lesson, li) => {
                  const st = state?.lessons[lesson.id];
                  const status = st?.status ?? "locked";
                  const locked = status === "locked" || progress?.locked;
                  const done = status === "completed";
                  const offset = li % 2 === 0 ? "translate-x-0" : "translate-x-2";
                  return (
                    <div key={lesson.id} className={`relative ${offset}`}>
                      <span
                        className={`absolute -left-6 top-1/2 flex h-[22px] w-[22px] -translate-y-1/2 items-center justify-center rounded-full border-2 text-[10px] font-black ${
                          done
                            ? "border-good bg-good text-white"
                            : locked
                              ? "border-line bg-surface2 text-muted"
                              : "border-brand bg-surface text-brand"
                        }`}
                        style={{ left: "-26px" }}
                      >
                        {done ? "✓" : locked ? "" : li + 1}
                      </span>

                      {locked ? (
                        <div className="rounded-2xl border border-line bg-surface2/70 p-3 opacity-70">
                          <div className="flex items-center justify-between gap-2">
                            <div className="min-w-0">
                              <div className="truncate text-sm font-extrabold">{lesson.title}</div>
                              <div className="truncate text-[11px] text-muted">{lesson.goal}</div>
                            </div>
                            <IconLock className="h-4 w-4 shrink-0 text-muted" />
                          </div>
                        </div>
                      ) : (
                        <Link href={`/learn/${lesson.id}`} className="block">
                          <Panel
                            className={`p-3 transition hover:-translate-y-0.5 ${
                              done ? "border-good/40" : "border-brand/30"
                            }`}
                          >
                            <div className="flex items-center justify-between gap-2">
                              <div className="min-w-0">
                                <div className="flex items-center gap-1.5">
                                  <span
                                    className="rounded-md px-1.5 py-0.5 text-[9px] font-black uppercase tracking-wide"
                                    style={{ background: `${path.color}22`, color: path.color }}
                                  >
                                    {MODE_LABEL[lesson.mode]}
                                  </span>
                                  <span className="truncate text-sm font-extrabold">{lesson.title}</span>
                                </div>
                                <div className="mt-0.5 truncate text-[11px] text-muted">{lesson.goal}</div>
                              </div>
                              <div className="flex shrink-0 items-center gap-2">
                                {done ? (
                                  <span className="text-[11px] font-black text-good">{st?.bestScore}%</span>
                                ) : null}
                                <span
                                  className={`flex h-8 w-8 items-center justify-center rounded-xl ${
                                    done ? "bg-goodsoft text-good" : "bg-brand text-white"
                                  }`}
                                >
                                  {done ? <IconCheck className="h-4 w-4" /> : <IconPlay className="h-3.5 w-3.5" />}
                                </span>
                              </div>
                            </div>
                          </Panel>
                        </Link>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );
}
