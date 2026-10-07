import type { Metadata, Viewport } from "next";
import type { ReactNode } from "react";
import "./globals.css";

import { Shell } from "@/components/Shell";
import { AppProvider } from "@/lib/store";

export const metadata: Metadata = {
  title: "Hangul Quest — Learn Korean From Zero",
  description:
    "A mobile-first Korean course in English: hangul, essential words, grammar and real sentences, taught with short quizzes, games and tests.",
  applicationName: "Hangul Quest",
};

export const viewport: Viewport = {
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#f4f6fb" },
    { media: "(prefers-color-scheme: dark)", color: "#070b16" },
  ],
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className="antialiased">
        <AppProvider>
          <Shell>{children}</Shell>
        </AppProvider>
      </body>
    </html>
  );
}
