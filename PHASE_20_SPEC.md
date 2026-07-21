# Phase 20 — Reconcile Metrics UI with the Real Read API (PR-24)

**Audience:** the secondary AI (CLI) implementing this in the `logpulse_analytics` repo.
**Author:** Claude, acting as reasoning/architecture AI in the split-AI workflow for this repo.
**Do not deviate from this spec without noting the deviation in the LOG.md entry (see the end of this document).**

## Background (read this before Step 1)

`central-logging-service` PR-24 shipped `GET /api/v1/metrics?appId=<optional>` — a real,
live, tested read route. The code already in this repo (`ServiceMetricsEntry`,
`ApiEndpoints.metricsSummary`, `parseServiceMetricsResponse()`,
`DashboardRepository._mergeServiceMetrics()`, `ServiceStats`, `ServiceHealthCard`) was written
earlier against a *guessed* contract that does not match what PR-24 actually returns. Full
field-by-field diff, if you need the raw evidence: `central-logging-service/docs/METRICS_READ_CONTRACT.md`.

The real response shape, per app, is:
```
{
  appId: string,
  health: { status: string, instanceId: string, uptimeSeconds: number, timestamp: ISO string } | null,
  metrics: { ...free-form... } | null,
  metricsReportedAt: ISO string | null
}
```

Two things make this more than a rename job:

1. `ServiceStats.hasHealthMetrics` currently requires `errorRate`, `avgLatency`, AND `uptime`
   (a percentage) to all be non-null. PR-24 provides none of those three. A path/field-rename-only
   fix would leave the dashboard showing "not reporting metrics yet" forever, even for an app
   that is successfully sending real health pings.
2. `ServiceStats.healthStatus` (drives the health card's dot color and pulse animation) is
   derived entirely from `errorRate` thresholds today — it has no path that considers a real
   `health.status` string at all.

`ServiceHealthCard` is confirmed (by searching the whole `lib/` tree) to be the *only* consumer
of these health-related `ServiceStats` fields, so the UI blast radius is one widget file. The
instance-count badge and custom-metric chips are separate concerns — see Step 5's edge cases.

---

## Step 1 — Fix the request contract

**What:** In `lib/core/constants/api_endpoints.dart`, change `metricsSummary` from
`/metrics/summary` to `/metrics`. In `buildMetricsSummaryQuery`, remove the `timeRange` query
parameter entirely — do not send it.

**Why:** PR-24's route has no `/summary` suffix, so every request today 404s. LogPulse's
existing 404-tolerance (`ApiService.getServiceMetrics`) silently converts that into an empty
list, which is why this has been invisible rather than erroring loudly. Separately, PR-24 only
accepts an optional `appId` query param — there is no server-side time-range filtering
(latest-snapshot only). Sending `timeRange` today is harmless (silently ignored) but implies a
capability that doesn't exist; remove it rather than leave a misleading parameter in the code.

**Sequencing:** First. Every later step depends on the client actually reaching the real route.

**Data flow:** Outbound request shape only — no response parsing changes in this step.

**Edge cases:** Confirm `ApiService._apiRoot` (base URL + `AppConstants.apiBasePath`) composes
`/metrics` the same way it composes `/logs` today — i.e. this is a like-for-like path change,
not a new composition pattern.

**Design decisions:** None — this is a direct correction to match the real, already-shipped route.

---

## Step 2 — Rewrite the response parser for the real shape

**What:** In `parseServiceMetricsResponse()` (`lib/data/services/api_service.dart`), stop
reading the old guessed flat fields (`errorRate`, `avgLatency`, `uptime`, `lastReportedAt`) from
the top level, and instead read the real nested shape: `health.status`, `health.uptimeSeconds`,
`health.timestamp`, and top-level `metricsReportedAt`. Add two new fields to
`ServiceMetricsEntry` (`lib/data/models/service_metrics_entry.dart`) to carry this data: a raw
health-status string, and a raw uptime-in-seconds integer. **Keep these two new fields
completely separate from the existing `uptime` field** — `uptime` is typed and formatted
elsewhere as a percentage (`'${uptime}%'`) and nothing on the server computes a percentage; it
must stay `null`. Do not repurpose it to hold seconds.

**Why:** Without this, the app never extracts `health.status` or `health.uptimeSeconds` even
after Step 1 fixes the path. And aliasing `uptimeSeconds` into the percentage-typed `uptime`
field would render nonsense (e.g. "up 86400.0%") the moment any real data arrives.

**Sequencing:** Depends on Step 1. Must complete before Step 3 (the model layer can't carry data
the parser hasn't extracted) and Step 5 (the UI can't show what the model doesn't have).

**Data flow:** Raw JSON entry → `ServiceMetricsEntry` with the two new nullable fields
populated. The existing `metrics` (custom free-form map) field already matches PR-24's shape
1:1 — no change needed there. For the "last reported" timestamp: prefer `metricsReportedAt`
when present, but fall back to `health.timestamp` when only a health document exists (a health
doc and a metric doc are independent — either can be present without the other).

**Edge cases:**
- `health` is `null` (app reports metrics but never called `reportHealth()`) — new fields stay null, `metrics` still populates normally.
- `metrics` is `null` (app only reports health) — new fields populate, `customMetrics` stays null.
- `health.status` missing or an unexpected type — leave the new field null rather than guessing or coercing.
- `health.uptimeSeconds` non-numeric or missing — defensive-parse the same way this function already handles other numeric fields (it has an existing int-coercion helper — reuse it, don't write a new one).

**Design decisions:** Name the new raw status field distinctly from the existing `HealthStatus`
enum / `.healthStatus` getter elsewhere in the codebase, to avoid confusion between "the raw
string the server sent" and "the derived enum LogPulse computes for display." Suggest something
like a field literally named for what it is (the raw wire value), not `healthStatus` itself.

---

## Step 3 — Thread the new fields through ServiceStats and the merge logic

**What:** Add the same two new nullable fields to `ServiceStats`
(`lib/data/models/dashboard_stats.dart`) that Step 2 added to `ServiceMetricsEntry`. Wire them
through the constructor, `copyWith`, and `DashboardRepository._mergeServiceMetrics()`
(`lib/data/repositories/dashboard_repository.dart`) — that merge function has **two** branches
(one for "service exists in log-derived stats, merge metrics in" and one for "metrics-only app,
no logs at all") and both currently copy every other metrics field the same way; extend both,
not just one.

**Why:** `ServiceStats` is what the UI layer actually reads — `ServiceMetricsEntry` is just the
wire DTO. Without this step, Step 2's newly-extracted data reaches the repository and stops
there, never reaching the widget.

**Sequencing:** Depends on Step 2. Must complete before Step 4 and Step 5.

**Data flow:** `ServiceMetricsEntry` (new fields) → merged into `ServiceStats` (same new
fields), following the exact field-by-field copy pattern already used for `errorRate`,
`avgLatency`, `customMetrics`, etc. in both merge branches.

**Edge cases:** A service present in log-derived stats that never reports metrics at all —
new fields simply stay null, identical to today's behavior for the existing fields in that case.

**Design decisions:** None — mechanical extension of an existing, already-established pattern.

---

## Step 4 — Update health-status derivation logic

**What:** In `dashboard_stats.dart`, add a getter on `ServiceStats` that reports whether a real
(server-reported, non-computed) health status exists, independent of the numeric
`errorRate`/`avgLatency`/`uptime` fields. Update the existing `healthStatus` getter (currently:
numeric metrics present → derive from `errorRate` thresholds; otherwise → `HealthStatus.unknown`)
to add a middle branch: when numeric metrics are absent but the new raw status field is present,
derive a `HealthStatus` from that string instead of falling straight to `unknown`. Add a
formatting getter that renders the raw uptime-seconds field as a human-readable duration
(e.g. hours/minutes style), separate from the existing percentage formatter.

**Why:** This is the actual fix for the UI-impact problem described in Background — without it,
Steps 2–3 deliver real data into the model, but every existing derived getter is hard-wired to
numeric fields PR-24 doesn't provide, so nothing the user sees would change.

**Sequencing:** Depends on Step 3. Must complete before Step 5.

**Data flow:** Raw status string + raw uptime seconds in → existing `HealthStatus` enum +
formatted duration string out. This keeps the UI layer (Step 5) reading only getters, never raw
wire values.

**Edge cases:** The collector's health-status vocabulary is not formally documented beyond the
literal string `"ok"` seen in code/tests. Decide how to treat any other non-null status string.

**Design decision — flagging this explicitly rather than picking silently:** recommend mapping
`"ok"` → `HealthStatus.healthy`, and any other non-null status string → `HealthStatus.degraded`
(not `healthy`, not `unhealthy`) as the conservative default, since treating an unrecognized
status as healthy risks hiding a real problem, and treating it as unhealthy risks false alarms
for a status that doesn't actually mean "down." This default should be easy to revisit once the
collector's status vocabulary is documented — note it as a `TODO` comment at the mapping site.

---

## Step 5 — Update ServiceHealthCard to a three-state display

**What:** In `lib/presentation/widgets/cards/service_health_card.dart`, the detail line
currently has two states: the full numeric line (`"err X% · Yms · up Z%"`) when
`hasHealthMetrics` is true, or `"not reporting metrics yet"` otherwise. Add a third, in-between
state: when the new "real status present" getter from Step 4 is true but `hasHealthMetrics` is
still false, render the raw status label and the formatted uptime duration instead of falling
through to "not reporting." Wire the dot color/pulse animation to use the Step 4 `healthStatus`
getter as-is (it already handles all three cases once Step 4 lands) — no separate branching
needed there.

**Why:** This is the user-visible half of the fix. Everything in Steps 1–4 is invisible to
someone looking at the dashboard until this step lands.

**Sequencing:** Last code step. Depends on all of Steps 1–4.

**Data flow:** Purely presentational — reads getters added in Step 4, no new data fetching or
model changes.

**Edge cases:** Confirm the instance-count badge (`instanceCount`) and custom-metric chips
(`customMetrics`) are untouched by this change — they already read fields unrelated to health
status/uptime, and unaffected by this phase. **Do not attempt to make the instance badge appear
based on `health.instanceId`** — PR-24 returns a single latest instance's ID, not a count of
distinct instances; showing the badge based on presence of one ID would be misleading (implies
"1 instance," which is a fabrication risk this repo has specifically fixed once before — see
`log.md`'s fabrication audit). Leave `instanceCount` null and the badge hidden; this is a real,
documented gap (`central-logging-service/docs/METRICS_READ_CONTRACT.md` §4.4), not something to
paper over in this phase.

**Design decisions:** Exact wording/formatting of the new middle-state line is a judgment call —
match the existing line's style (JetBrains Mono, `textTertiary` color, "·"-separated segments)
rather than inventing a new visual style. The secondary AI should match this repo's existing
formatting conventions exactly rather than being given a literal string to copy.

---

## Step 6 — Tests and verification

**What:** Extend the existing test suite (the 13 tests referenced in prior session logs, plus
the two files' own unit tests) with fixtures matching PR-24's actual response shape — nested
`health` object, top-level `metrics`, top-level `metricsReportedAt` — including at least: a
health-only fixture, a metrics-only fixture, a both-present fixture, and a neither-present
fixture. Add a test asserting the Step 5 middle UI state renders correctly for the
both-missing-numerics-but-status-present case. Run `flutter analyze`.

**Why:** Tests written in the earlier phase were written against the wrong (guessed) contract.
They may currently pass while testing something that will never occur in production — fixtures
need to match reality, or the test suite gives false confidence.

**Sequencing:** Last. Needs all prior steps' code to exist.

**Data flow:** N/A — verification only.

**Edge cases:** None beyond the four fixture combinations listed above.

**Design decisions:** None.

---

## LOG.md update instruction (fill in and append to this repo's existing `log.md`)

This repo already has its own phase-log file at the repo root (`log.md`, lowercase — not a new
file). After completing **each step above**, append an entry there in this format, continuing
this repo's existing phase-log convention rather than creating a separate `LOG.md`:

```
## Phase 20, Step [N] — [short title]
Completed: [timestamp]
Branch/commit: [if applicable]

### What was done
[3-5 sentences describing what was actually implemented]

### Key facts for next step
- [field names added, exact getter names chosen, file paths touched, any judgment calls made]
- [...]

### Deviations from spec
[Any places the implementation differed from this spec, and why]

### Status
[DONE / PARTIAL — describe what remains if partial]
```

Paste each completed entry back to Claude before starting the next step, so field/getter names
chosen during implementation carry forward correctly into later steps' code (Steps 3-5 in
particular depend on the exact names Step 2 and Step 4 choose).
