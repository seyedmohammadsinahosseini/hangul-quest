import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { randomUUID } from "node:crypto";

import { ensureProfile, loadState } from "@/lib/engine";

export const runtime = "nodejs";

const COOKIE = "hq_handle";

async function resolveProfile() {
  const jar = await cookies();
  let handle = jar.get(COOKIE)?.value;
  if (!handle) {
    handle = `guest-${randomUUID()}`;
    jar.set(COOKIE, handle, {
      httpOnly: true,
      sameSite: "lax",
      path: "/",
      maxAge: 60 * 60 * 24 * 365,
    });
  }
  const profile = await ensureProfile(handle);
  return { profile, handle };
}

export async function GET() {
  try {
    const { profile, handle } = await resolveProfile();
    const state = await loadState(profile);
    return NextResponse.json({ handle, state });
  } catch (err) {
    const message = err instanceof Error ? err.message : "failed to load state";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}

export async function POST(req: Request) {
  try {
    const body = (await req.json().catch(() => ({}))) as { displayName?: string };
    const jar = await cookies();
    const handle = jar.get(COOKIE)?.value ?? `guest-${randomUUID()}`;
    jar.set(COOKIE, handle, {
      httpOnly: true,
      sameSite: "lax",
      path: "/",
      maxAge: 60 * 60 * 24 * 365,
    });
    const profile = await ensureProfile(handle, body.displayName);
    const state = await loadState(profile);
    return NextResponse.json({ handle, state });
  } catch (err) {
    const message = err instanceof Error ? err.message : "failed to create profile";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
