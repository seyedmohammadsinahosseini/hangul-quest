"use client";

import { useState } from "react";

import { SectionTitle } from "@/components/Shell";
import { IconGrid, IconVolume } from "@/components/icons";
import { Panel, Pill } from "@/components/ui";
import { HANGUL_TABLE } from "@/lib/curriculum";
import { speak, speechSupported } from "@/lib/store";

export default function AlphabetPage() {
  const [active, setActive] = useState<string | null>(null);
  const supported = typeof window !== "undefined" ? speechSupported() : false;

  return (
    <div className="space-y-5">
      <Panel className="p-4">
        <SectionTitle
          icon={<IconGrid className="h-4 w-4" />}
          title="Hangul chart"
          sub="Tap any letter to hear it."
          right={supported ? <Pill tone="good">audio ready</Pill> : <Pill tone="warn">no TTS</Pill>}
        />
        <p className="text-xs text-muted">
          Korean is written in blocks: a consonant and a vowel always sit together, and a final consonant can
          be added underneath. Every block you will ever read is built from these 40 letters.
        </p>
      </Panel>

      {HANGUL_TABLE.map((group) => (
        <div key={group.group}>
          <h2 className="mb-2 px-1 text-[11px] font-black uppercase tracking-[0.16em] text-muted">
            {group.group}
          </h2>
          <div className="grid grid-cols-4 gap-2">
            {group.items.map((item) => {
              const [letter, sound] = item.split(" ");
              const isActive = active === item;
              return (
                <button
                  key={item}
                  type="button"
                  onClick={() => {
                    setActive(item);
                    speak(letter);
                  }}
                  className={`flex flex-col items-center gap-0.5 rounded-2xl border px-2 py-3 transition active:scale-95
                    ${isActive ? "border-brand bg-brandsoft" : "border-line bg-surface hover:border-brand/50"}`}
                >
                  <span className="hangul text-2xl font-bold leading-none">{letter}</span>
                  <span className="text-[11px] font-bold text-muted">{sound}</span>
                  <IconVolume className={`h-3 w-3 ${isActive ? "text-brand" : "text-muted/50"}`} />
                </button>
              );
            })}
          </div>
        </div>
      ))}

      <Panel className="p-4">
        <h2 className="text-sm font-black">How a block is assembled</h2>
        <div className="mt-3 flex items-center justify-center gap-2">
          {["ㅎ", "+", "ㅏ", "+", "ㄴ", "=", "한"].map((piece, i) => (
            <span
              key={i}
              className={`hangul flex h-12 w-12 items-center justify-center rounded-2xl text-xl font-bold ${
                piece === "한" ? "bg-brand text-white" : piece === "+" || piece === "=" ? "w-4 text-muted" : "bg-surface2"
              }`}
            >
              {piece}
            </span>
          ))}
        </div>
        <p className="mt-3 text-center text-xs text-muted">
          한 = ㅎ + ㅏ + ㄴ → “han”. The final consonant is called <b>batchim</b>.
        </p>
      </Panel>
    </div>
  );
}
