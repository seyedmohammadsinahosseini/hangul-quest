"use client";

import Link from "next/link";

import { SectionTitle } from "@/components/Shell";
import {
  IconBolt,
  IconCheck,
  IconFlame,
  IconLock,
  IconMap,
  IconPlay,
  IconSparkle,
  IconTarget,
  IconTrophy,
} from "@/components/icons";
import { Bar, Btn, EmptyState, Panel, Pill, Ring } from "@/components/ui";
import { ALL_LESSONS, getLesson } from "@/lib/curriculum";
import { useApp } from "@/lib/store";

const STAGE_LABEL: Record<string, string> = {
  alphabet: "Stage 1 · Alphabet",
  vocabulary: "Stage 2 · Words",
  grammar: "Stage 3 · Grammar",
  conversation: "Stage 4 · Sentences",
};

export default function HomePage() {
  const { state, loading, error, refresh } = useApp();

  if (loading && !state) return <LoadingHome />;
  if (error && !state)
    return (
      <div className="space-y-3">
        <EmptyState icon="⚠️" title="Could not reach the server" body={error} />
        <Btn block onClick={() => void refresh()}>
          Try again
        </Btn>
      </div>
    );
  if (!state) return <LoadingHome />;

  const { profile, paths, lessons } = state;
  const done = paths.reduce((s, p) => s + p.completedLessons, 0);
  const total = ALL_LESSONS.length;

  const nextLessonId =
    paths.find((p) => !p.locked && p.firstAvailableLessonId)?.firstAvailableLessonId ??
    Object.values(lessons).find((l) => l.status === "available")?.id;
  const nextLesson = nextLessonId ? getLesson(nextLessonId) : undefined;
  const nextPath = nextLessonId ? paths.find((p) => p.id === lessons[nextLessonId]?.pathId) : undefined;

  return (
    <div className="space-y-6">
      {/* Journey hero */}
      <Panel className="overflow-hidden">
        <div className="flex items-center gap-4 p-4">
          <Ring value={state.overallPercent} size={84} stroke={9}>
            <div className="text-center">
              <div className="text-lg font-black leading-none">{state.overallPercent}%</div>
              <div className="text-[9px] font-bold uppercase tracking-wide text-muted">done</div>
            </div>
          </Ring>
          <div className="min-w-0 flex-1">
            <p className="text-xs font-semibold uppercase tracking-[0.14em] text-muted">Your journey</p>
            <h1 className="truncate text-xl font-black tracking-tight">
              {done} / {total} lessons
            </h1>
            <p className="mt-0.5 text-xs text-muted">
              {total - done} lesson{total - done === 1 ? "" : "s"} left on the roadmap
            </p>
            <div className="mt-2.5 flex flex-wrap gap-1.5">
              <Pill tone="brand">
                <IconBolt className="h-3 w-3" /> {profile.xpBalance} XP
              </Pill>
              <Pill tone="warn">
                <IconFlame className="h-3 w-3" /> {profile.streak} day streak
              </Pill>
              <Pill tone={profile.accuracy >= 70 ? "good" : "neutral"}>
                <IconTarget className="h-3 w-3" /> {profile.accuracy}% accuracy
              </Pill>
            </div>
          </div>
        </div>

        <div className="border-t border-line bg-surface2/60 px-4 py-3">
          <div className="mb-1.5 flex items-center justify-between text-xs font-semibold">
            <span className="text-muted">
              Daily goal · {profile.xpToday}/{profile.dailyGoal} XP
            </span>
            <span className={profile.goalDone ? "text-good" : "text-muted"}>
              {profile.goalDone ? "Goal reached" : `${Math.max(0, profile.dailyGoal - profile.xpToday)} to go`}
            </span>
          </div>
          <Bar value={(profile.xpToday / profile.dailyGoal) * 100} color="var(--good)" />
        </div>
      </Panel>

      {/* Continue */}
      {nextLesson ? (
        <Link href={`/learn/${nextLesson.id}`} className="block">
          <Panel className="anim-glow flex items-center gap-3 border-brand/40 p-4">
            <span className="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-brand text-white">
              <IconPlay />
            </span>
            <span className="min-w-0 flex-1">
              <span className="block text-[11px] font-bold uppercase tracking-[0.14em] text-brand">
                {nextPath ? STAGE_LABEL[nextPath.stage] : "Continue"}
              </span>
              <span className="block truncate text-base font-extrabold">{nextLesson.title}</span>
              <span className="block truncate text-xs text-muted">{nextLesson.goal}</span>
            </span>
            <span className="shrink-0 rounded-xl bg-brandsoft px-3 py-2 text-xs font-bold text-brandfg">
              Start
            </span>
          </Panel>
        </Link>
      ) : (
        <EmptyState
          icon="🏁"
          title="Roadmap complete"
          body="You finished every lesson. Replay any lesson for a higher score or clear your Review Deck."
        />
      )}

      {/* Hint economy */}
      <Panel className="p-4">
        <SectionTitle
          icon={<IconSparkle className="h-4 w-4" />}
          title="Hint economy"
          sub="Hints are expensive on purpose."
          right={<Pill tone="brand">{profile.hintsUsed} used</Pill>}
        />
        <div className="grid grid-cols-3 gap-2">
          {[
            { tier: "small", cost: state.hintCosts.small, label: "50 / 50", desc: "Removes one wrong option" },
            { tier: "medium", cost: state.hintCosts.medium, label: "Sounds", desc: "Shows romanization" },
            { tier: "large", cost: state.hintCosts.large, label: "Reveal", desc: "Shows the answer" },
          ].map((h) => {
            const afford = profile.xpBalance >= h.cost;
            return (
              <div
                key={h.tier}
                className={`rounded-2xl border p-2.5 ${
                  afford ? "border-brand/40 bg-brandsoft/50" : "border-line bg-surface2"
                }`}
              >
                <div className="flex items-center gap-1 text-[11px] font-black">
                  <IconBolt className={`h-3 w-3 ${afford ? "text-brand" : "text-muted"}`} />
                  {h.cost} XP
                </div>
                <div className="mt-1 text-sm font-extrabold">{h.label}</div>
                <div className="text-[11px] leading-snug text-muted">{h.desc}</div>
              </div>
            );
          })}
        </div>
        <p className="mt-3 text-[11px] leading-relaxed text-muted">
          1 correct answer = {state.xpPerCorrect} XP, so <b>6 correct answers buy one small hint</b>. A hinted
          question never pays XP — think first, spend later.
        </p>
      </Panel>

      {/* Onboarding for absolute beginners */}
      {done === 0 ? (
        <Panel className="p-4">
          <SectionTitle title="How this course works" sub="Never studied Korean? Perfect." />
          <ol className="space-y-2.5">
            {[
              {
                n: 1,
                t: "Learn the letters first",
                d: "Hangul is 40 letters that stack into blocks. You can learn to read in a few sessions — no romanization crutch needed after this stage.",
              },
              {
                n: 2,
                t: "Collect essential words",
                d: "Greetings, food, places, numbers, verbs. Every word is drilled with short quizzes, matching games and listening rounds.",
              },
              {
                n: 3,
                t: "Unlock grammar at 70%",
                d: "Score 70% or better to pass a lesson. Finish 4 word lessons with 70%+ accuracy and the Grammar Engine opens — particles, tense and connectors, while new words keep coming.",
              },
              {
                n: 4,
                t: "Speak full sentences",
                d: "Build real sentences chunk by chunk: introductions, ordering food, asking for directions.",
              },
            ].map((step) => (
              <li key={step.n} className="flex gap-3">
                <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-xl bg-brandsoft text-xs font-black text-brandfg">
                  {step.n}
                </span>
                <span>
                  <span className="block text-sm font-extrabold">{step.t}</span>
                  <span className="block text-xs leading-relaxed text-muted">{step.d}</span>
                </span>
              </li>
            ))}
          </ol>
        </Panel>
      ) : null}

      {/* Roadmap */}
      <div>
        <SectionTitle
          icon={<IconMap className="h-4 w-4" />}
          title="Learning roadmap"
          sub="Alphabet → words → grammar → sentences"
        />
        <div className="space-y-3">
          {paths.map((p) => {
            const remaining = p.totalLessons - p.completedLessons;
            return (
              <Panel key={p.id} className={`p-4 ${p.locked ? "opacity-90" : ""}`}>
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0">
                    <div className="flex items-center gap-2">
                      <span
                        className="h-2.5 w-2.5 shrink-0 rounded-full"
                        style={{ background: p.color }}
                      />
                      <span className="text-[10px] font-black uppercase tracking-[0.16em] text-muted">
                        {STAGE_LABEL[p.stage]}
                      </span>
                    </div>
                    <h3 className="mt-0.5 truncate text-[17px] font-extrabold tracking-tight">{p.title}</h3>
                    <p className="text-xs text-muted">{p.tagline}</p>
                  </div>
                  {p.locked ? (
                    <Pill tone="warn">
                      <IconLock className="h-3 w-3" /> Locked
                    </Pill>
                  ) : p.percent === 100 ? (
                    <Pill tone="good">
                      <IconCheck className="h-3 w-3" /> Done
                    </Pill>
                  ) : (
                    <Pill tone="brand">{p.percent}%</Pill>
                  )}
                </div>

                <div className="mt-3">
                  <div className="mb-1.5 flex items-center justify-between text-[11px] font-semibold text-muted">
                    <span>
                      {p.completedLessons}/{p.totalLessons} lessons · {remaining} remaining
                    </span>
                    <span>{p.accuracy > 0 ? `${p.accuracy}% accuracy` : "not started"}</span>
                  </div>
                  <Bar value={p.percent} color={p.color} height={9} />
                </div>

                {p.locked ? (
                  <div className="mt-3 rounded-2xl border border-dashed border-warn/50 bg-warnsoft/40 p-3">
                    <p className="text-[11px] font-bold uppercase tracking-wide text-warn">Unlock condition</p>
                    <p className="mt-0.5 text-xs text-fg">{p.unlockLabel}</p>
                    <p className="mt-1 text-[11px] text-muted">
                      Progress: {p.unlockDone}/{p.unlockNeed} lessons · needs ≥70% accuracy in that stage
                    </p>
                  </div>
                ) : p.firstAvailableLessonId ? (
                  <div className="mt-3 flex items-center justify-between gap-2">
                    <span className="truncate text-xs font-semibold text-muted">
                      Next: {getLesson(p.firstAvailableLessonId)?.title}
                    </span>
                    <Link href={`/path/${p.id}`}>
                      <Btn size="sm" variant="soft">
                        Open map
                      </Btn>
                    </Link>
                  </div>
                ) : (
                  <div className="mt-3 flex items-center justify-between gap-2">
                    <span className="text-xs font-semibold text-good">Path complete — replay for a better score</span>
                    <Link href={`/path/${p.id}`}>
                      <Btn size="sm" variant="soft">
                        Open map
                      </Btn>
                    </Link>
                  </div>
                )}
              </Panel>
            );
          })}
        </div>
      </div>

      {/* Achievements */}
      <div>
        <SectionTitle
          icon={<IconTrophy className="h-4 w-4" />}
          title="Achievements"
          sub={`${state.achievements.filter((a) => a.earned).length} / ${state.achievements.length} earned`}
          right={
            <Link href="/profile">
              <Btn size="sm" variant="ghost">
                See all
              </Btn>
            </Link>
          }
        />
        <div className="grid grid-cols-2 gap-2">
          {state.achievements.slice(0, 4).map((a) => (
            <Panel key={a.id} className={`p-3 ${a.earned ? "border-good/40" : ""}`}>
              <div className="flex items-center gap-2">
                <span
                  className={`flex h-8 w-8 items-center justify-center rounded-xl text-sm ${
                    a.earned ? "bg-goodsoft text-good" : "bg-surface2 text-muted"
                  }`}
                >
                  {a.earned ? <IconCheck className="h-4 w-4" /> : <IconLock className="h-4 w-4" />}
                </span>
                <div className="min-w-0">
                  <div className="truncate text-[13px] font-extrabold">{a.title}</div>
                  <div className="truncate text-[11px] text-muted">
                    {a.progress}/{a.target}
                  </div>
                </div>
              </div>
            </Panel>
          ))}
        </div>
      </div>
    </div>
  );
}

function LoadingHome() {
  return (
    <div className="space-y-4">
      <div className="h-[132px] animate-pulse rounded-3xl border border-line bg-surface" />
      <div className="h-[76px] animate-pulse rounded-3xl border border-line bg-surface" />
      <div className="h-[150px] animate-pulse rounded-3xl border border-line bg-surface" />
      <div className="h-[150px] animate-pulse rounded-3xl border border-line bg-surface" />
      <p className="text-center text-xs text-muted">Loading your roadmap…</p>
    </div>
  );
}
