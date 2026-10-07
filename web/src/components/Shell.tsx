"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import type { ReactNode } from "react";

import {
  IconBolt,
  IconBook,
  IconFlame,
  IconGrid,
  IconMap,
  IconMoon,
  IconSun,
  IconTarget,
  IconUser,
} from "@/components/icons";
import { useApp } from "@/lib/store";

const TABS = [
  { href: "/", label: "Path", Icon: IconMap },
  { href: "/alphabet", label: "Hangul", Icon: IconGrid },
  { href: "/review", label: "Review", Icon: IconBook },
  { href: "/profile", label: "You", Icon: IconUser },
];

export function Shell({ children }: { children: ReactNode }) {
  const { state, setTheme } = useApp();
  const pathname = usePathname();
  const dark = state?.profile.theme === "dark";
  const reviewCount = state?.review.length ?? 0;

  return (
    <div className="min-h-dvh w-full">
      <div className="mx-auto flex min-h-dvh w-full max-w-[560px] flex-col">
        <header className="sticky top-0 z-30 border-b border-line/70 bg-bg/85 backdrop-blur-xl">
          <div className="flex items-center justify-between gap-2 px-4 py-3">
            <Link href="/" className="flex items-center gap-2.5">
              <span className="hangul flex h-9 w-9 items-center justify-center rounded-xl bg-brand text-base font-bold text-white">
                한
              </span>
              <span className="leading-tight">
                <span className="block text-[15px] font-extrabold tracking-tight">Hangul Quest</span>
                <span className="block text-[10px] font-semibold uppercase tracking-[0.16em] text-muted">
                  Korean from zero
                </span>
              </span>
            </Link>

            <div className="flex items-center gap-1.5">
              <span className="inline-flex items-center gap-1 rounded-full border border-line bg-surface px-2.5 py-1.5 text-xs font-bold text-warn">
                <IconFlame className="h-3.5 w-3.5" />
                {state?.profile.streak ?? 0}
              </span>
              <span className="inline-flex items-center gap-1 rounded-full border border-line bg-surface px-2.5 py-1.5 text-xs font-bold text-brand">
                <IconBolt className="h-3.5 w-3.5" />
                {state?.profile.xpBalance ?? 0}
              </span>
              <button
                type="button"
                onClick={() => setTheme(dark ? "light" : "dark")}
                aria-label={dark ? "Switch to light theme" : "Switch to dark theme"}
                className="inline-flex h-9 w-9 items-center justify-center rounded-full border border-line bg-surface text-muted transition hover:text-fg active:scale-90"
              >
                {dark ? <IconSun className="h-4 w-4" /> : <IconMoon className="h-4 w-4" />}
              </button>
            </div>
          </div>
        </header>

        <main className="flex-1 px-4 pb-28 pt-4">{children}</main>

        <nav className="fixed bottom-0 left-1/2 z-30 w-full max-w-[560px] -translate-x-1/2 border-t border-line/70 bg-surface/95 pb-[env(safe-area-inset-bottom)] backdrop-blur-xl">
          <div className="grid grid-cols-4">
            {TABS.map(({ href, label, Icon }) => {
              const active = href === "/" ? pathname === "/" : pathname.startsWith(href);
              return (
                <Link
                  key={href}
                  href={href}
                  className={`relative flex flex-col items-center gap-1 py-2.5 text-[10px] font-bold uppercase tracking-wide transition ${
                    active ? "text-brand" : "text-muted hover:text-fg"
                  }`}
                >
                  <span className="relative">
                    <Icon className="h-[19px] w-[19px]" />
                    {label === "Review" && reviewCount > 0 ? (
                      <span className="absolute -right-2 -top-1.5 flex h-4 min-w-4 items-center justify-center rounded-full bg-bad px-1 text-[9px] font-extrabold text-white">
                        {reviewCount > 9 ? "9+" : reviewCount}
                      </span>
                    ) : null}
                  </span>
                  {label}
                  {active ? (
                    <span className="absolute inset-x-6 top-0 h-0.5 rounded-full bg-brand" />
                  ) : null}
                </Link>
              );
            })}
          </div>
        </nav>
      </div>
    </div>
  );
}

export function SectionTitle({
  icon,
  title,
  sub,
  right,
}: {
  icon?: ReactNode;
  title: string;
  sub?: string;
  right?: ReactNode;
}) {
  return (
    <div className="mb-3 flex items-end justify-between gap-3">
      <div className="flex items-center gap-2">
        {icon ? <span className="text-brand">{icon}</span> : null}
        <div>
          <h2 className="text-base font-extrabold tracking-tight">{title}</h2>
          {sub ? <p className="text-xs text-muted">{sub}</p> : null}
        </div>
      </div>
      {right}
    </div>
  );
}

export function ScoreTone({ score }: { score: number }) {
  const tone = score >= 90 ? "text-good" : score >= 70 ? "text-brand" : "text-bad";
  return (
    <span className={`inline-flex items-center gap-1 text-xs font-bold ${tone}`}>
      <IconTarget className="h-3.5 w-3.5" />
      {score}%
    </span>
  );
}
