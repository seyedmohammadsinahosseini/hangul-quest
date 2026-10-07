import "dotenv/config";
import { defineConfig } from "drizzle-kit";

/**
 * Local Postgres URL. Keep it in `.env` (never committed) — copy `.env.example`
 * and adjust the credentials to match your machine.
 */
const url = process.env.DATABASE_URL;

if (!url) {
  throw new Error(
    "DATABASE_URL is not set. Copy web/.env.example to web/.env and fill in your Postgres URL.",
  );
}

export default defineConfig({
  dialect: "postgresql",
  schema: "./src/db/schema.ts",
  out: "./drizzle",
  dbCredentials: { url },
  strict: true,
  verbose: true,
});
