# Phase 24 — Cross-repo bug-fix pass (data layer, screens, config persistence)

**Audience:** anyone reading this repo's history later — this phase record is
retrospective, not a forward-looking spec. Unlike Phases 20-23, this work was
diagnosed and implemented in the same pass (an API/data-layer audit and a live
screen-by-screen review, both against real production data, surfaced these bugs;
they were fixed as found rather than specced ahead of time).
**Author:** Claude, in a single extended session with Kevin — docs unification
(the `PROGRESS.md` ledger) → API/data-layer audit → screen review (empty states,
then live production data) → this bug-fix phase, prompted by Kevin's "fix all
bugs, make a phase out of it."

## Background

Everything in this phase was **verified against real production data**
(`central-logging-service-858865328729...run.app`, the "Bevin Production"
connection), not just read from source or tested against empty states — several
of these bugs (the Log Detail crash, the Dashboard time-range bug) were only
discoverable that way; reading the code alone made them look correct.

## Bugs fixed

### 1. Log Detail page crashed on every single open
**File(s):** `lib/presentation/pages/log_details/log_details_page.dart`,
`lib/presentation/pages/log_details/tabs/detail_widgets.dart`,
`lib/presentation/pages/log_details/tabs/response_tab.dart`
**Symptom:** tapping any log card opened a page with a working AppBar but a
permanently blank body — no error, no skeleton, nothing.
**Root cause:** `BoxDecoration(border: Border(left: BorderSide(color: X), top/
right/bottom: BorderSide(color: Y)), borderRadius: ...)` — Flutter throws "A
borderRadius can only be given on borders with uniform colors" when a `Border`
has different per-side colors and a radius is also set. Present in three places:
the page header, the shared `DetailSection` widget (used by every tab), and the
Response tab's status card.
**Fix:** `Border.all()` (uniform) + `borderRadius` on the outer `Container`, with
the colored accent rendered as an actual `Container` child clipped by the rounded
corners (`IntrinsicHeight` + a stretched `Row`) — the same pattern
`error_group_card.dart` already used correctly. First attempt omitted
`IntrinsicHeight` and introduced a second real bug (still blank); caught by
re-testing against live data, corrected in the same phase.
**Commit:** `7fe527864f13d13ba80f34a5811d7e4ca9f5b098`

### 2. Logs tab never loaded on mount
**File:** `lib/presentation/pages/logs/logs_page.dart`
**Symptom:** opening the Logs tab showed "No Logs Found — Try adjusting your
filters" instead of real data or a real error — confirmed via network trace
showing zero API calls were ever made.
**Root cause:** `initState()` had no fetch call at all, unlike `ErrorsPage`/
`ServicesPage`, which both call their load function via `Future.microtask` in
`initState`. `LogsPage` relied solely on a configured-transition `ref.listen`,
which never fires for a user with nothing to transition from.
**Fix:** added the same `initState` fetch the sibling pages already use.
**Commit:** `8dd8966dbfa5690bad40dc3a809d2b8f6fe7129b`

### 3. Settings screen layout overflow at phone width
**File:** `lib/presentation/pages/settings/settings_page.dart`
**Symptom:** confirmed Flutter `RenderFlex` overflow ("RIGHT OVERFLOWED BY 32
PIXELS") on the "Configure API"/"Add Connection" row at 375px-wide viewports.
**Root cause:** plain `Row` + `Spacer()`, no wrap handling.
**Fix:** switched to `Wrap`, which drops the overflow to a second line.
**Commit:** `8dd8966dbfa5690bad40dc3a809d2b8f6fe7129b`

### 4. ErrorGroup ignored the server's authoritative status code
**File:** `lib/data/models/error_group.dart`
**Symptom:** none visible, but a correctness/simplicity issue — `d607640` (an
earlier commit) added client-side heuristic status-code guessing
(`inferredStatusCode`: regex over the message, scanning `instances`) 5 minutes
before `central-logging-service` started returning the real value
(`sampleStatusCode`, from the log's own structured `statusCode` field) in the
same API response.
**Fix:** `ErrorGroup.fromApiJson` now reads `sampleStatusCode`; the heuristic is
kept only as a fallback for server responses that predate that field.
**Commit:** `d72782d684529633ec1a971c4a28dfe354b6745f`

### 5. API key silently reverted when editing an existing connection
**File:** `lib/presentation/providers/service_providers.dart`
**Symptom** (reported directly by Kevin): the API key doesn't reliably stay set;
editing a connection shows the Service URL but not the key (expected — secrets
aren't echoed back), and re-entering the key and saving still doesn't make it
stick.
**Root cause:** `ApiConfigNotifier.configure()`'s existing-profile-update branch
called `currentProfiles[index].copyWith(baseUrl: baseUrl)` — omitting `apiKey`.
The freshly-typed key *was* correctly written to secure storage
(`storage.setProfileApiKey(...)`), but the in-memory `ApiConnectionProfile`
object kept its old (often empty) `apiKey`, and that stale value is what got used
a few lines later to reconfigure the live `ApiService` (the actual Dio client
sending `X-API-Key`) and to populate the returned state. So the new key was
persisted but never actually took effect for the running session, and looked
identical to "the key didn't save."
**Fix:** `copyWith(baseUrl: baseUrl, apiKey: apiKey)` — one missing field.
**Commit:** `1a080f1f2c5cd9aaca1b3ee92c1a755403f592e5`

### 6. Theme picker's "System" label wrapped at phone width
**File:** `lib/presentation/pages/settings/settings_page.dart`
**Symptom:** "Syste"/"m" wrap in the 3-segment theme `SegmentedButton` at 375px.
**Root cause:** `SegmentedButton` divides its parent's full width evenly across
all segments regardless of content — not enough room for icon + "System" text.
Three different layout-level fixes were tried (scroll wrapper, tighter
padding/smaller icons) and either didn't help or made it worse (all three labels
wrapped instead of one).
**Fix:** renamed the label to "Auto" (a common convention for this exact toggle)
— the underlying `themeMode` value sent to the provider is unchanged (`'system'`).
**Commit:** `1a080f1f2c5cd9aaca1b3ee92c1a755403f592e5`

### 7. Dead code: `LogFilter.toQueryParams()`
**File:** `lib/data/models/log_filter.dart`
Never called anywhere (`ApiEndpoints.buildLogsQuery` is what's actually used).
Independently re-implemented the same `search`/`q` bug fixed server-side below.
Deleted.

### 8. `central-logging-service`: log search silently ignored
**File:** `src/routes/logs.js` (CLS-12)
**Symptom:** the Logs page search bar and Errors tab's "Find Similar"/"View
Similar" actions all silently returned unfiltered results — confirmed live by
capturing the actual outgoing request (`...&search=...`) getting `200 OK` with
zero matches despite thousands of matching entries existing.
**Root cause:** `GET /api/v1/logs` only ever read a `q` query param; LogPulse
Analytics has always sent `search`.
**Fix:** `search` now aliases `q` (additive; `q` stays canonical for any other
caller). **Not yet deployed** — see Next Steps.
**Commit:** `70a93f382095b52256d39a6adb32f57c0a9ff35d` (central-logging-service)

### 9. `central-logging-service`: Dashboard's time-range selector was fake
**File:** `src/routes/logs.js` (CLS-13)
**Symptom:** switching LogPulse's Dashboard time-range pills (1h/24h/7d/30d)
never changed Total Logs, Error Rate, Avg Latency, or the Service Health list —
confirmed live by switching to "1h" and watching those numbers not move while
the Traffic & Errors chart directly below correctly emptied to "No data."
**Root cause:** `GET /logs/stats/summary` destructured only `service`/`from`/
`to` — never `timeRange`, unlike its three sibling routes
(`/logs/stats/timeseries`, `/logs/errors/groups`, `/services`), which all
correctly resolve it via the already-shared `resolveTimeseriesWindow()` helper.
Since the client never computed `from`/`to` itself (only ever sent `timeRange`),
this route's `matchQuery` was always `{}` — every call aggregated the service's
entire history, unconditionally.
**Fix:** the route now calls `resolveTimeseriesWindow(req.query)`, matching its
siblings. Also added `$sort: {totalRequests: -1}` to the `byService` facet —
`$group` has no ordering guarantee, which was visibly reshuffling the Dashboard's
Service Health list between identical-window refreshes. **Not yet deployed** —
see Next Steps.
**Commit:** `70a93f382095b52256d39a6adb32f57c0a9ff35d` (central-logging-service)

## Explicitly not fixed in this phase (tracked separately, not bugs in the
## same sense)

- **`@bevingh/auth` private package** (CLS-02) — open-source readiness blocker,
  needs a product decision (publish/inline/accept friction), not a code fix.
- **GCS cold-storage never implemented** (CLS-01) — docs vs. code disagreement,
  needs a decision (build it or drop it from the docs), not a code fix.
- **Exposed API key in `test_api.dart`/`test_api_2.dart`** — needs key rotation
  and/or a git history rewrite, both requiring Kevin's explicit sign-off; not
  something to silently fix as part of a bug-fix pass.
- **`academicx-api` vs `Academicx` showing as two separate catalog rows** — a
  producer-side naming inconsistency (logs use one identifier, telemetry uses
  another), not a LogPulse or CLS bug — both are correctly rendering/returning
  the union as designed.

## Next Steps (carried into Human pass queue / PROGRESS.md)

1. **Deploy `central-logging-service` to production and smoke-test.** CLS-12 and
   CLS-13 are committed but this sandbox has no way to build, run, or deploy the
   service (`node_modules` needs a private-registry PAT it doesn't have — see
   CLS-02) — LogPulse's live app only talks to production Cloud Run, so neither
   fix takes effect until deployed. Verify after deploy: (a) typing a search term
   in the Logs page actually filters, (b) switching the Dashboard's time-range
   pills actually changes the stat cards and Service Health list.
2. **Kevin to verify the API key fix** by editing the existing connection's key
   and saving — this needs a real key typed into the app, which is outside what
   this session can do itself.
3. Everything else from the pre-existing backlog (LP-05/LP-06/LP-14/LP-24/LP-25,
   CLS P3 stage timings, etc.) is unaffected by this phase — see `BACKLOG.md`
   and `PROGRESS.md`'s Next Steps for that queue.

## log.md update instruction

Append to this repo's `log.md`:

```
## Phase 24 — Cross-repo bug-fix pass
Completed: 2026-09-14
Commits: 7fe5278 (Log Detail crash), 8dd8966 (Logs init-load + Settings overflow),
d72782d (ErrorGroup sampleStatusCode), plus this phase's own commit (API key
persistence + Auto label + dead code removal), and central-logging-service
70a93f3 (CLS-12 search alias + CLS-13 timeRange fix).

### What was done
Nine bugs fixed across both repos, all found via a live API/data-layer audit and
a screen-by-screen review against real production data rather than empty-state
testing alone. Most severe: Log Detail's page body was blank on every single
open (Flutter's Border+borderRadius restriction, hit in 3 places); the Dashboard
time-range selector didn't do anything (server-side, CLS-13); and editing a
saved API key silently failed to take effect (one missing field in a copyWith
call).

### Key facts for next step
- CLS-12/CLS-13 are code-complete and committed but NOT deployed — this
  sandbox can't build/deploy central-logging-service (no node_modules, no
  registry access). Someone with deploy access needs to ship and smoke-test.
- The API key persistence fix needs Kevin to verify live (can't type a real key
  in this session).

### Deviations from spec
N/A — this phase had no upfront spec; bugs were fixed as found during review.

### Status
DONE (code), PENDING (CLS deploy + live verification of both CLS fixes and the
API key fix).
```
