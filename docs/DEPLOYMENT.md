# Deployment

The web client is a standard Next.js app with a PostgreSQL dependency, so it deploys to any Node
host. The walkthrough below uses **Vercel** (app) + **Neon** (database) because both have free
tiers and no infrastructure to babysit. The mobile client needs no deployment — it is distributed as
an APK / store build.

## 1. Create the database

1. Create a project on [neon.tech](https://neon.tech) (or Supabase, Railway, or any Postgres 14+).
2. Copy the **pooled** connection string; it looks like
   `postgresql://user:password@host/dbname?sslmode=require`.

Apply the committed migrations to it from your machine:

```bash
cd web
DATABASE_URL='postgresql://…' npm run db:migrate
```

The seed script is optional in production — skip it unless you want demo rows:

```bash
DATABASE_URL='postgresql://…' npm run db:seed
```

## 2. Deploy the app

1. Import this repository on [vercel.com/new](https://vercel.com/new).
2. **Root Directory:** `web` (the repo is a two-client monorepo; Vercel must build the app, not the
   repository root).
3. Framework preset: *Next.js* (detected automatically). Build command and output are the defaults.
4. **Environment variable** — add `DATABASE_URL` for Production, Preview and Development.

`DATABASE_URL` must exist at **build** time, not only at runtime: `/api/health` declares
`dynamic = "force-dynamic"`, but Next.js still imports route modules while collecting page data, and
`src/db/index.ts` throws when the variable is missing. CI works around this with a placeholder URL
(`.github/workflows/ci.yml`); on Vercel you simply set the real value before the first build.

5. Deploy, then open `https://your-app.vercel.app/api/health` — it should return `{"ok":true}`.
6. Put the URL in the repository's *About* panel and in the README.

## Other hosts

Any platform that runs `npm install && npm run build && npm start` with Node 20+ and a
`DATABASE_URL` works the same way — Railway, Render, Fly.io, a VPS with `pm2`, or a container.
Two things to remember:

- Run `npm run db:migrate` once per new database (and again after pulling migrations).
- Point uptime checks at `/api/health`; it executes `select 1` against Postgres.

## Mobile builds

```bash
cd mobile
flutter create . --project-name hangul_quest --org com.hangulquest --platforms android,ios
flutter pub get
flutter build apk --release       # Android artifact
flutter build ipa --release       # iOS (needs an Apple signing identity)
```

`setup.sh` (macOS/Linux) or `setup.bat` (Windows) performs the first three steps and patches
`AndroidManifest.xml` so text-to-speech can be discovered on Android 11+.

## Housekeeping

- Rotate the database password if it was ever committed; this repository reads it only from
  `DATABASE_URL` and ships `.env.example` instead of `.env`.
- The app is auth-less by design: each browser gets its own `hq_handle` cookie. Before exposing a
  public instance, consider rate-limiting `/api/action` and pruning abandoned profiles.
