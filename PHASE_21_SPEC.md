# Phase 21 — Isolate Metrics Fetch Failures from `DashboardRepository.getStats()`

**Audience:** the secondary AI (CLI) implementing this in the `logpulse_analytics` repo.
**Author:** Claude, acting as reasoning/architecture AI in the split-AI workflow for this repo.
**Do not deviate from this spec without noting the deviation in the LOG.md entry (see the end of this document).**

## Background (read this before Step 1)

This is a pre-existing design tradeoff, flagged during the original code review of the Phase
16/18 work (before PR-24 or Phase 20 existed) and left un-acted-on until now. It's still present
in the current code, verified against `lib/data/repositories/dashboard_repository.dart` as of
Phase 20's completion.

`DashboardRepository.getStats()` does:
```
Future.wait([ _apiService.getDashboardStats(...), _apiService.getServiceMetrics() ])
```
wrapped in a single `try`/`catch` that rethrows as `AppException`.

`ApiService.getServiceMetrics()` already soft-fails on **404** (returns `[]` — this is correct
and deliberate, so an older backend without the metrics route degrades cleanly). But it
explicitly does **not** swallow other errors — a 500, a timeout, a network drop, or a malformed
response on the metrics endpoint all propagate as thrown exceptions (the code comment there says
plainly: *"Non-404 errors still propagate — 'missing route' must not be conflated with
'broken.'"* — a deliberate, correct distinction).

The problem is what happens to that exception once it reaches `getStats()`: because both calls
share one `Future.wait` and one `catch`, a metrics-specific failure fails the **entire**
`getStats()` call — meaning total log counts, global error rate, global latency, and every
per-service row disappear from the dashboard, not just the health/metrics portion, because of a
problem in a single supplementary signal that was only added in Phase 16/18/20.

**The fix is not to make metrics failures invisible** (that would repeat the exact mistake this
repo's own fabrication audit already fixed once — masking a real problem by making it look like
"no data"). The fix is to stop a metrics-specific failure from taking down data that has nothing
to do with metrics, while still surfacing the failure somewhere a developer can see it.

---

## Step 1 — Decouple the metrics fetch's failure from the log-stats fetch

**What:** In `DashboardRepository.getStats()`, keep both calls running concurrently (do not
serialize them — no added latency), but give the metrics call its own error boundary, separate
from the log-stats call. Any exception from `getServiceMetrics()` — of any kind, not just the
already-handled 404 — should be caught locally, logged as a warning, and treated as "no metrics
this fetch" (empty list), while `getDashboardStats()` keeps its current all-or-nothing behavior:
if *that* call fails, `getStats()` should still fail loudly, exactly as it does today. Log stats
are the primary data source; metrics are a supplementary enhancement layer.

**Why:** This is the actual bug. Today, a transient blip on the metrics endpoint alone (which
has no rate limiting, per `central-logging-service`'s routes, and is a newer, less
battle-tested route than `/logs/stats/summary`) takes the whole dashboard down. That's a worse
failure mode than the thing it would be protecting against.

**Sequencing:** Single, self-contained step — one method, one file.

**Data flow:** Both `_apiService.getDashboardStats(...)` and `_apiService.getServiceMetrics()`
still start concurrently. The metrics future gets its own `try`/`catch` (or equivalent — e.g.
`Future.catchError` composed before both are awaited together — the concurrency must be
preserved either way, don't await metrics before starting the stats call). On any exception from
the metrics future: log it, substitute an empty list, and continue building the returned
`DashboardStats` exactly as if `getServiceMetrics()` had returned `[]` (i.e. same code path as
the existing 404 case flows through `_mergeServiceMetrics`). On any exception from the
log-stats future: unchanged — rethrow as `AppException`, same as today.

**Edge cases:**
- Preserve concurrency. A sequential "try metrics, then try stats" implementation would add
  latency for no reason — both must still be in flight at the same time.
- The existing per-endpoint `CancelToken` tracking (`_issueToken`) in `ApiService` is keyed
  separately per endpoint already — confirm a metrics-call failure/cancellation doesn't affect
  the log-stats call's token, and vice versa (should already be true, just verify, don't assume).
- A metrics fetch that throws a non-`DioException` (e.g. a JSON-parsing exception inside
  `parseServiceMetricsResponse` on a malformed-but-200 response) must also be caught here —
  don't narrow the catch to `DioException` only, since a parse-time crash is exactly the kind of
  failure this step exists to isolate.
- Do not change `ApiService.getServiceMetrics()`'s own 404-handling or its decision to propagate
  non-404 errors — that distinction is correct and should be preserved. The fix belongs at the
  repository layer, which decides how much a metrics failure should matter to the overall
  `getStats()` call — not at the API layer, which should keep reporting what actually happened.

**Design decision — flagging this rather than picking silently:** there are two ways to make
this fix, and they are not equivalent:
- *(Rejected)* Make `ApiService.getServiceMetrics()` itself swallow all errors, not just 404.
  Simpler, but destroys the "missing route vs. broken route" distinction everywhere in the app,
  including for any future caller that isn't the dashboard (e.g. a future admin/diagnostics
  view) and might legitimately want to know the difference.
- *(Recommended)* Keep `ApiService.getServiceMetrics()` exactly as it is today (throws on real
  errors); catch that specific failure at the `DashboardRepository.getStats()` call site instead,
  log it, and continue. This preserves the useful signal at the layer that produces it, while
  fixing the isolation problem at the layer that was over-broadly propagating it.

Use the recommended approach.

**Logging:** `DashboardRepository` does not currently hold a logger. Add one the same way
`ApiService` already does (a local `Logger` instance from the `logger` package, no dependency
injection needed — match the existing pattern rather than introducing a new one). Log at warning
level with enough detail to debug later (the exception, not just "metrics failed").

---

## Step 2 — Tests

**What:** Add a test file for `DashboardRepository.getStats()` (none currently exists) covering:
- Metrics future throws a non-404 error → `getStats()` still succeeds; returned `DashboardStats`
  has the log-stats data unchanged, and `serviceStats` reflects the same merge outcome as if
  metrics had returned `[]` (i.e. matches existing 404-case behavior).
- Log-stats future throws → `getStats()` still fails (unchanged from today — this must **not**
  regress; a mistake here would be at least as bad as the bug being fixed).
- Both futures succeed → unchanged existing merge behavior (regression check against Phase 20's
  existing test coverage for `_mergeServiceMetrics`).
- Metrics future throws a non-`DioException` (e.g. a generic parse exception) → same soft-fail
  outcome as a `DioException`, confirming the catch isn't accidentally narrowed to one exception
  type.

**Why:** This method has no existing test coverage at all, and it's exactly the kind of
error-handling logic that regresses silently without one — this fix could easily be undone by a
future refactor without a test guarding it.

**Sequencing:** After Step 1.

**Data flow:** N/A — verification only.

**Edge cases:** None beyond the four cases above.

**Design decisions:** None.

---

## LOG.md update instruction (fill in and append to this repo's existing `log.md`)

Continue this repo's existing phase-log convention (append to `log.md` at the repo root, do not
create a separate file). After completing **each step above**, append an entry in this format:

```
## Phase 21, Step [N] — [short title]
Completed: [timestamp]
Branch/commit: [if applicable]

### What was done
[3-5 sentences describing what was actually implemented]

### Key facts for next step
- [logger setup chosen, exact catch structure, any judgment calls made]
- [...]

### Deviations from spec
[Any places the implementation differed from this spec, and why]

### Status
[DONE / PARTIAL — describe what remains if partial]
```

Paste each completed entry back to Claude when done.
