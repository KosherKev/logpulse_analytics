# Phase 25 — Unified API keys (logs + telemetry) and easier onboarding

**Audience:** whoever implements this — spans three repos, in this order:
`central-logging-service` (schema + middleware + provisioning) →
`bevin-core` `packages/telemetry` (client-side logging capability) →
`logpulse-analytics` (consumer-side key swap only, no code change).
**Author:** Claude, from a theory-crafting discussion with Kevin about why
provisioning credentials for this system currently requires two unrelated
mechanisms and a hand-run CLI script.
**Do not deviate from this spec without noting the deviation in each repo's own
log at completion (see the update instructions at the end of each part).**

**Status (2026-09-15): DONE — all three parts complete.** Part A deployed
(scope migration run, `ADMIN_SETUP_TOKEN` set on Cloud Run). Part B
published (`@bevingh/telemetry@0.2.0` live on the npm registry). Part C
done: LogPulse's connection switched to a scoped key, and KL-2609-key (the
exposed key this phase's Background section flags below) is fully closed —
rotated **and** purged from `logpulse_analytics`' git history via
`git filter-repo` (2026-09-15, see that repo's `PROGRESS.md`). See each
repo's own `PROGRESS.md`/`LOG.md` for verification detail.

## Background (read this before Step 1)

Confirmed by reading the actual code (not doc claims):

- **Two auth schemes exist in `central-logging-service` today**, not one:
  - `src/middleware/auth.js` (`authenticate`) — a flat, comma-separated
    `API_KEYS` env var, no DB, no per-app identity, no revocation without a
    redeploy. Guards `POST /api/v1/logs`, all `GET /api/v1/logs*` routes,
    both `GET /api/v1/services*` routes, **and** `GET /api/v1/metrics`
    (confirmed via `grep` on `src/routes/*.js` — that last one is a standing
    inconsistency: metrics *reads* use the flat scheme even though metrics
    *writes* don't).
  - `src/middleware/metricsAuth.js` (`metricsAuth`) — per-app, bcrypt-hashed
    `sk_live_`/`sk_test_` keys stored in Mongo (`ApiKeyCandidate` model:
    `subjectId`, `testHash`, `liveHash`), matched via `@bevingh/auth`'s
    `matchApiKey`. Guards only `POST /api/v1/metrics` and
    `POST /api/v1/metrics/health`.
  - The split was a deliberate 2026-07-20 decision (PR-22, recorded in that
    repo's `PROGRESS.md`): per-app keys specifically so "a leaked AcademicX
    key cannot post as another app." **This property must survive
    unification, not regress to one shared secret for everyone.**
  - Keys for the per-app scheme are provisioned by `src/utils/generateAppApiKey.js`,
    a CLI script run by hand against production Mongo. There is no list, no
    revoke, no rotate — only "generate a new one and go update the hash."
- **`@bevingh/telemetry` (`bevin-core/packages/telemetry`) already has the
  buffering primitive this needs.** `src/client.ts`'s own header comment
  says its batch/flush/retry shape was ported directly from
  `central-logging-service/client/log-shipper.js` — the old plain-JS log
  shipper. `BufferedItem` is already a discriminated union over `context`
  (`"health" | "metrics"`), each with its own `path`. Adding a `"log"`
  variant posting to `/api/v1/logs` is an extension of an existing pattern,
  not new architecture. Per `bevin-core/docs/TELEMETRY_HANDOFF.md`, this
  package is **not yet published** and **not yet wired into any real app**
  (AcademicX wiring is still pending) — so this is a low-risk time to extend
  its contract.
- **`client/log-shipper.js`** (in `central-logging-service`) is the thing
  `@bevingh/telemetry` was modeled on. Per the handoff doc, it has no
  confirmed production consumers today. Candidate for deprecation once
  Part B ships, not deletion yet — flag, don't silently remove (this
  project's own established discipline, see `PROGRESS.md`'s Decisions log).
- **This also resolves KL-2609-key** (logpulse-analytics `PROGRESS.md`):
  `test_api.dart`/`test_api_2.dart` have a live flat API key committed to
  git history. Once logs move off the flat scheme onto revocable, DB-backed
  keys, Kevin rotates *that one key* without touching any other consumer —
  the fix for that incident falls out of this phase rather than needing its
  own.
- **Non-goal:** migrating off MongoDB. The database-setup pain point is an
  *onboarding friction* problem (a new self-hoster needs a Mongo URI), not a
  wrong-database problem — MongoDB Atlas's free tier already is "register,
  get a link, get a URI" in about two minutes. Solved by pointing to it in
  the setup wizard (Step 7), not by changing the datastore.

---

## Part A — `central-logging-service`: schema, middleware, provisioning

### Step 1 — Extend `ApiKeyCandidate` with scopes and lifecycle fields

**What:** In `src/models/ApiKeyCandidate.js`, add:
- `scopes: { type: [String], enum: ['logs:read', 'logs:write', 'metrics:read', 'metrics:write'], required: true, default: [] }`
- `label: { type: String, required: false }` — human-readable, shown in the list UI (e.g. `"LogPulse dashboard"`, `"AcademicX producer"`).
- `lastUsedAt: { type: Date, required: false }` — updated on successful auth.
- `revokedAt: { type: Date, required: false, default: null }` — soft-revoke; a non-null value means the key(s) on this candidate no longer authenticate, but the row (and its audit trail) stays.

**Why:** One unified credential model needs to express *what an app is allowed
to do*, not just *who it is*. Scopes are what let a single key work for logs
and metrics without regressing to "any valid key can do anything."

**Sequencing:** First — everything else depends on this shape existing.

**Data flow:** N/A — schema-only change. Existing rows get `scopes: []` by
default (see Step 3's migration note — they need backfilling before the new
middleware can authorize them for anything).

**Edge cases:** `subjectId` stays `unique` — one row per app, scopes shared
across that app's test and live key. If a real need for different scopes per
environment shows up later, that's a new field then; don't build it
speculatively now.

**Design decision:** Scopes live on the candidate (per app), not per
individual key (test vs. live) — simpler, and no current use case needs the
split.

---

### Step 2 — Unified `apiKeyAuth(requiredScope)` middleware

**What:** New file `src/middleware/apiKeyAuth.js`, replacing the two existing
middleware files' *logic* (keep `auth.js`/`metricsAuth.js` as thin re-exports
during migration if anything imports them directly — check call sites before
deleting). Factory signature: `apiKeyAuth(requiredScope)` returns an Express
handler that:
1. Reads `X-API-Key` from headers; 401 if missing.
2. Loads all `ApiKeyCandidate`s where `revokedAt: null` (`.select('subjectId scopes testHash liveHash')`).
3. Calls `@bevingh/auth`'s `matchApiKey(rawKey, candidates, bcrypt.compare)`.
4. 403 if no match, or if the matched candidate's `scopes` doesn't include `requiredScope`.
5. On success: fire-and-forget `ApiKeyCandidate.updateOne({ subjectId }, { lastUsedAt: new Date() })` (don't `await` — don't let a write-back slow down every authenticated request), then set `req.apiKeyAppId = match.subjectId`, `req.apiKeyEnvironment = match.environment`, call `next()`.

**Why:** One codepath, one mental model, for every route in this service —
today's split (env-var equality vs. bcrypt-hash-plus-DB) is two different
trust mechanisms doing conceptually the same job.

**Sequencing:** Depends on Step 1 (needs `scopes` to check against).

**Data flow:** `ApiKeyCandidate` (Mongo) → `matchApiKey` (`@bevingh/auth`,
already a dependency via `metricsAuth.js`) → route.

**Edge cases:** A candidate with a matching hash but missing the required
scope must 403, not 401 — the key is valid, just not authorized for this
route (matches `metricsAuth.js`'s existing `appId`-mismatch behavior, which
also 403s rather than 401s for "valid key, wrong permission").

**Design decision:** `lastUsedAt` updates fire-and-forget rather than
blocking the request — this is a UI nicety (Step 6's list shows "last used"),
not something request correctness depends on. A failed write-back should log
and move on, never fail the request.

---

### Step 3 — Migration: backfill scopes, add the legacy fallback

**What:**
- One-off script (`scripts/migrate-scopes.js`, run manually, not part of
  `npm run setup`): for every existing `ApiKeyCandidate` row (today, these
  only exist for the metrics-write use case), set `scopes: ['metrics:write']`
  if not already set — preserves current behavior for anything already
  provisioned.
- Inside `apiKeyAuth`, add a fallback: if no DB candidate matches, check the
  raw key against `config.auth.apiKeys` (the existing flat `API_KEYS` env
  list) — if it matches, treat it as authorized for **every** scope (this is
  the flat scheme's current blast radius; no regression, just made explicit)
  and log a `warn`-level line naming which legacy key was used, so real usage
  of legacy keys is visible in logs before Step 4's routes go live and before
  anyone decides to remove this fallback.

**Why:** This is what makes the cutover non-destructive. Every existing
consumer (LogPulse's flat key, any producer app's flat key, the metrics-write
keys already issued) keeps working through the deploy; nothing goes dark on
flag day.

**Sequencing:** Depends on Steps 1-2. Must land and deploy *before* Step 4's
route rewiring, or there's a window where routes reference scopes nothing has
yet.

**Data flow:** N/A.

**Edge cases:** The legacy fallback must never be reachable for a *revoked*
DB candidate whose key happens to also appear in `API_KEYS` — not a realistic
collision (different key formats: `cls_...` flat vs. `sk_live_/sk_test_`
DB-backed), but worth a one-line comment noting why it's safe (format alone
prevents overlap).

**Design decision — flagged, not picked:** this fallback should have a hard
sunset once Step 12 confirms every real consumer holds a DB-backed key.
That's deliberately **not** decided in this phase — removing it is a
follow-up cleanup step (see Next Steps), so this phase doesn't couple "ship
the new model" to "everyone has migrated," which would block indefinitely.

---

### Step 4 — Rewire every route onto `apiKeyAuth`

**What:** Replace `authenticate`/`metricsAuth` imports with `apiKeyAuth(...)`
calls:
- `src/routes/logs.js`: `POST /` → `apiKeyAuth('logs:write')`; all `GET`
  routes (`/`, `/:traceId`, `/stats/summary`, `/stats/timeseries`,
  `/errors/groups`) → `apiKeyAuth('logs:read')`.
- `src/routes/services.js`: both `GET` routes → `apiKeyAuth('logs:read')`
  (the services catalog is log-derived, same read audience as the logs
  routes today).
- `src/routes/metrics.js`: `POST /` and `POST /health` →
  `apiKeyAuth('metrics:write')` (the existing `subjectId`-vs-`appId` check
  in that file stays — it's now a defense-in-depth check on top of scope
  auth, not the only check). `GET /` → `apiKeyAuth('metrics:read')`.

**Why:** This is the actual unification — every route now authorizes through
one function, differing only in which scope string they require.

**Sequencing:** Depends on Step 3 being deployed first (see that step's
sequencing note).

**Data flow:** N/A — call-site swap.

**Edge cases:** `GET /api/v1/metrics` moving from the flat scheme to
`metrics:read` is a **behavior change**, not a refactor — anything currently
reading that route with a flat key needs a `metrics:read`-scoped key before
this lands, or it breaks. **Decision needed from Kevin before this sub-step
ships: confirm who currently calls `GET /api/v1/metrics` (grep both this
repo and `logpulse_analytics` for callers) and get them a scoped key first.**
If nobody currently calls it in practice, this is a non-event and can ship
immediately.

**Design decisions:** None beyond the flagged one above.

---

### Step 5 — Provisioning service + admin API (replaces the CLI script)

**What:**
- New `src/services/apiKeyService.js`: the actual logic behind key lifecycle
  — `createKey({ appId, label, scopes, environment })` (generates the raw
  key with the existing `sk_live_`/`sk_test_` prefix convention from
  `generateAppApiKey.js`, bcrypt-hashes it, upserts the `ApiKeyCandidate`,
  returns the raw key **once**), `listKeys()` (returns id/label/scopes/
  environments-present/createdAt/lastUsedAt/revokedAt — **never** hashes or
  raw keys), `revokeKey(subjectId)` (sets `revokedAt`), `rotateKey(subjectId, environment)`
  (regenerates just that environment's hash, old value stops matching
  immediately).
- `src/utils/generateAppApiKey.js` becomes a thin CLI wrapper calling
  `apiKeyService.createKey` — keeps working for anyone still scripting
  against it, but is no longer the only way to provision a key.
- New route file `src/routes/admin/keys.js`: `POST /admin/keys`,
  `GET /admin/keys`, `POST /admin/keys/:id/revoke`, `POST /admin/keys/:id/rotate`.
  Guarded by a **separate** middleware checking a bearer `ADMIN_SETUP_TOKEN`
  env value — a different trust tier from app-level API keys, since this
  surface can mint and revoke those keys.

**Why:** "Run a CLI script by hand against production Mongo, with no list
and no revoke" is the exact friction Kevin flagged. This makes provisioning
a normal HTTP operation the UI in Step 6 can drive.

**Sequencing:** Depends on Steps 1-2 (needs the scope-aware model to exist).
Independent of Steps 3-4 in principle, but land after them so the admin API
is provisioning keys the rest of the service already understands.

**Data flow:** Admin UI/CLI → `apiKeyService` → `ApiKeyCandidate` (Mongo).

**Edge cases:** `createKey` must never log or return the raw key more than
once — matches the existing discipline already in `generateAppApiKey.js`
("Raw key is NEVER written to the database — only the bcrypt hash is
upserted"). `revokeKey` must be idempotent (revoking an already-revoked key
is a no-op, not an error).

**Design decision — flagged, not picked:** a single shared `ADMIN_SETUP_TOKEN`
bearer is the v1 choice, not a real login system. Reasonable for a
single-operator context (matches this repo's existing minimal-infra
philosophy — see `TELEMETRY_HANDOFF.md`'s reasoning for folding the metrics
collector into this service instead of standing up a 4th one). Revisit if
this service ever needs multiple named operators.

---

### Step 6 — Minimal provisioning UI

**What:** One static page, `src/public/admin/keys.html`, served via
Express's `express.static` (no build step, no framework — plain HTML +
`fetch()` calls to Step 5's routes). Prompts once for the admin token
(kept in `sessionStorage`, never logged), then: a table listing existing
keys (label, appId, scopes, environments present, created, last used,
revoked-or-not), a create form (appId, label, scope checkboxes,
test/live/both), and a revoke button per row.

**Why:** This is the "list UI that allows for provisioning keys" from the
original discussion — replacing a hand-run script with something Kevin (or
anyone self-hosting this repo) can use without a terminal.

**Sequencing:** Depends on Step 5.

**Data flow:** Browser → Step 5's `/admin/keys*` routes → `apiKeyService`.

**Edge cases:** The raw key returned by the create form must be shown
exactly once in the UI with a "copy, you won't see this again" notice —
matches the CLI script's existing one-time-print discipline.

**Design decisions:** No framework, no build pipeline — a static page kept
this simple is easier for a self-hoster to trust and audit than a bundled
SPA would be, and matches this repo's existing "add a route, not a new
service" pattern.

---

### Step 7 — Setup wizard (`npm run setup`)

**What:** New `scripts/setup.js`, interactive (readline prompts):
1. Ask for a Mongo URI. If the user doesn't have one, print a link to
   MongoDB Atlas's free-tier signup (no card required) and wait.
2. Generate a random `ADMIN_SETUP_TOKEN`, print it once, write it to `.env`.
3. Write `.env` from `.env.example` plus the answers (Mongo URI, admin
   token, a fresh `API_KEYS` value kept only as the legacy fallback's seed —
   see Step 3).
4. Ask whether to create a first app key now (appId, scopes); if yes, call
   `apiKeyService.createKey` directly (same function the admin API uses)
   and print the raw key with instructions for where it goes
   (`@bevingh/telemetry`'s `createTelemetryClient({ apiKey: ... })`, or
   LogPulse's Settings screen for a `logs:read` key).

**Why:** Replaces today's implicit onboarding ("hand-edit `.env`, then
separately remember to run `generateAppApiKey.js`") with one command that
gets a fresh clone to a working, credentialed instance.

**Sequencing:** Depends on Step 5 (reuses `apiKeyService` directly, not the
HTTP layer, since the server isn't running yet during setup).

**Data flow:** Terminal prompts → `.env` file + one `apiKeyService.createKey`
call.

**Edge cases:** Running `npm run setup` again on an already-configured repo
should ask before overwriting an existing `.env`, not silently clobber it.

**Design decisions:** None beyond what's in Background (Atlas over building
custom DB-provisioning infrastructure).

---

### Step 8 — Docs rewrite

**What:** Update `README.md`/`QUICKSTART.md`: replace the current manual
`.env` + CLI-script instructions with: clone → `npm install` → `npm run setup`
→ `npm run dev` → open `/admin/keys.html` for any further keys. Fold in the
Atlas signup link from Step 7. Note the legacy `API_KEYS` fallback exists for
migration only and is not the recommended path for new consumers.

**Why:** Docs currently describe the two-mechanism world this phase removes;
leaving them stale would just recreate the original confusion for the next
person who reads them instead of the code.

**Sequencing:** Last in Part A — depends on everything above actually
existing.

---

## Part B — `bevin-core` `packages/telemetry`: add logging capability

### Step 9 — `reportLog()` + Express middleware on `createTelemetryClient`

**What:** In `packages/telemetry/src/client.ts`, extend the `BufferedItem`
union with a third variant: `{ context: "log"; path: "/api/v1/logs"; body: LogEntry }`
(shape matching what `central-logging-service/src/routes/logs.js`'s
`POST /` already validates via `validateLogBatch` — read that validator
before defining `LogEntry`'s type, don't guess the shape). Add
`reportLog(entry)` to the returned client object, enqueueing through the
exact same `enqueue`/`flush`/`sendOne` machinery `reportMetrics`/`reportHealth`
already use — no new buffering logic needed, this is wiring a third context
into an existing generic buffer. Add a `logMiddleware()` export from
`adapters/express/index.ts`, mirroring `log-shipper.js`'s `middleware()`
method (auto request/response logging via `res.on('finish', ...)`), but
calling `reportLog()` instead of `LogShipper.log()`.

**Why:** This is the actual "update the package to offer logging too" — and
it's a small extension because the hard part (batching, retry, buffer-cap,
shutdown hooks) was already ported from `log-shipper.js` when this package
was first built (`TELEMETRY_HANDOFF.md` §2.1).

**Sequencing:** Depends on Part A's Step 4 being live (the collector needs
`logs:write` as a real, checkable scope before a client can be told to use
it) — but can be developed and unit-tested against a mock collector in
parallel with Part A.

**Data flow:** App code → `reportLog()`/`logMiddleware()` → same buffer →
`POST /api/v1/logs` with the app's unified key.

**Edge cases:** `logMiddleware()` must not throw or block the response
pipeline it's wrapping — same fire-and-forget discipline as the rest of this
client (`reportHealth`/`reportMetrics` never throw; failures go to
`onReportError` only).

**Design decision — flagged, not picked:** this package now does three
things (health, metrics, logs) for what's still nominally "the telemetry
package," used by other, non-LogPulse products in this monorepo (payments,
ledger, etc., per `bevin-core/PACKAGES.md`). Adding logging as an *optional*,
separately-called capability (not a rename, not a required config field)
keeps existing consumers' contracts untouched. Whether this package should
eventually be renamed to reflect "telemetry + logs" is a naming question for
later, not blocking this phase.

---

### Step 10 — Update package docs

**What:** `packages/telemetry/README.md` and `src/types.ts`'s doc comments:
document `reportLog`/`logMiddleware`, and add a short migration note pointing
`client/log-shipper.js` consumers here — check first whether any exist in
production (per `TELEMETRY_HANDOFF.md`, none confirmed as of that doc).

**Sequencing:** Depends on Step 9.

---

### Step 11 — Flag `log-shipper.js` as deprecated (don't delete)

**What:** Add a header comment to `central-logging-service/client/log-shipper.js`
pointing at `@bevingh/telemetry`'s new `reportLog`/`logMiddleware`. Do not
delete the file in this phase — confirm zero production consumers first
(this repo's own established discipline: flag rather than silently remove,
see `logpulse_analytics/PROGRESS.md`'s Decisions log on the provider/http
package removal-then-rebuild cycle).

**Sequencing:** Last in Part B.

---

## Part C — `logpulse-analytics`: consumer-side only

### Step 12 — Rotate LogPulse's key, close KL-2609-key

**What:** No code change. Using Part A's admin UI (or setup wizard), issue
LogPulse a new `logs:read`-scoped key (add `metrics:read` too if/when LogPulse
starts reading the metrics-read route). Update the "Bevin Production"
connection's stored key via Settings (the existing edit-connection flow,
already fixed in Phase 24). Separately: revoke the old flat key from
`API_KEYS`/rotate it, and — since the key is exposed in git history via
`test_api.dart`/`test_api_2.dart` — this is the moment to actually close
KL-2609-key, which has been sitting in the Human pass queue.

**Why:** This is the payoff for LogPulse specifically: the exposed key
becomes a revoked, DB-backed key instead of "rewrite git history or accept
the risk forever."

**Sequencing:** Last overall — depends on Part A being deployed.

**Edge cases:** Don't remove the old flat key from `API_KEYS` until the new
scoped key is confirmed working live (same "verify before declaring done"
discipline this repo already follows per the Phase 24 record).

---

## Explicitly not in this phase

- Removing the legacy flat-key fallback (Step 3) — needs a confirmed-migrated
  consumer list first; tracked as a follow-up cleanup phase.
- Deleting `client/log-shipper.js` — needs a confirmed zero-consumers check.
- Publishing `@bevingh/telemetry` to a registry — a pre-existing item from
  `TELEMETRY_HANDOFF.md`, unblocked by this phase but not part of it.
- Any change to the datastore (Mongo stays); any multi-operator admin login
  system (Step 5's single bearer token is the v1 choice).
- AcademicX (or any other app's) actual wiring to the new unified key —
  separate session per this monorepo's own "one app at a time" discipline.

## Open decisions for Kevin (do not guess these silently)

1. Who currently calls `GET /api/v1/metrics` with the flat key (Step 4) —
   needs confirming before that route's auth requirement tightens.
2. When to schedule removing the Step 3 legacy fallback once migration is
   confirmed complete.
3. Whether `test_api.dart`/`test_api_2.dart`'s exposed key needs a git
   history rewrite in addition to rotation (Step 12), given the repo may go
   public — rotation alone stops the key from working, but doesn't remove it
   from history.

---

## Log update instructions

**`central-logging-service` `PROGRESS.md`/`LOG.md`** (after Part A):
```
## Phase 25a — Unified API keys (schema + middleware + provisioning)
Completed: [timestamp]
Commits: [list]

### What was done
[scopes field, unified apiKeyAuth middleware, migration fallback, admin
API + UI, setup wizard — note anything that deviated from PHASE_25_SPEC.md]

### Key facts for next step
- [which routes' auth requirement actually changed behavior, e.g. GET /metrics]
- [whether the GET /api/v1/metrics caller question (Open decision 1) was resolved]

### Deviations from spec
[...]

### Status
DONE / PARTIAL — note whether the legacy fallback is still active (it should be)
```

**`bevin-core` `LOG.md`** (after Part B):
```
## Session NNN — @bevingh/telemetry: add logging capability
Completed: [timestamp]

### What was done
[reportLog/logMiddleware added, BufferedItem extended, docs updated]

### Key facts for next step
- [confirmed log-shipper.js consumer count before/after]

### Status
DONE
```

**`logpulse-analytics` `log.md`** (after Part C):
```
## Phase 25c — Rotate LogPulse's API key onto the unified scheme
Completed: [timestamp]

### What was done
[new logs:read key issued and configured; old flat key revoked; KL-2609-key
closed — note whether a git history rewrite was also done or deliberately
deferred]

### Status
DONE
```

Paste each entry back to Claude when its part is done.
