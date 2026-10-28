"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";

import type { AppState } from "@/lib/types";

export type HintTier = "small" | "medium" | "large";
export type LessonAnswer = { cardId: string; correct: boolean; hint: HintTier | null };

type Ctx = {
  state: AppState | null;
  loading: boolean;
  error: string | null;
  refresh: () => Promise<void>;
  setTheme: (theme: "light" | "dark") => Promise<void>;
  saveProfile: (patch: { displayName?: string; dailyGoal?: number }) => Promise<void>;
  submitLesson: (lessonId: string, answers: LessonAnswer[]) => Promise<{
    score: number;
    passed: boolean;
    correct: number;
    total: number;
    xpGained: number;
  } | null>;
  buyHint: (tier: HintTier) => Promise<{ ok: boolean; error?: string }>;
  recordReview: (entries: { cardId: string; correct: boolean }[]) => Promise<void>;
  reset: () => Promise<void>;
};

const AppCtx = createContext<Ctx | null>(null);

const THEME_KEY = "hq_theme";

function applyTheme(theme: "light" | "dark") {
  if (typeof document === "undefined") return;
  const root = document.documentElement;
  root.classList.toggle("dark", theme === "dark");
  root.style.colorScheme = theme;
  try {
    localStorage.setItem(THEME_KEY, theme);
  } catch {
    /* ignore */
  }
}

export function AppProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<AppState | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const saved = (typeof localStorage !== "undefined" && localStorage.getItem(THEME_KEY)) as
      | "light"
      | "dark"
      | null;
    if (saved) applyTheme(saved);
    else if (typeof window !== "undefined" && window.matchMedia?.("(prefers-color-scheme: dark)").matches) {
      applyTheme("dark");
    }
  }, []);

  const refresh = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetch("/api/state", { cache: "no-store" });
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error ?? "Could not load your progress");
      setState(data.state as AppState);
      applyTheme((data.state as AppState).profile.theme);
      setError(null);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Network error");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    // Load the profile once on mount. `refresh` is a stable useCallback, so this
    // runs exactly once per session; the state it sets comes from the API, not
    // from render-time derivations.
    // eslint-disable-next-line react-hooks/set-state-in-effect -- initial fetch on mount
    void refresh();
  }, [refresh]);

  const act = useCallback(async (body: unknown): Promise<any> => {
    const res = await fetch("/api/action", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(body),
    });
    const data = await res.json();
    if (!res.ok) throw Object.assign(new Error(data?.error ?? "Action failed"), { status: res.status });
    return data;
  }, []);

  const setTheme = useCallback(
    async (theme: "light" | "dark") => {
      applyTheme(theme);
      setState((prev) => (prev ? { ...prev, profile: { ...prev.profile, theme } } : prev));
      try {
        await act({ type: "profile", theme });
      } catch {
        /* keep optimistic theme */
      }
    },
    [act],
  );

  const saveProfile = useCallback(
    async (patch: { displayName?: string; dailyGoal?: number }) => {
      const data = await act({ type: "profile", ...patch });
      if (data?.state) setState(data.state as AppState);
    },
    [act],
  );

  const submitLesson = useCallback(
    async (lessonId: string, answers: LessonAnswer[]) => {
      const data = await act({ type: "lesson", lessonId, answers });
      if (data?.state) setState(data.state as AppState);
      return data
        ? {
            score: data.score as number,
            passed: data.passed as boolean,
            correct: data.correct as number,
            total: data.total as number,
            xpGained: data.xpGained as number,
          }
        : null;
    },
    [act],
  );

  const buyHint = useCallback(
    async (tier: HintTier) => {
      try {
        const data = await act({ type: "hint", tier });
        if (data?.state) setState(data.state as AppState);
        return { ok: true };
      } catch (e) {
        return { ok: false, error: e instanceof Error ? e.message : "Not enough XP" };
      }
    },
    [act],
  );

  const recordReview = useCallback(
    async (entries: { cardId: string; correct: boolean }[]) => {
      const data = await act({ type: "review", entries });
      if (data?.state) setState(data.state as AppState);
    },
    [act],
  );

  const reset = useCallback(async () => {
    const data = await act({ type: "reset" });
    if (data?.state) setState(data.state as AppState);
  }, [act]);

  const value = useMemo<Ctx>(
    () => ({
      state,
      loading,
      error,
      refresh,
      setTheme,
      saveProfile,
      submitLesson,
      buyHint,
      recordReview,
      reset,
    }),
    [state, loading, error, refresh, setTheme, saveProfile, submitLesson, buyHint, recordReview, reset],
  );

  return <AppCtx.Provider value={value}>{children}</AppCtx.Provider>;
}

export function useApp(): Ctx {
  const ctx = useContext(AppCtx);
  if (!ctx) throw new Error("useApp must be used inside AppProvider");
  return ctx;
}

/* ---------------- speech ---------------- */

export function speak(text: string, rate = 0.85): boolean {
  if (typeof window === "undefined" || !("speechSynthesis" in window) || !text.trim()) return false;
  try {
    const synthesis = window.speechSynthesis;
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = "ko-KR";
    utterance.rate = rate;

    // Voices are populated asynchronously by some browsers. Use a Korean voice
    // when available, while still letting the browser's Korean locale fallback
    // speak if its voice list is not ready yet.
    const voices = synthesis.getVoices();
    const ko = voices.find((v) => v.lang?.toLowerCase().startsWith("ko"));
    if (ko) utterance.voice = ko;

    // Avoid cancelling an idle synthesizer. In Chromium, cancel() followed by
    // speak() in the same task can occasionally leave the speech queue muted.
    const interrupting = synthesis.speaking || synthesis.pending;
    if (interrupting) synthesis.cancel();
    synthesis.resume();
    if (interrupting) {
      window.setTimeout(() => {
        synthesis.resume();
        synthesis.speak(utterance);
      }, 80);
    } else {
      synthesis.speak(utterance);
    }
    return true;
  } catch {
    return false;
  }
}

export function speechSupported(): boolean {
  return typeof window !== "undefined" && "speechSynthesis" in window;
}

export function hasKoreanVoice(): boolean {
  if (!speechSupported()) return false;
  return window.speechSynthesis.getVoices().some((v) => v.lang?.toLowerCase().startsWith("ko"));
}

/** True once the browser reports a usable ko-KR voice (voices load async). */
export function useKoreanVoice(): boolean {
  const [ready, setReady] = useState<boolean>(false);
  useEffect(() => {
    if (!speechSupported()) return;
    const check = () => setReady(hasKoreanVoice());
    check();
    window.speechSynthesis.addEventListener?.("voiceschanged", check);
    const t = window.setTimeout(check, 600);
    return () => {
      window.speechSynthesis.removeEventListener?.("voiceschanged", check);
      window.clearTimeout(t);
    };
  }, []);
  return ready;
}
