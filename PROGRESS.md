# PROGRESS.md — LogPulse Analytics

> Project ledger. Bootstrapped 2026-09-01 by the planner routine from git history and the
> ledger-shaped documents already in the repo (see Decisions log for what was consolidated).
> This file is the source of truth going forward; the documents it consolidates are left in
> place and referenced, not edited.

## Status Snapshot

- **Phase**: No phase is in progress. The last completed unit of work is Phase 23
  ("Dedicated Services tab" — `PHASE_23_SPEC.md`, `log.md` lines 939-960), landed
  2026-07-21 10:06 UTC (commit `1076640`). One commit sits on top of it
  (`92e6706`, "update application launcher icons and assets", 2026-07-21 16:08 UTC) —
  an asset-only regen not described in `log.md` or any phase spec.
- **Blocking issues**:
  - No `./scripts/green-gate.sh` (or any `scripts/` directory) exists — there is no
    single gate command for this project yet.
  - No CI workflow (`.github/workflows/` absent) — nothing runs tests/analyze automatically
    on push.
  - This session's sandbox has no Flutter/Dart toolchain (`flutter`/`dart` not on `PATH`),
    so `flutter test` / `flutter analyze` could not be executed to verify current state
    against the 11 test files under `test/`. Test suite existence and shape were confirmed
    by reading, not by running.
- **Next action**: Per `BACKLOG.md` §2.5 ("Suggested LogPulse implementation order"), the
  remaining unblocked work is P2 cleanup — see Next Steps below. No CLS (server-side)
  work is currently specced beyond the already-shipped P0/P1/P2 routes.
- **Repo state**: Clean working tree. Branch `claude/serene-fermi-jij7zo` at `92e6706`
  (50 commits total, first commit 2026-02-16, most recent 2026-07-21 — no commits in the
  6 weeks since, until this ledger).
- **Verified running**: Not verified this session — no toolchain available to build/run the
  app or execute its test suite (see Blocking issues).
- **Machine**: Ephemeral remote execution container for this session; no Flutter SDK
  installed. Not the developer's regular machine — no assumptions about local toolchain
  availability should be inherited from this entry.

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
- **New — KL-2609-a3** — No automated verification gate exists in this repo: no
  `scripts/green-gate.sh`, no CI workflow. Nothing currently runs `flutter analyze` or
  `flutter test` automatically on a change. This session additionally had no Flutter/Dart
  toolchain available at all, so even manual verification wasn't possible here — that part
  is a sandbox constraint, not a repo defect, but the absence of any gate is a repo defect.
- **New — KL-2609-k7** — `log.md`, the project's execution log, is one commit behind `HEAD`:
  it documents Phase 23 as the last completed unit of work but has no entry for the
  subsequent launcher-icon asset commit (`92e6706`). Low risk (asset-only change) but the
  ledger discipline described in this document's own process was not followed for that
  commit.
- **New — KL-2609-p2** — `PHASES.md` only documents Phases 1-14 and has not been touched
  since 2026-03-03. Phases 15+ exist only across `TELEMETRY_PATCH_PLAN.md` (phases ~16-21),
  `PHASE_20_SPEC.md`-`PHASE_23_SPEC.md`, and `log.md`'s prose entries, with no single index
  reconciling phase numbering across those documents. A reader relying on `PHASES.md` alone
  would believe the project stopped at Phase 14.

## Next Steps

Unblocked, no CLS (server) dependency — per `BACKLOG.md` §2.5, in the order that document
recommends:

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
6. **Process** — Add a `scripts/green-gate.sh` (or equivalent) that runs `flutter analyze`
   and `flutter test` in one command, so future ledger entries have a real signal to check
   per this document's own Step 3 gate requirement (see Human pass queue — this is a
   process decision, not a unilateral one).

No `TASK_SPEC` was produced this run — this is a bootstrap (ledger-creation) run, which by
its own process definition does not produce one. The next planner run should treat item 6
above as worth specing before or alongside any feature-shaped task, since without a gate
script every future "Step 3" will have to fall back to "no verification signal available."

## Human pass queue

Decisions this ledger surfaced that are Kevin's to make, not the planner's:

- Whether to invest in a `scripts/green-gate.sh` + CI workflow now (KL-2609-a3), or continue
  relying on manual `flutter test`/`analyze` runs — this materially changes how much future
  planner runs can trust "done" claims in specs.
- Whether CLS P3 (stage-timing/timeline spans, called out in `BACKLOG.md` LP-18 as
  something the client must **not** fabricate in the meantime) is worth pursuing, or stays
  parked indefinitely.
- Whether the `PHASES.md` / `TELEMETRY_PATCH_PLAN.md` / `PHASE_2x_SPEC.md` split
  (KL-2609-p2) should be consolidated into one phase index, or left as historical record
  with this `PROGRESS.md` as the only forward-looking document from here on.

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
