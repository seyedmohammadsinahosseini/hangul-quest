"use client";

import { useEffect, useState } from "react";

import { SectionTitle } from "@/components/Shell";
import {
  IconBolt,
  IconCheck,
  IconFlame,
  IconLock,
  IconMoon,
  IconSun,
  IconTarget,
  IconTrophy,
} from "@/components/icons";
import { Bar, Btn, Panel, Pill, Stat } from "@/components/ui";
import { useApp } from "@/lib/store";

type Row = {
  displayName: string;
  xp: number;
  streak: number;
  accuracy: number;
  isMe: boolean;
};

export default function ProfilePage() {
  const { state, setTheme, saveProfile, reset } = useApp();
  // Derived draft: the field shows whatever the learner typed, and falls back to
  // the value stored on the server (so we never mirror server state in an effect).
  const [nameDraft, setNameDraft] = useState<string | null>(null);
  const name = nameDraft ?? state?.profile.displayName ?? "";
  const [rows, setRows] = useState<Row[]>([]);
  const [myRank, setMyRank] = useState(0);
  const [confirmReset, setConfirmReset] = useState(false);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    let alive = true;
    fetch("/api/leaderboard", { cache: "no-store" })
      .then((r) => r.json())
      .then((d) => {
        if (!alive) return;
        setRows(d.rows ?? []);
        setMyRank(d.myRank ?? 0);
      })
      .catch(() => undefined);
    return () => {
      alive = false;
    };
  }, [state?.profile.xpEarned]);

  if (!state) {
    return <div className="h-80 animate-pulse rounded-3xl border border-line bg-surface" />;
  }

  const { profile, achievements } = state;
  const earned = achievements.filter((a) => a.earned).length;
  const dark = profile.theme === "dark";

  return (
    <div className="space-y-5">
      <Panel className="p-4">
        <div className="flex items-center gap-3">
          <span className="hangul flex h-14 w-14 items-center justify-center rounded-2xl bg-brand text-2xl font-bold text-white">
            {profile.displayName.slice(0, 1).toUpperCase() || "한"}
          </span>
          <div className="min-w-0 flex-1">
            <h1 className="truncate text-xl font-black tracking-tight">{profile.displayName}</h1>
            <p className="text-xs text-muted">
              Learning since {new Date(profile.joinedAt).toLocaleDateString("en-US", { month: "short", year: "numeric" })}
            </p>
            <div className="mt-1.5 flex flex-wrap gap-1.5">
              <Pill tone="brand">
                <IconBolt className="h-3 w-3" /> {profile.xpEarned} XP earned
              </Pill>
              <Pill tone="warn">
                <IconFlame className="h-3 w-3" /> {profile.streak}d
              </Pill>
            </div>
          </div>
        </div>

        <div className="mt-4 grid grid-cols-2 gap-2">
          <Stat icon={<IconTarget className="inline h-3 w-3" />} label="Accuracy" value={`${profile.accuracy}%`} />
          <Stat icon={<IconBolt className="inline h-3 w-3" />} label="XP balance" value={profile.xpBalance} />
          <Stat label="Correct answers" value={profile.correctAnswers} />
          <Stat label="Hints used" value={profile.hintsUsed} />
        </div>

        <div className="mt-3">
          <div className="mb-1 flex items-center justify-between text-[11px] font-bold text-muted">
            <span>Today · {profile.xpToday}/{profile.dailyGoal} XP</span>
            <span>Longest streak {profile.longestStreak}d</span>
          </div>
          <Bar value={(profile.xpToday / profile.dailyGoal) * 100} color="var(--good)" />
        </div>
      </Panel>

      <div>
        <SectionTitle
          icon={<IconTrophy className="h-4 w-4" />}
          title="Achievements"
          sub={`${earned} of ${achievements.length} unlocked`}
        />
        <div className="space-y-2">
          {achievements.map((a) => (
            <Panel key={a.id} className={`flex items-center gap-3 p-3 ${a.earned ? "border-good/40" : ""}`}>
              <span
                className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-2xl ${
                  a.earned ? "bg-goodsoft text-good" : "bg-surface2 text-muted"
                }`}
              >
                {a.earned ? <IconCheck className="h-5 w-5" /> : <IconLock className="h-5 w-5" />}
              </span>
              <div className="min-w-0 flex-1">
                <div className="text-sm font-extrabold">{a.title}</div>
                <div className="truncate text-[11px] text-muted">{a.desc}</div>
                <div className="mt-1">
                  <Bar
                    value={(a.progress / a.target) * 100}
                    height={5}
                    color={a.earned ? "var(--good)" : "var(--brand)"}
                  />
                </div>
              </div>
              <span className="shrink-0 text-[11px] font-black text-muted">
                {a.progress}/{a.target}
              </span>
            </Panel>
          ))}
        </div>
      </div>

      <div>
        <SectionTitle
          icon={<IconTrophy className="h-4 w-4" />}
          title="Leaderboard"
          sub={myRank ? `You are #${myRank}` : "Top XP balances"}
        />
        <Panel className="divide-y divide-line">
          {rows.length === 0 ? (
            <p className="p-4 text-sm text-muted">No learners yet.</p>
          ) : (
            rows.map((r, i) => (
              <div
                key={`${r.displayName}-${i}`}
                className={`flex items-center gap-3 px-4 py-2.5 ${r.isMe ? "bg-brandsoft/40" : ""}`}
              >
                <span className="w-6 text-center text-sm font-black text-muted">{i + 1}</span>
                <span className={`min-w-0 flex-1 truncate text-sm font-bold ${r.isMe ? "text-brandfg" : ""}`}>
                  {r.displayName}
                  {r.isMe ? " · you" : ""}
                </span>
                <span className="text-xs font-bold text-muted">{r.accuracy}%</span>
                <span className="inline-flex items-center gap-1 text-xs font-black text-brand">
                  <IconBolt className="h-3 w-3" />
                  {r.xp}
                </span>
              </div>
            ))
          )}
        </Panel>
      </div>

      <div>
        <SectionTitle title="Settings" sub="Theme, goal and data" />
        <Panel className="space-y-4 p-4">
          <div>
            <label className="mb-1.5 block text-[11px] font-black uppercase tracking-wide text-muted">
              Display name
            </label>
            <div className="flex gap-2">
              <input
                value={name}
                onChange={(e) => setNameDraft(e.target.value)}
                maxLength={24}
                className="flex-1 rounded-2xl border border-line bg-surface2 px-4 py-2.5 text-sm font-semibold outline-none focus:border-brand"
              />
              <Btn
                onClick={async () => {
                  await saveProfile({ displayName: name });
                  setSaved(true);
                  window.setTimeout(() => setSaved(false), 1400);
                }}
              >
                {saved ? "Saved" : "Save"}
              </Btn>
            </div>
          </div>

          <div>
            <span className="mb-1.5 block text-[11px] font-black uppercase tracking-wide text-muted">Theme</span>
            <div className="grid grid-cols-2 gap-2">
              {(["light", "dark"] as const).map((t) => (
                <button
                  key={t}
                  type="button"
                  onClick={() => void setTheme(t)}
                  className={`flex items-center justify-center gap-2 rounded-2xl border px-3 py-2.5 text-sm font-bold capitalize transition ${
                    profile.theme === t
                      ? "border-brand bg-brandsoft text-brandfg"
                      : "border-line bg-surface2 text-muted"
                  }`}
                >
                  {t === "light" ? <IconSun className="h-4 w-4" /> : <IconMoon className="h-4 w-4" />}
                  {t}
                </button>
              ))}
            </div>
          </div>

          <div>
            <span className="mb-1.5 block text-[11px] font-black uppercase tracking-wide text-muted">
              Daily XP goal
            </span>
            <div className="flex flex-wrap gap-2">
              {[5, 10, 20, 30].map((g) => (
                <button
                  key={g}
                  type="button"
                  onClick={() => void saveProfile({ dailyGoal: g })}
                  className={`rounded-2xl border px-4 py-2 text-sm font-bold transition ${
                    profile.dailyGoal === g
                      ? "border-brand bg-brandsoft text-brandfg"
                      : "border-line bg-surface2 text-muted"
                  }`}
                >
                  {g} XP
                </button>
              ))}
            </div>
          </div>

          <div className="border-t border-line pt-3">
            {!confirmReset ? (
              <Btn variant="soft" block onClick={() => setConfirmReset(true)}>
                Reset all progress
              </Btn>
            ) : (
              <div className="space-y-2">
                <p className="text-xs font-bold text-bad">
                  This deletes every lesson score, XP and review word. Continue?
                </p>
                <div className="grid grid-cols-2 gap-2">
                  <Btn variant="ghost" onClick={() => setConfirmReset(false)}>
                    Cancel
                  </Btn>
                  <Btn variant="danger" onClick={() => void reset()}>
                    Yes, reset
                  </Btn>
                </div>
              </div>
            )}
          </div>
        </Panel>
      </div>
    </div>
  );
}
