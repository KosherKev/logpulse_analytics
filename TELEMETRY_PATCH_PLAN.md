# LogPulse Analytics ↔ @bevingh/telemetry — Patch Plan

**Audience:** whoever picks up `logpulse_analytics` next (its own `log.md`/`PHASES.md` convention — this doc is written to be dropped alongside those).
**Purpose:** LogPulse is the Flutter dashboard for `central-logging-service`. That backend is about to grow a `metrics` route to receive reports from `@bevingh/telemetry` (see `bevin-core/docs/TELEMETRY_HANDOFF.md`). This doc maps what LogPulse already does, what's fabricated today that real metrics would fix, and a phased patch plan — following LogPulse's own phase-numbered, one-verify-step-per-phase convention.

**Read `bevin-core/docs/TELEMETRY_HANDOFF.md` first.** This doc assumes its contents.

> **Update (2026-07-21): the collector's write side is now built** (`central-logging-service` PR-22 — see that repo's changelog, and `bevin-core/docs/TELEMETRY_HANDOFF.md` §2/§3 for the cross-repo sync). Sections below are updated accordingly; the core finding (§1's fabricated per-service data) and the core blocker (no read API — §2) are unchanged.
>
> **Second update (2026-07-21, same day): the read API is ALSO now built** (`central-logging-service` PR-24, `GET /api/v1/metrics`) — merged the same day as this doc's first update, before this doc caught up. **§2's "does not exist" claim below is now stale.** The bad news: it doesn't match the shape Phase 16/18's code below was already written against (that code was built provisionally, ahead of the real contract, per this doc's own guidance in §4 not to do — see Phase 20 for the reconciliation). Full field-by-field diff: `central-logging-service/docs/METRICS_READ_CONTRACT.md`.

---

## 1. What LogPulse actually does today (verified by reading the code, not assumed)

LogPulse talks to `central-logging-service`'s existing `logs`-only API:

| LogPulse call | Backend route | What it returns |
|---|---|---|
| `getLogs(filter)` | `GET /api/v1/logs` | Paginated raw log documents |
| `getLogsByTraceId(traceId)` | `GET /api/v1/logs/:traceId` | All logs sharing a trace |
| `getDashboardStats(timeRange)` | `GET /api/v1/logs/stats/summary` | Aggregated counts (`byLevel`, `byService`, `byStatusCode`, global `errorRate`/`avgDuration`) |
| `getTimeSeries(timeRange)` | `GET /api/v1/logs/stats/timeseries` *(doesn't exist — 404s today)* | Falls back to fetching 200 raw logs client-side and bucketing them locally |
| `checkHealth()` | `GET /health` | `{ status: 'healthy', uptime, memory }` — a single global process health, not per-service |

**Two things worth naming plainly:**

- `/logs/stats/timeseries` is called but was never built server-side. Every timeseries chart in the dashboard today runs on the **200-log client-side fallback** (`_getTimeSeriesFromLogs` in `api_service.dart`), which the code itself logs a warning about (`'Time-series fallback... Consider adding /logs/stats/timeseries endpoint.'`).
- `DashboardStats.fromApiJson` synthesizes **per-service uptime as a hardcoded `100.0`** and copies the **global** `errorRate`/`avgLatency` onto every entry in `serviceStats`, because `/logs/stats/summary`'s `byService` only returns request *counts* per service, nothing else. The `Service` model and `ServiceHealthCard` widget are built to show real per-service health, but are being fed fabricated numbers today — this is the same category of problem the transformation log's own `[2026-06-17]` entries flagged in the Timeline tab ("every millisecond value in PERFORMANCE BREAKDOWN is fabricated").

This second point is the actual opportunity: real per-service metrics from `@bevingh/telemetry`-instrumented apps would let LogPulse show genuine numbers instead of fabricated ones, in exactly the place it's currently faking them.

---

## 2. What changes now that the collector's `metrics` route exists (write side only)

> **Revised from "not yet built" to reflect PR-22.**

`central-logging-service` PR-22 shipped:
- `POST /api/v1/metrics` — `{ appId, timestamp, instanceId, metrics: {...} }` (free-form `metrics`, no fixed shape beyond type; `instanceId` is **required**, not optional)
- `POST /api/v1/metrics/health` — `{ appId, status: 'ok', timestamp, instanceId, uptimeSeconds? }`
- Storage: a `Metric` model (MongoDB, `kind: 'health' | 'metric'` — two document shapes in one collection, not a single unified shape), with indexes on `{appId,timestamp}`, `{appId,kind,timestamp}`, `{appId,instanceId,timestamp}`
- Auth: per-app bcrypt-hashed keys (`sk_live_`/`sk_test_`), scoped so a key for one `appId` can't post as another — a different, stronger scheme than the flat list `/api/v1/logs` still uses

This is a **write path apps push to**, parallel to the existing `logs` write path. LogPulse is a **read-only dashboard** — it never calls telemetry's own client package, and none of PR-22's auth scheme is LogPulse's concern (LogPulse doesn't post metrics, it only needs to read them back).

**~~What LogPulse actually needs — a read side — still does not exist.~~ Stale as of this doc's second 2026-07-21 update: `GET /api/v1/metrics` now exists (PR-24, same day).** It uses exactly the indexes this section predicted (`{appId,kind,timestamp}` for the per-kind aggregation, merged in app code). It is **not** the blocker for Phase 16/18 anymore — see Phase 20 for what actually needs fixing now (a path + field-name mismatch between this route and the code already written in Phases 16/18).

**One new wrinkle for LogPulse specifically, now that the real model is visible:** the `Metric` collection stores `kind: 'health'` and `kind: 'metric'` as separate documents, not one combined record per app. Whatever read API gets built, LogPulse's `Service`/`ServiceStats` models will need to merge both kinds per `appId` (latest health doc for status/uptime, latest metric doc for custom numbers) rather than assuming a single document per app — see Phase 16 below.

---

## 3. Phased patch plan (LogPulse-side only)

Numbered starting at 16 to continue LogPulse's own `log.md` phase sequence (last completed: Phase 15).

### Phase 16 — Real per-service health (replaces fabricated uptime/errorRate)

**Blocked on:** the metrics *read* endpoint (still doesn't exist — see §2). Once it does, it should return, per `appId`: latest health status (from `kind: 'health'` docs) merged with latest free-form metrics (from `kind: 'metric'` docs) — e.g. AcademicX's `{ students, activeToday }` — and, per PR-22's model, an `instanceId` on each, so multiple instances of one app aren't silently collapsed into one record (see Phase 18).

**Plan once unblocked:**
- Add `getServiceMetrics()` to `ApiService`, calling the new read route
- Extend `Service`/`ServiceStats` models with a nullable `Map<String, dynamic>? customMetrics` field (free-form, matches telemetry's own "no required shape" design — LogPulse shouldn't assume any particular app's metric keys) **and** merge the two `kind`s (`health` status/uptime + `metric` custom fields) into one `ServiceStats` per `appId` on the client side, unless the read API already merges them server-side (preferable — flag this preference back if the read API is still being designed)
- Replace the hardcoded `uptime: 100.0` and copied global `errorRate`/`avgLatency` in `DashboardStats.fromApiJson`'s `byService` mapping with real per-service data where the collector has it, and an explicit "no data reported yet" state where it doesn't — **do not silently fall back to fabricated numbers**, show an honest empty/unknown state instead (same principle the transformation log itself landed on for the Timeline tab: "fabricated percentages... are worse than showing nothing")
- `ServiceHealthCard`'s pulse animation (healthy=slow/2s, unhealthy=fast/0.8s — built in Phase 8) already has the right visual language for this; it just needs real health data instead of the derived-from-global-stats approximation it uses today

**Verify:** `flutter analyze` clean, existing tests pass, manually confirm a service with no reported metrics shows an explicit "not reporting" state rather than 100% uptime.

### Phase 17 — Real timeseries endpoint adoption

**Blocked on:** `/logs/stats/timeseries` being built server-side (this is a **pre-existing gap**, unrelated to telemetry — it was never built, LogPulse has been running on the client-side fallback since Phase 5).

**Plan once unblocked:**
- `getTimeSeries()` in `ApiService` already has the fallback-on-404 logic (`_getTimeSeriesFromLogs`) — once the real endpoint exists, the `DioException` 404 branch simply stops firing and the real endpoint's response is used automatically. **No LogPulse code change needed**, just server-side work — confirm this by testing against the real endpoint once it's live, and consider removing `_getTimeSeriesFromLogs` + the 200-log-fetch fallback afterward to simplify `api_service.dart`, but only once the real endpoint has been stable for a while (keep the fallback as a safety net until then).

**Verify:** timeseries charts show real backend-computed buckets instead of client-computed ones; log a diff between the two for one time range to sanity-check they roughly agree before removing the fallback.

### Phase 18 — Multi-instance awareness — **UNBLOCKED** (telemetry handoff §2.2 resolved)

**No longer blocked on a `bevin-core` decision** — `@bevingh/telemetry` PR-20 added `instanceId` (client-side, defaults from `K_REVISION` + random suffix if not set), and `central-logging-service` PR-22 made it a **required** field on every stored `Metric` document, with its own index (`{appId,instanceId,timestamp}`). The field is real and already being stored — this phase is now blocked only on the same thing Phase 16 is (the metrics read API not existing yet), not on an open design question.

**Plan once the read API exists:**
- `ServiceStats` needs to represent "N instances reporting" rather than assuming one process per `appId` — e.g. an app on Cloud Run autoscaled to 3 instances shouldn't silently overwrite or average away per-instance signal
- Minimal version: add an `instanceCount` field (distinct `instanceId`s seen for that `appId` in some recent window), shown as a small badge on `ServiceHealthCard` ("3 instances") — does not require redesigning the card, just surfacing one more number
- Slightly richer version, now that this is unblocked and worth considering: since the collector indexes `{appId,instanceId,timestamp}` directly, the read API could plausibly return per-instance breakdowns, not just a count — worth asking for this when the read API is being designed, since retrofitting it later would be more work than including it from the start

**Verify:** once the read API exists and returns instance data, confirm a multi-instance app shows a distinct count/badge rather than silently showing one row per app regardless of instance count.

### Phase 19 — Auth alignment — **RESOLVED** (telemetry handoff §2.4 resolved; low impact on LogPulse confirmed)

`central-logging-service` PR-22 answered the open question: metrics auth is now per-app, bcrypt-hashed, scoped (`sk_live_`/`sk_test_` keys via `matchApiKey`), and separate from the flat `X-API-Key` list still used by `/api/v1/logs`.

**Confirmed low-impact for LogPulse, as suspected:** LogPulse is a read-only consumer of logs today, and will be a read-only consumer of metrics once the read API exists — it never authenticates against the new per-app metrics-write scheme, because it never posts to `/api/v1/metrics`. Whatever the eventual **read** route's auth turns out to be (still undecided — could reuse the flat `/logs` key, could be its own scheme) is a separate, still-open question, but it's a smaller one than the write-side scoping problem PR-22 solved. No LogPulse code changes needed from PR-22 itself.

**Remaining, smaller question:** when the read API is designed, confirm what auth it expects — if it reuses the existing flat `/logs` key (likely, since LogPulse already has a working settings screen for that), no LogPulse change is needed at all; only revisit `api_connection_profile.dart` if the read API turns out to need something else.

### Phase 20 — Reconcile with the real read API (PR-24) — **NEW, supersedes "blocked" status on Phase 16/18**

**Not blocked anymore.** `GET /api/v1/metrics?appId=<optional>` is live (PR-24, 2026-07-20). But the Phase 16/18 code already in this repo (`ServiceMetricsEntry`, `ApiEndpoints.metricsSummary`, `parseServiceMetricsResponse()`, `DashboardRepository._mergeServiceMetrics()`) was written against a guessed contract that differs from what actually shipped. Concretely, today, this code silently gets zero metrics forever — not because of a server error, but because it requests the wrong path and reads the wrong field names, and its own 404-tolerant design swallows the mismatch as "no metrics yet."

Full diff in `central-logging-service/docs/METRICS_READ_CONTRACT.md`. Summary of what needs to change:

- `ApiEndpoints.metricsSummary`: `/metrics/summary` → `/metrics` (the real route has no `/summary` suffix)
- `buildMetricsSummaryQuery`'s `timeRange` param: drop it — the real route only accepts optional `appId`, no time range (latest-snapshot only, no history)
- `parseServiceMetricsResponse()`: read the real nested shape — `health.status`, `health.uptimeSeconds`, `health.instanceId`, `health.timestamp`, top-level `metrics` (this one already matches), and `metricsReportedAt` (not `lastReportedAt`/`timestamp`)
- `errorRate`, `avgLatency`, `errorCount`, `instanceCount`, and `uptime`-as-percentage genuinely don't exist server-side yet — PR-24 only returns latest raw health/metric docs, no computed aggregates. These stay `null` until/unless a v2 collector aggregation is scoped. Recommend: don't block on this — ship the path/field-name fix now (lights up real `status` + custom `metrics`), leave the rest as a known, documented gap rather than fabricated or guessed values.

**Plan:**
- Fix `ApiEndpoints` + `parseServiceMetricsResponse()` per above
- Re-run the 13 existing tests for this area (still not run in this environment — no Flutter SDK available); add a test fixture matching PR-24's actual response shape
- Confirm `ServiceHealthCard` degrades sensibly when `errorRate`/`avgLatency`/`instanceCount` are `null` (should already, per Phase 16's "not reporting yet" design) — just verify against real field names, not guessed ones

**Verify:** point at a real `central-logging-service` instance (or a fixture matching PR-24's exact JSON), confirm `health.status` and custom `metrics` render; confirm the still-missing fields (`errorRate` etc.) show the existing "not reporting" state rather than `null`-crashing or silently blank.

---

## 4. What NOT to do

- **Don't wire LogPulse directly to `@bevingh/telemetry`.** That package is a *write* client for apps reporting their own metrics. LogPulse reads aggregated data back from the collector; it has no reason to depend on the emitter package itself.
- **Don't build Phase 16's UI against a guessed metrics-read API shape.** The read route doesn't exist yet and hasn't been designed. Guessing the shape now risks a rewrite later — flag this back to whichever chat is designing the collector's write route, so the read route gets designed at the same time, not as an afterthought.
- **Don't remove the timeseries client-side fallback (Phase 17) until the real endpoint has been verified stable.** It's a safety net, not dead code, until proven otherwise.
- **Don't quietly keep the fabricated `uptime: 100.0` / copied-global-stats pattern anywhere else in the app.** Worth a quick audit beyond `DashboardStats.fromApiJson` for the same pattern (the Timeline tab already had 3+ separate fabricated-data spots per the transformation log's `[2026-06-17]` entries — there may be others not yet caught).

---

## 5. Suggested order

> **Revised (2026-07-21, second update): read API exists — Phase 20 is now the actual next step, not "flag back and wait."**

1. **Phase 20** (reconcile with PR-24) — fix the path + field names so the Phase 16/18 code that already exists actually talks to the real collector. Small, mechanical, unblocks everything below.
2. Phase 16 (real per-service health) — once Phase 20 lands, verify it actually renders real `status`/`metrics` instead of the "not reporting" fallback, against a live collector.
3. Phase 17 (timeseries) — independent of telemetry, can proceed anytime; unrelated server-side gap pending since Phase 5.
4. Phase 18 (multi-instance) — `instanceId` is stored and returned in `health.instanceId`, but `instanceCount` (a distinct-instance count) still doesn't exist server-side (see METRICS_READ_CONTRACT.md §4.4). Revisit once more than one instance of an app is actually reporting.
5. Phase 19 (auth) — resolved, confirmed no LogPulse work needed; PR-24's read route uses the same flat key as `/logs`, so the "remaining smaller question" in §3 Phase 19 is now also answered.
