import { NextResponse } from "next/server";
import { eq } from "drizzle-orm";
import { cookies } from "next/headers";

import { db } from "@/db";
import { profiles } from "@/db/schema";
import { leaderboard } from "@/lib/engine";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET() {
  const rows = await leaderboard();
  const jar = await cookies();
  const handle = jar.get("hq_handle")?.value;
  const me = handle
    ? await db.select({ id: profiles.id }).from(profiles).where(eq(profiles.handle, handle)).limit(1)
    : [];
  const myId = me[0]?.id;
  const myRank = myId ? rows.findIndex((r) => r.id === myId) + 1 : 0;
  return NextResponse.json({
    rows: rows.map((r) => ({
      displayName: r.displayName,
      xp: r.xpEarned,
      streak: r.streak,
      accuracy:
        r.correctAnswers + r.wrongAnswers === 0
          ? 0
          : Math.round((r.correctAnswers / (r.correctAnswers + r.wrongAnswers)) * 100),
      isMe: r.id === myId,
    })),
    myRank,
  } satisfies { rows: unknown[]; myRank: number });
}
