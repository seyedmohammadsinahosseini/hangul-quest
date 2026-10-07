import { defineConfig, globalIgnores } from "eslint/config";
import nextCoreWebVitals from "eslint-config-next/core-web-vitals";

export default defineConfig([
  ...nextCoreWebVitals,
  globalIgnores([".next/**", "drizzle/meta/**", "out/**", "build/**", "next-env.d.ts"]),
  {
    // The lesson player reacts to hint presses and match selections through
    // effects: the hint buttons live above the question component and flipping a
    // hint flag is an external trigger, not derived render state. The rule stays
    // enabled everywhere else; the refactor to an event-driven question component
    // is tracked in ../docs/ROADMAP.md.
    files: ["src/components/LessonPlayer.tsx"],
    rules: {
      "react-hooks/set-state-in-effect": "warn",
    },
  },
]);
