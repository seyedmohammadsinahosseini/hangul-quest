import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { randomUUID } from "node:crypto";

import {
  ensureProfile,
  loadState,
  patchProfile,
  recordLessonResult,
  recordReview,
  resetProgress,
  spendHint,
  type HintTier,
} from "@/lib/engine";

export const runtime = "nodejs";

const COOKIE = "hq_handle";

type Body =
  | { type: "lesson"; lessonId: string; answers: { cardId: string; correct: boolean; hint: HintTier | null }[] }
  | { type: "hint"; tier: HintTier }
  | { type: "review"; entries: { cardId: string; correct: boolean }[] }
  | { type: "profile"; displayName?: string; theme?: "light" | "dark"; dailyGoal?: number }
  | { type: "reset" };

async function profileFromRequest() {
  const jar = await cookies();
  const handle = jar.get(COOKIE)?.value ?? `guest-${randomUUID()}`;
  jar.set(COOKIE, handle, { httpOnly: true, sameSite: "lax", path: "/", maxAge: 60 * 60 * 24 * 365 });
  return ensureProfile(handle);
}

export async function POST(req: Request) {
  let body: Body;
  try {
    body = (await req.json()) as Body;
  } catch {
    return NextResponse.json({ error: "invalid json" }, { status: 400 });
  }

  try {
    const profile = await profileFromRequest();

    if (body.type === "lesson") {
      if (!body.lessonId || !Array.isArray(body.answers)) {
        return NextResponse.json({ error: "lessonId and answers are required" }, { status: 400 });
      }
      const result = await recordLessonResult(profile, {
        lessonId: body.lessonId,
        answers: body.answers.map((a) => ({
          cardId: String(a.cardId),
          correct: Boolean(a.correct),
          hint: a.hint === "small" || a.hint === "medium" || a.hint === "large" ? a.hint : null,
        })),
      });
      return NextResponse.json(result);
    }

    if (body.type === "review") {
      const entries = Array.isArray(body.entries)
        ? body.entries.map((e) => ({ cardId: String(e.cardId), correct: Boolean(e.correct) }))
        : [];
      const state = await recordReview(profile, entries);
      return NextResponse.json({ state });
    }

    if (body.type === "hint") {
      const tier: HintTier = body.tier;
      if (tier !== "small" && tier !== "medium" && tier !== "large") {
        return NextResponse.json({ error: "invalid hint tier" }, { status: 400 });
      }
      const result = await spendHint(profile, tier);
      if (!result.ok) return NextResponse.json({ error: result.error }, { status: 409 });
      return NextResponse.json({ cost: result.cost, state: result.state });
    }

    if (body.type === "profile") {
      const state = await patchProfile(profile, {
        displayName: body.displayName,
        theme: body.theme,
        dailyGoal: body.dailyGoal,
      });
      return NextResponse.json({ state });
    }

    if (body.type === "reset") {
      const state = await resetProgress(profile);
      return NextResponse.json({ state });
    }

    return NextResponse.json({ error: "unknown action" }, { status: 400 });
  } catch (err) {
    const message = err instanceof Error ? err.message : "action failed";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}

export async function GET() {
  const profile = await profileFromRequest();
  return NextResponse.json({ state: await loadState(profile) });
}
