# PROGRESS.md — LogPulse Analytics

> Project ledger. Bootstrapped 2026-09-01 by the planner routine from git history and the
> ledger-shaped documents already in the repo (see Decisions log for what was consolidated).
> This file is the source of truth going forward; the documents it consolidates are left in
> place and referenced, not edited.

## Status Snapshot

- **Phase**: No phase is in progress. The last *specced* unit of work is Phase 23
  ("Dedicated Services tab" — `PHASE_23_SPEC.md`, `log.md` lines 939-960), landed
  2026-07-21 10:06 UTC (commit `1076640`). Two commits sit on top of it, neither
  documented in `log.md` or any phase spec (see Known Limitations KL-2609-k7):
  `92e6706` (asset-only launcher-icon regen, 2026-07-21 16:08 UTC) and `d607640`
  (client-side error-group status inference + working "Find Similar"/"View Trace"
  actions, 2026-07-21 23:50:05 UTC — see Decisions log for what this actually does
  and why it may now be partly redundant).
- **Blocking issues**:
  - ~~No `./scripts/green-gate.sh` exists~~ — **resolved 2026-09-14**: `842b0ca`
    added it. First run failed (3 analyzer warnings, 46 unformatted files); fixed in
    `fa277b6` (removed dead `_selectedProfileId` state, ran `dart format`). Gate is
    now green **except** 2 residual `unused_import` warnings in `test_api.dart`/
    `test_api_2.dart` — deliberately not touched, see the item below.
  - **New, higher severity — live API key committed to git, tracked, already
    pushed.** `test_api.dart`/`test_api_2.dart` (repo root) hardcode a live-looking
    key (prefix `cls_RBA8...` — full value deliberately not repeated here; see the
    files directly, or `.env`'s `API_KEY`, which matches) for the production
    `central-logging-service` Cloud Run instance. Both
    files are tracked (`git ls-files` confirms) and have been on `origin/main` since
    2026-06-17. Deleting the files does not remove the key from git history — this
    needs either a key rotation on the CLS side, a history rewrite before the repo
    goes public, or both. **Not resolved by this session** — see Human pass queue.
  - No CI workflow (`.github/workflows/` absent) — nothing runs the gate automatically
    on push.
- **Next action**: Docs are now unified into this ledger across both repos (LogPulse +
  `central-logging-service`, which now has its own `PROGRESS.md`). Per `BACKLOG.md` §2.5,
  remaining unblocked client work is P2 cleanup — see Next Steps below — plus the newly
  surfaced gate failures and cross-repo bug-status question.
- **Repo state**: Local `main` merged `origin/main`'s bootstrapped ledger this session
  (merge commit `cda3bea`) and is now **3 commits ahead of `origin/main`, not pushed**
  (`d607640`, `842b0ca`, `cda3bea`). Working tree has one uncommitted modification
  (`assets/app_icon.png`) and one untracked file (`docs/CLS_ERROR_GROUPS_MESSAGE_FIX_PR_BRIEF.md`)
  — both pre-existing when this session started, neither touched by ledger work, not
  yet explained (see Human pass queue).
- **Verified running**: **Verified this session** (2026-09-14) via `./scripts/green-gate.sh`
  on Kevin's local machine: `flutter test` — 76/76 pass, 12 test files (up from the
  11 the bootstrap ledger could only confirm by reading). `flutter analyze`/
  `dart format` initially failed, fixed in `fa277b6` — gate is now green except the
  2 warnings tied to the API-key exposure above (deliberately left, not a gap).
- **Machine**: Kevin's local MacBook (Flutter SDK at `~/flutter/bin`, confirmed
  working) — not the ephemeral sandbox the bootstrap ledger ran in. Toolchain
  availability can now be assumed normal for future sessions on this machine.

## Decisions log

Consolidated from `handoff_context.md` §4-5, `BACKLOG.md`, and `log.md` phase entries.
Dates are when the decision was last reaffirmed in the source documents, not rediscovered
today.

- **2026-07-21** — Flat `X-API-Key` header is the single auth mechanism for all read routes
  (logs + metrics GET) against `central-logging-service`. Metrics *write* keys
  (`sk_live_`/`sk_test_`) are a separate scheme and are not used by this client.
  (`handoff_context.md` §4)
- **2026-07-21** — Design principle, stated explicitly as "do not regress": never fabricate
  health/timeline/uptime numbers; never invent `instanceCount` from a single `instanceId`;
  metrics failures soft-fail at the repository layer, log-stats failures stay loud (surfaced
  to the user). (`handoff_context.md` §5)
- **2026-07-21** — Timeseries 404 fallback (bucket ≤200 raw logs client-side) is kept
  deliberately even though the real CLS timeseries endpoint is live, until the prod endpoint
  is proven stable. (`handoff_context.md` §5, `BACKLOG.md` §3.1)
- **2026-07-21 (Phase 22)** — `ErrorRateChart` uses independent Y-axis ranges for traffic
  (count) vs. error rate (%) rather than one shared `maxY`; the error series is projected
  into the traffic host's coordinate space only for plotting, with true percentages kept in
  a parallel array and looked up for tooltips (`trueErrorValueAtX`) rather than reading the
  transformed plot value. Error axis floor is hardcoded at `kErrorAxisFloorPercent = 5.0`,
  flagged in `log.md` as a TODO to revisit once real error-rate distributions are known.
- **2026-07-21 (LP-cleanup)** — `provider` and `http` packages dropped as dependencies
  (superseded by Riverpod and Dio respectively); dead `Service`/`EndpointStats` models and
  empty `service_details`/`charts` directories removed, then **rebuilt** once CLS P2 shipped
  real catalog routes (see LP P2 consumers entry below) — the removal was a hold, not a
  cancellation.
- **2026-07-21 (LP P2 consumers)** — `ErrorGroup` is hand-written (custom `fromApiJson`)
  rather than routed through `json_serializable`/`freezed`, specifically because it is a
  server-only shape with no client-side construction path — judged simpler than maintaining
  a `.g.dart` for it.
- **2026-03-03 (Phase 6)** — "Neo-Terminal" design token system adopted as the app's visual
  language (`d6272ae`), replacing ad hoc inline text styles across all screens by Phase 14.
- **2026-08-31 (green-gate policy)** — Recorded in `scripts/green-gate.sh`'s own header:
  the gate "runs whatever verification the repo actually has, never invents a step";
  missing test/lint/format is a **gap** (still passes) but an existing step that fails
  is a hard **failure**; `flutter analyze` warnings/errors fail the gate but *infos*
  are reported non-blocking, because on this repo 114 style infos were burying 3 real
  warnings and "a gate that is red for reasons nobody will act on trains you to ignore
  it." `--strict` promotes gaps to failures for repos expected to have none left.
- **2026-07-21 (d607640, client-side error-group workaround)** — `ErrorGroup` gained
  client-inferred `inferredStatusCode`/`isClientErrorGroup`/`isServerErrorGroup`
  heuristics (parsed from message/instance data, since the CLS groups API doesn't
  return a status code), and the previously-dead "Find Similar"/"View Trace" actions
  were wired up. The code explicitly skips the literal string `"unknown error"` as a
  placeholder — direct evidence the CLS "Unknown error" megagroup bug
  (`docs/CLS_ERROR_GROUPS_MESSAGE_FIX_PR_BRIEF.md`) was still live when this landed.
  **New finding this session**: `central-logging-service` commit `39de821` — "switch
  error grouping to application-side aggregation with improved message extraction" —
  landed 5 minutes later (23:55:23 UTC same day) and appears to be the actual
  server-side fix for that exact bug. Whether the client's `"unknown error"` skip
  logic is now dead weight (server no longer emits it) is unverified — see Next Steps.

## Known Limitations

Carried forward as **inherited** evidence (not re-verified against source this session)
unless marked new:

- **Inherited, `BACKLOG.md` §2.2/§2.3** — Several features are intentionally thin pending
  server support and are tracked with their own `LP-xx` ids there rather than duplicated
  here: stat card deltas always null (LP-06), `serviceHealthProvider.checkHealth()` unused
  by any UI (LP-09), `ApiEndpoints.ready` never called (LP-10), `ErrorGroup.isResolved`
  always `false` with no resolve UX (LP-12), metrics soft-fail is silent — a warning log
  only, no "metrics unavailable" UI chip (LP-14), `metricsSummary` naming is acknowledged
  as odd (LP-27, the value is actually `/metrics`).
- **Inherited, `log.md` line 927** — `ErrorRateChart`'s error-axis floor
  (`kErrorAxisFloorPercent = 5.0`) is a hardcoded placeholder, not derived from real
  distributions.
- **Inherited, `BACKLOG.md` LP-24/LP-25** — `build_runner` codegen has not been regenerated
  since related model changes; `.g.dart` files may be stale relative to hand-edited models.
  `flutter analyze` has known remaining info-level noise (e.g. deprecated `Radio` usage),
  partially cleaned but not finished.
- ~~**KL-2609-a3** — No automated verification gate exists~~ — **resolved
  2026-09-14**: `scripts/green-gate.sh` added (`842b0ca`), run for the first time,
  found 3 warnings + 46 unformatted files, fixed in `fa277b6`. Gate is green except
  KL-2609-key below. No CI workflow still exists to run this automatically.
- **New — KL-2609-key (security)** — `test_api.dart`/`test_api_2.dart` (repo root,
  tracked in git, pushed since 2026-06-17) hardcode a live-looking production
  `central-logging-service` API key (`cls_RBA8...`, matches `.env`'s `API_KEY`).
  Deleting the files doesn't remove the key from git history. Needs a decision: rotate
  the key on the CLS side, rewrite this repo's git history before it goes public, or
  both. Left in place, not deleted, pending that decision — see Human pass queue.
- **KL-2609-k7 (updated)** — `log.md` is now **two** commits behind `HEAD`, not one:
  still missing `92e6706` (asset-only, low risk) and now also missing `d607640`
  (error-group status inference + Find Similar/View Trace — a real feature commit,
  higher risk to leave undocumented than the asset regen was).
- **New — KL-2609-p2** — `PHASES.md` only documents Phases 1-14 and has not been touched
  since 2026-03-03. Phases 15+ exist only across `TELEMETRY_PATCH_PLAN.md` (phases ~16-21),
  `PHASE_20_SPEC.md`-`PHASE_23_SPEC.md`, and `log.md`'s prose entries, with no single index
  reconciling phase numbering across those documents. A reader relying on `PHASES.md` alone
  would believe the project stopped at Phase 14.
- **New — KL-2609-p15** — Phase 15 (animation/micro-interactions) status is
  contradictory across docs: `PHASES.md` and `log.md`'s own status table both say
  `⬜ Not Started`, but `handoff_context.md` (line 11) claims "partial 15 animations"
  were done. No `log.md` entry exists for any Phase-15 work either way. Unresolved —
  needs a direct look at `service_health_card.dart`/`dashboard_page.dart` for
  pulse/stagger animation code before this can be marked done, partial, or not started.
- **New — KL-2609-b1** — `BACKLOG.md` contradicts itself within the same document:
  §1's status table (line 30) says the Services tab is "Wired (Phase 23 catalog tab +
  existing detail)," but §4's cross-repo board (line 958) still lists "Optional:
  dedicated Services tab" as **future** work. The doc's own footer (line 996) is dated
  2026-07-21, "after Phases 16-21" — i.e. it predates Phase 23 entirely and was only
  ever partially hand-patched afterward.
- **New — KL-2609-lp04** — `BACKLOG.md` LP-04 ("view all → on Service Health goes to
  Logs, should list all services") is still listed open in §2.1, but Phase 23 Step 3
  (`goToServices()`, confirmed via `git show 1076640`) already fixed exactly this —
  the backlog row was never struck through.
- **New — KL-2609-search (functional bug, verified 2026-09-14)** — **Log search is
  completely non-functional in production.** `ApiEndpoints.buildLogsQuery()`
  (`lib/core/constants/api_endpoints.dart:47`) sends the search term as
  `?search=<term>`, but `central-logging-service`'s `GET /api/v1/logs` handler
  (`src/routes/logs.js:65-116`) only ever reads `req.query.q` — `search` is silently
  ignored, and the endpoint falls through to returning the default unfiltered
  time-windowed log list. This is not a doc-staleness issue; it's a live parameter-
  name mismatch between the two repos, confirmed by reading both sides' current code.
  **Three separate UI entry points route through this broken path**: the Logs page's
  own search bar, the Errors page "Find Similar" action (`errors_page.dart:368`,
  literally the feature `d607640` just wired up), and Log Detail's "View Similar"
  (`error_tab.dart:_viewSimilar`). All three silently degrade to "show the default
  log list" instead of actually filtering — no error is thrown, so this is easy to
  miss in casual use. No client-side fallback filtering exists to mask this (removed
  at some point after the 2026-06-17 `_applyLocalSearch` investigation).
- ~~**KL-2609-statuscode**~~ — **fixed 2026-09-14** (`d72782d`). Was:
  `ErrorGroup.fromApiJson`
  (`lib/data/models/error_group.dart`) never reads the `sampleStatusCode` field that
  `GET /api/v1/logs/errors/groups` already returns per group
  (`central-logging-service/src/routes/logs.js:573-574`, sourced from the log's own
  structured `statusCode` field via `extractErrorDisplay` — reliable, not guessed).
  Instead, `d607640` added `inferredStatusCode`, a client-side heuristic (regex over
  the message text, scanning `instances`, parsing `errorCode`) to reconstruct
  something the server already hands over directly. Likely sequencing: `d607640`
  (23:50:05 UTC) landed 5 minutes before the CLS commit that added `sampleStatusCode`
  (`39de821`, 23:55:23 UTC) — the client was never updated afterward to just use it.
- **New — KL-2609-deadquery** — `LogFilter.toQueryParams()` is dead code (never
  called anywhere; `ApiEndpoints.buildLogsQuery()` is what `api_service.dart`
  actually uses). It independently re-implements the same `search`/`q` mismatch as
  KL-2609-search, so if it's ever wired up later without fixing that first, the bug
  would resurface through a second code path. Low priority; noted so a future
  cleanup doesn't miss it.
- **New — KL-2609-wt** — Working tree has an uncommitted modification
  (`assets/app_icon.png`) and an untracked file
  (`docs/CLS_ERROR_GROUPS_MESSAGE_FIX_PR_BRIEF.md`) that predate this session and
  weren't explained by any doc read — flagged rather than committed or discarded (see
  Human pass queue).

## Next Steps

**0a. New, highest priority — fix KL-2609-search.** Log search is broken end-to-end
(three UI entry points, zero functional effect). Needs a cross-repo decision: make
`central-logging-service`'s `GET /api/v1/logs` accept `search` as an alias for `q`
(safer — no client change, no risk to any other existing `q`-based caller), or change
LogPulse to send `q` instead of `search` (simpler, but only fixes the client that's
actually broken today). Recommend the server-side alias unless there's a reason to
prefer `q` as the sole public param name.
~~**0b. Fix KL-2609-statuscode.**~~ — **done 2026-09-14** (`d72782d`): `ErrorGroup`
now reads `sampleStatusCode` and `inferredStatusCode` prefers it, falling back to the
heuristic only when it's absent. Added a regression test locking in the precedence.

Below, per `BACKLOG.md` §2.5, in the order that document recommends (all unblocked, no
further CLS dependency beyond what's already shipped):

1. **LP-05 / LP-21** — Now that CLS P2 catalog routes have shipped and been consumed
   (`log.md` "LP P2 consumers" entry), confirm `service_details/` and the `Service`-family
   models are fully wired rather than partially dead code left from the earlier removal/
   rebuild cycle.
2. **LP-04** — "view all →" on Service Health still routes to Logs in some paths per the
   backlog table; reconcile against Phase 23's `goToServices()` change, which may have
   already superseded this (the backlog row predates Phase 23 and was not confirmed
   updated).
3. **LP-24** — Regenerate codegen: `dart run build_runner build --delete-conflicting-outputs`.
4. **LP-25** — Clear remaining `flutter analyze` info-level noise (deprecated `Radio`, etc.).
5. **LP-14** — Add a "metrics unavailable" chip on the dashboard for the existing silent
   soft-fail path, or explicitly decide it's not worth the UI surface.
6. ~~**Process** — Add a `scripts/green-gate.sh`~~ — **done 2026-09-14** (`842b0ca`).
7. ~~**Fix the gate.**~~ — **done 2026-09-14** (`fa277b6`): removed dead
   `_selectedProfileId` state, ran `dart format` on the 46 flagged files. The 2
   remaining warnings in `test_api.dart`/`test_api_2.dart` are intentionally left —
   see KL-2609-key.
7a. **New — resolve KL-2609-key.** Rotate the exposed CLS API key and/or rewrite git
    history to remove it before this repo goes public. This blocks the open-source
    push independently of the `@bevingh/auth` blocker already flagged in CLS's ledger.
8. **New — verify cross-repo bug status.** Confirm whether `central-logging-service`
   commit `39de821` actually fixed the "Unknown error" megagroup bug that `d607640`'s
   `isClientErrorGroup`/`"unknown error"` skip logic works around, and if so, whether
   that client-side special-case can be simplified or removed.
9. **New — resolve KL-2609-p15** (Phase 15 status ambiguity) by checking the actual
   animation code, and KL-2609-b1/KL-2609-lp04 (`BACKLOG.md` self-contradiction and
   stale LP-04 row) by editing `BACKLOG.md` directly.
10. **New — log.md catch-up.** Add entries for `92e6706` and `d607640` (KL-2609-k7) so
    the execution log isn't further behind `HEAD`, or formally retire `log.md` in favor
    of this ledger's Changelog going forward (see Human pass queue — process decision).

No `TASK_SPEC` was produced for the 2026-09-01 bootstrap run (a ledger-creation run does
not produce one by its own process definition). This 2026-09-14 update is a doc-only
maintenance pass, also without a `TASK_SPEC` — the next planner/feature run should treat
items 7-10 above as ready to spec.

## Human pass queue

Decisions this ledger surfaced that are Kevin's to make, not the planner's:

- ~~Whether to invest in a `scripts/green-gate.sh` + CI workflow now~~ — decided: the
  script was added (`842b0ca`) and the gate failures it found were fixed (`fa277b6`).
  **Still open**: whether to add the CI workflow too.
- **Security — needs a decision before open-sourcing**: `test_api.dart`/
  `test_api_2.dart` have a live CLS API key committed and pushed (KL-2609-key). Rotate
  the key, rewrite history, or both?
- What `assets/app_icon.png` (uncommitted modification) and
  `docs/CLS_ERROR_GROUPS_MESSAGE_FIX_PR_BRIEF.md` (untracked) sitting in the working
  tree are for — both predate this session; not touched, but should be committed,
  discarded, or explained rather than left in limbo.
- Whether to push local `main` (3 commits ahead of `origin/main`: `d607640`, `842b0ca`,
  and this session's merge `cda3bea`) now, or hold until more of the docs/API/app pass
  is done.
- Whether CLS P3 (stage-timing/timeline spans, called out in `BACKLOG.md` LP-18 as
  something the client must **not** fabricate in the meantime) is worth pursuing, or stays
  parked indefinitely.
- Whether the `PHASES.md` / `TELEMETRY_PATCH_PLAN.md` / `PHASE_2x_SPEC.md` split
  (KL-2609-p2) should be consolidated into one phase index, or left as historical record
  with this `PROGRESS.md` as the only forward-looking document from here on.
- Whether `log.md` should keep being hand-maintained going forward or be formally
  retired in favor of this ledger's Changelog (KL-2609-k7 keeps recurring because two
  parallel logs are being kept).

## Changelog

- **2026-09-01** — `ledger:` Bootstrapped `PROGRESS.md`, this repo's first ledger.
  Consolidated: `README.md`, `handoff_context.md`, `BACKLOG.md`, `PHASES.md`,
  `TELEMETRY_PATCH_PLAN.md`, `PHASE_20_SPEC.md`..`PHASE_23_SPEC.md`, `log.md`,
  `docs/CLS_P2_PR_BRIEF.md`. Verified against `git log` (50 commits, 2026-02-16 →
  2026-07-21) rather than taking document claims at face value; found one gap
  (KL-2609-k7: `log.md` doesn't cover the last commit) and one staleness issue
  (KL-2609-p2: `PHASES.md` frozen at Phase 14 since 2026-03-03) in doing so. Could not
  verify: current `flutter analyze`/`flutter test` pass/fail state — no toolchain in this
  sandbox (KL-2609-a3). Commit: `a5c4d08d906f34c47968e16095c99b090aa1e222`.
- **2026-09-14** — `ledger:` Pulled origin's bootstrapped ledger into local `main`
  (merge `cda3bea`), which had diverged (2 local-only commits, 2 origin-only commits)
  — reconciled by merge per Kevin's choice, not force-resolved. Extended the ledger
  forward past the bootstrap: documented `92e6706` and `d607640` (KL-2609-k7),
  recorded the green-gate policy decision now that `842b0ca` actually landed it, and
  **ran the gate for real for the first time** (`flutter test` 76/76 pass across 12
  files; `flutter analyze`/`dart format` both fail — KL-2609-a3 updated with the
  concrete list). Cross-referenced against `central-logging-service`'s git history and
  found its commit `39de821` (5 minutes after this repo's `d607640`) likely fixes the
  "Unknown error" megagroup bug that `d607640`'s client-side workaround exists for —
  flagged for verification, not resolved here. Found three new doc inconsistencies:
  Phase 15 status ambiguity (KL-2609-p15), a self-contradiction inside `BACKLOG.md`
  (KL-2609-b1), and a stale LP-04 backlog row (KL-2609-lp04). Also bootstrapped a
  parallel `PROGRESS.md` for `central-logging-service` (the API this app consumes),
  using the same ledger format, so both halves of the project now share one
  documentation method. Did not touch `assets/app_icon.png` (uncommitted) or
  `docs/CLS_ERROR_GROUPS_MESSAGE_FIX_PR_BRIEF.md` (untracked) — pre-existing,
  unrelated to this pass, flagged in Human pass queue instead. Did not push to
  `origin` — local `main` is 3 commits ahead. Commit: `f7406748f900058b1c508045f805b1dbc6157382`.
- **2026-09-14 (same session, continued)** — Pushed the ledger commits to `origin`.
  Fixed the gate failures found above: removed dead `_selectedProfileId` state
  (`settings_page.dart`), ran `dart format` on the 46 flagged files (`fa277b6`).
  While doing so, found `test_api.dart`/`test_api_2.dart` — the two files
  contributing the remaining 2 analyzer warnings — hardcode a live production CLS API
  key and are tracked/pushed in git history (KL-2609-key). Did not delete or edit
  those files pending a decision on key rotation and/or history rewrite. Commit:
  `fa277b68619905c794638fda9b381aa02fc51f47`.
- **2026-09-14 (same session, API/data-layer conformance audit)** — Per Kevin's
  plan (unify docs → audit the API and what it hands the app → then review screens),
  read `central-logging-service`'s actual route handlers (`logs.js`, `metrics.js`,
  `services.js`, `health.js`, `jobs.js`) side-by-side with LogPulse's parsers/models
  to check real conformance, not just doc claims. Found and fixed
  KL-2609-statuscode (`d72782d`). Found and **left open** KL-2609-search (needs a
  cross-repo decision, see Next Steps 0a) and KL-2609-deadquery (minor). Confirmed
  solid, no action needed: `DashboardStats`/`ServiceStats` correctly consume
  `/logs/stats/summary`'s object-shaped `byService`; `ServiceSummary`/`ServiceDetail`/
  `EndpointStats`/`ServiceInstance` correctly consume `/services` and `/services/:name`;
  `TimeSeriesPoint` matches `/logs/stats/timeseries` exactly; `LogEntry`'s `_id`→`id`
  normalization (`api_service.dart:237,406`) correctly handles Mongoose's `.lean()`
  omitting the `id` virtual, with a regression test already covering it
  (`logs_page_parser_test.dart`); `/health` and `/jobs/purge-logs` have no client
  consumer in this repo (health is infra-only, purge is CLS-internal) so nothing to
  conform. Commit: `6ab940fc3e00698c00b5b74685fad8b32d81c8d0`.
