"use client";

import type { ButtonHTMLAttributes, ReactNode } from "react";
import { speak } from "@/lib/store";

type BtnProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: "primary" | "soft" | "ghost" | "danger" | "good";
  size?: "sm" | "md" | "lg";
  block?: boolean;
};

const VARIANTS: Record<string, string> = {
  primary:
    "bg-brand text-white hover:brightness-110 active:brightness-95 shadow-[0_10px_24px_-14px_var(--brand)]",
  soft: "bg-surface2 text-fg hover:bg-line/60 border border-line",
  ghost: "bg-transparent text-muted hover:text-fg hover:bg-surface2",
  danger: "bg-bad text-white hover:brightness-110",
  good: "bg-good text-white hover:brightness-110",
};

const SIZES: Record<string, string> = {
  sm: "px-3 py-1.5 text-xs rounded-xl gap-1.5",
  md: "px-4 py-2.5 text-sm rounded-2xl gap-2",
  lg: "px-5 py-3.5 text-base rounded-2xl gap-2",
};

export function Btn({ variant = "primary", size = "md", block, className = "", ...rest }: BtnProps) {
  return (
    <button
      {...rest}
      className={`inline-flex items-center justify-center font-semibold transition-all duration-150
        disabled:opacity-40 disabled:pointer-events-none active:scale-[0.97]
        ${VARIANTS[variant]} ${SIZES[size]} ${block ? "w-full" : ""} ${className}`}
    />
  );
}

export function Panel({
  children,
  className = "",
  onClick,
}: {
  children: ReactNode;
  className?: string;
  onClick?: () => void;
}) {
  return (
    <div
      onClick={onClick}
      className={`rounded-3xl border border-line bg-surface shadow-card ${className}`}
    >
      {children}
    </div>
  );
}

export function Bar({
  value,
  color = "var(--brand)",
  className = "",
  height = 8,
}: {
  value: number;
  color?: string;
  className?: string;
  height?: number;
}) {
  const pct = Math.max(0, Math.min(100, value));
  return (
    <div
      className={`w-full overflow-hidden rounded-full bg-surface2 ${className}`}
      style={{ height }}
      role="progressbar"
      aria-valuenow={pct}
      aria-valuemin={0}
      aria-valuemax={100}
    >
      <div
        className="h-full rounded-full transition-[width] duration-700 ease-out"
        style={{ width: `${pct}%`, background: color }}
      />
    </div>
  );
}

export function Ring({
  value,
  size = 64,
  stroke = 7,
  color = "var(--brand)",
  children,
}: {
  value: number;
  size?: number;
  stroke?: number;
  color?: string;
  children?: ReactNode;
}) {
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const pct = Math.max(0, Math.min(100, value));
  return (
    <div className="relative inline-flex items-center justify-center" style={{ width: size, height: size }}>
      <svg width={size} height={size} className="-rotate-90">
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="var(--surface-2)" strokeWidth={stroke} />
        <circle
          cx={size / 2}
          cy={size / 2}
          r={r}
          fill="none"
          stroke={color}
          strokeWidth={stroke}
          strokeLinecap="round"
          strokeDasharray={c}
          strokeDashoffset={c - (c * pct) / 100}
          style={{ transition: "stroke-dashoffset 0.8s cubic-bezier(.22,1,.36,1)" }}
        />
      </svg>
      <div className="absolute inset-0 flex items-center justify-center">{children}</div>
    </div>
  );
}

export function Pill({
  children,
  tone = "neutral",
  className = "",
}: {
  children: ReactNode;
  tone?: "neutral" | "brand" | "good" | "bad" | "warn";
  className?: string;
}) {
  const tones: Record<string, string> = {
    neutral: "bg-surface2 text-muted border-line",
    brand: "bg-brandsoft text-brandfg border-transparent",
    good: "bg-goodsoft text-good border-transparent",
    bad: "bg-badsoft text-bad border-transparent",
    warn: "bg-warnsoft text-warn border-transparent",
  };
  return (
    <span
      className={`inline-flex items-center gap-1 rounded-full border px-2.5 py-1 text-[11px] font-bold ${tones[tone]} ${className}`}
    >
      {children}
    </span>
  );
}

export function Speaker({ text, size = "md" }: { text: string; size?: "sm" | "md" | "lg" }) {
  const dims = size === "lg" ? "h-12 w-12 text-xl" : size === "sm" ? "h-7 w-7 text-xs" : "h-9 w-9 text-sm";
  return (
    <button
      type="button"
      onClick={() => speak(text)}
      aria-label={`Play pronunciation for ${text}`}
      className={`${dims} inline-flex shrink-0 items-center justify-center rounded-full border border-line bg-surface2 text-fg transition hover:bg-brandsoft hover:text-brandfg active:scale-90`}
    >
      🔊
    </button>
  );
}

export function Stat({ label, value, icon }: { label: string; value: ReactNode; icon?: ReactNode }) {
  return (
    <div className="rounded-2xl border border-line bg-surface2 px-3 py-2.5">
      <div className="text-[11px] font-semibold uppercase tracking-wide text-muted">
        {icon ? <span className="mr-1">{icon}</span> : null}
        {label}
      </div>
      <div className="mt-0.5 text-lg font-extrabold text-fg">{value}</div>
    </div>
  );
}

export function EmptyState({ icon, title, body }: { icon: string; title: string; body: string }) {
  return (
    <div className="flex flex-col items-center gap-2 rounded-3xl border border-dashed border-line bg-surface/60 px-6 py-10 text-center">
      <div className="anim-float text-4xl">{icon}</div>
      <div className="text-base font-bold">{title}</div>
      <p className="max-w-[34ch] text-sm text-muted">{body}</p>
    </div>
  );
}
