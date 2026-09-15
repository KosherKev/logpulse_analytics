# Phase 26 — One-click deploy button for `central-logging-service`

**Audience:** whoever implements this — entirely within `central-logging-service`.
No changes to `logpulse_analytics` or `bevin-core` (kept here only for
phase-numbering continuity with Phase 24/25, same as those did for
cross-repo work).
**Author:** Claude, following up on the Phase 25 theory-crafting discussion
about onboarding friction — Kevin confirmed he does **not** want a shared
multi-tenant hosted backend (every deploy stays a fully isolated instance,
same trust model as self-hosting today), just wants standing one up to be
as close to zero-terminal as possible, and asked whether that's worth
building versus leaving hosting entirely to the user.

**Status (2026-09-15): Built and committed — `render.yaml` parses cleanly
and its `healthCheckPath` matches the real `/health` route. NOT live-verified
(no Render account in this session) — Step 3 below is the one remaining
piece, needs Kevin to actually click the button once.**

## Background (read this before Step 1)

**Why build one button rather than "leave it to the user" or support many
platforms:** both extremes have a real cost. Leaving it fully to the user
means every new self-hoster re-derives "clone, npm install, pick a host,
figure out Docker vs buildpack, wire up env vars" from the README — exactly
the friction that started this whole discussion. Building deploy configs
for many platforms (Railway, Render, Fly.io, Heroku-likes, ...) is real
ongoing maintenance for marginal benefit once one path already works well.
The middle ground taken here: **one first-class button**, with the existing
manual path (`npm run setup` + your own host) kept as the documented
fallback for anyone who wants something else — so this is additive, not a
replacement for the Phase 25 setup wizard.

**Why Render, not Railway:** Railway's template mechanism can bundle a
MongoDB service alongside the app in the same one-click flow (no separate
Atlas signup), which is closer to "app + database, one click." It was
seriously considered and rejected for v1: it means authoring and
maintaining a multi-service template with Railway-specific env var
references (`${{MongoDB.MONGO_URL}}`), a second templating dialect on top
of what Render needs. Render's Blueprint (`render.yaml`) deploys just the
app service and prompts for one field it can't auto-generate — a MongoDB
Atlas connection string — reusing the Atlas signup flow **already built and
documented** in Phase 25's `npm run setup`/README/QUICKSTART. One extra
click (paste a URI you got from a link) in exchange for a much smaller,
single-file, single-dialect integration. If Railway's bundled-DB path ever
turns out to matter more than this tradeoff suggests, it's an additive
follow-up, not a rework of this phase.

**What already exists and this phase reuses, unchanged:**
- `Dockerfile` — standard, already reads `process.env.PORT` (via
  `src/config/index.js`), already has a working `HEALTHCHECK` hitting
  `/health`. No Dockerfile changes needed — Render's Docker runtime builds
  this exact file, so behavior stays identical to the Cloud Run deploy.
- `.env.example` — the canonical list of env vars and their defaults; this
  phase's `render.yaml` should mirror it field-for-field so the two never
  drift apart silently.
- `scripts/setup.js` / README's "Authentication" section (Phase 25) — the
  Atlas signup link and the "what is `ADMIN_SETUP_TOKEN` for" explanation
  already exist; this phase points at them rather than re-explaining.
- `/health` route (`src/routes/health.js`, mounted at `/` in `server.js`) —
  reused directly as Render's health-check path.

**Verified against Render's current Blueprint docs** (not guessed) via web
search — `sync: false` (prompts the user in the dashboard at deploy time),
`generateValue: true` (Render generates a random base64 value if one
doesn't already exist), `dockerfilePath`, `runtime: docker`, `type: web`,
`healthCheckPath` are all real, current fields. **Still double-check the
exact syntax against
[render.com/docs/blueprint-spec](https://render.com/docs/blueprint-spec)
at implementation time** — third-party platform specs can move, and this
was verified via search snippets, not a full fetch of the live page.

---

## Step 1 — Add `render.yaml` at repo root

**What:** New file, `render.yaml`:

```yaml
services:
  - type: web
    name: central-logging-service
    runtime: docker
    dockerfilePath: ./Dockerfile
    plan: free
    healthCheckPath: /health
    envVars:
      - key: NODE_ENV
        value: production
      - key: MONGODB_URI
        sync: false
      - key: API_KEYS
        generateValue: true
      - key: ADMIN_SETUP_TOKEN
        generateValue: true
      - key: HOT_STORAGE_DAYS
        value: "7"
      - key: COLD_STORAGE_DAYS
        value: "90"
      - key: RATE_LIMIT_WINDOW_MS
        value: "60000"
      - key: RATE_LIMIT_MAX_REQUESTS
        value: "100"
```

Deliberately omitted: `PORT` (Render injects and expects the app to bind
this itself — already true, `config/index.js` already reads
`process.env.PORT`) and the `GCS_*` vars (cold storage isn't implemented —
see `PROGRESS.md` Known Limitations; don't prompt for config that does
nothing).

**Why:** This file is the entire mechanism — Render reads it from the repo
at deploy time and renders a form pre-filled with everything except
`MONGODB_URI`, the one value that genuinely can't be auto-generated (it
points at an external database the user must have or create).

**Sequencing:** First — everything else in this phase points at this file
existing.

**Data flow:** N/A — declarative config, no runtime code path.

**Edge cases:** `API_KEYS` auto-generating a random value is fine — per
Phase 25 that's only the legacy fallback scheme now, not required for the
service to function; a fresh deploy's real keys come from `/admin/keys.html`
using the auto-generated `ADMIN_SETUP_TOKEN`, same flow Phase 25's manual
setup already establishes.

**Design decisions:** `plan: free` as the default — cheapest zero-typing
path for someone just trying this out. Flag, don't silently upgrade:
Render's free web services spin down after inactivity and cold-start on the
next request (a few seconds' delay) — worth one sentence in the docs (Step
2) so it doesn't read as broken. Not a blocker for evaluating/self-hosting;
someone running this for real production traffic would upgrade the plan
themselves, same as they'd pick a real Cloud Run tier today.

---

## Step 2 — "Deploy to Render" button + doc updates

**What:**
- `README.md`: add a Render deploy badge near the very top (before "##
  Features"), linking to
  `https://render.com/deploy?repo=<this repo's github URL>`. One short
  paragraph under it: click → paste a MongoDB URI (link to the Atlas
  signup instructions already in the "Environment Setup" section further
  down) → deploy → open `https://<your-service>.onrender.com/admin/keys.html`,
  same as the local `/admin/keys.html` flow, using the `ADMIN_SETUP_TOKEN`
  Render generated (visible in the service's Environment tab in the Render
  dashboard — Render doesn't expose generated values anywhere else).
- `QUICKSTART.md`: add this as an explicit alternative at the very top of
  "## 2. Clone and Install" / "## 3. Run the setup wizard" — "Don't want to
  run anything locally? Click the Render button in the README instead,
  skip straight to step 6 once it's deployed."
- Note the free-plan cold-start behavior (Step 1's design decision) in
  whichever of these two docs feels less redundant — don't repeat it in
  both.

**Why:** A `render.yaml` with no button pointing at it is undiscoverable —
this is the actual "one click" a person sees and uses.

**Sequencing:** Depends on Step 1 (the button's URL only works once the
Blueprint file exists in the repo Render reads).

**Edge cases:** The deploy URL must reference the exact GitHub path of this
repo (`KosherKev/central-logging-service` per this session's remotes,
unless it's moved — check before hardcoding, the way `bevin-core`'s remote
already turned out to have moved once this session).

**Design decisions:** None beyond Step 1's.

---

## Step 3 — Verify live (cannot be done in a sandbox — needs Kevin)

**What:** Click the button on a real Render account once. Confirm:
1. The form shows exactly one required field (`MONGODB_URI`) and nothing
   else demands typing.
2. Paste a fresh Atlas URI (or reuse an existing cluster with a new
   database name) → deploy succeeds → `/health` returns 200.
3. `/admin/keys.html` is reachable, and the `ADMIN_SETUP_TOKEN` visible in
   Render's Environment tab actually unlocks it (mirrors the local
   verification already done for the Phase 25 CSP fix).
4. Create a key through the deployed instance's admin UI, confirm a
   `curl` against `/api/v1/logs` with that key works.

**Why:** This is exactly the kind of thing that "looks right reading the
YAML" can still get wrong in practice — a wrong `dockerfilePath`, an env
var name typo, or a Render platform quirk not caught by web search alone.
Same discipline this project has followed throughout Phase 24/25: don't
call a deploy done from a diff review, verify it live.

**Sequencing:** Last — depends on Steps 1-2, and depends on Render account
access this session doesn't have.

---

## Explicitly not in this phase

- No Railway (or any other platform) template — considered, deferred, see
  Background.
- No code changes to the app itself — `Dockerfile`, `config/index.js`,
  `health.js` are all already correctly shaped for this; this phase is
  config + docs only.
- No "connect your backend from inside the LogPulse app" flow (the
  admin-token-mints-a-scoped-key idea from the earlier discussion) — a
  separate, LogPulse-side phase, not bundled here.
- No change to `scripts/deploy.sh` (the Cloud Run path) — stays as the
  documented option for anyone who wants that instead.

## Log update instructions

Append to this repo's `central-logging-service/PROGRESS.md` (not
`logpulse_analytics`'s — this phase is CLS-only despite living in this
repo's phase-numbering sequence):

```
## Phase 26 — One-click Render deploy
Completed: [timestamp]
Commit: [hash]

### What was done
render.yaml added; README/QUICKSTART updated with the deploy button and
the paste-your-Mongo-URI-then-open-/admin/keys.html flow.

### Key facts for next step
- [confirmed live on a real Render account? free-plan cold start noted where?]
- [exact repo URL used in the deploy link, confirmed correct]

### Status
[DONE — live-verified / PARTIAL — config committed, not yet clicked for real]
```
