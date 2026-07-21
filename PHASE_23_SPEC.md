# Phase 23 — Dedicated Services Tab

**Audience:** the secondary AI (CLI) implementing this in the `logpulse_analytics` repo.
**Author:** Claude, acting as reasoning/architecture AI in the split-AI workflow for this repo.
**Do not deviate from this spec without noting the deviation in the LOG.md entry (see the end of this document).**

## Background (read this before Step 1)

Most of the data layer for this already exists and is verified working — this phase is smaller
than Phases 20-22, mostly navigation and one new list page.

Confirmed already in place:
- `ServicesRepository.listServices()` / `.getService(name)` calling `GET /api/v1/services` and
  `GET /api/v1/services/:name` (CLS P2, landed).
- `servicesListProvider` (`ServicesListNotifier` / `ServicesListState`) — a working catalog list
  provider with `load({timeRange})`, loading/error state, already wired to the repository. Not
  currently consumed by any page.
- `serviceDetailProvider` (family by name) + `ServiceDetailsPage` — a complete, working detail
  page (overview, health, metrics, instances, endpoints), reachable today via
  `Navigator.push(MaterialPageRoute(builder: (_) => ServiceDetailsPage(serviceName: name)))`
  from `ServiceHealthList` on the dashboard.
- `ServiceSummary` model (catalog row: `name`, `displayName`, `totalRequests`, `errorRate`,
  `avgLatency`, `lastSeen`, `instanceCount`) — **no health-status field**. The `/services` list
  route doesn't carry a health string per row (only `/services/:name` detail does, via the same
  `fetchLatestMetricsSnapshot` reuse the metrics route uses).
- A known placeholder, found verbatim in `service_health_list.dart`: the dashboard's "view all →"
  link currently opens *the first overflow service's detail page* instead of a real list, with a
  comment already saying `// full services list can replace this when a dedicated tab exists.`
  This phase is that replacement — fold it in rather than treating it as separate follow-up work.
- `HomePage` uses a plain `IndexedStack` + `NavigationBar`, indices from `NavIndex`
  (`navigation_provider.dart`), 4 destinations today: Dashboard·Logs·Errors·Settings. Every
  consumer of nav indices in the codebase (confirmed by search) goes through named methods
  (`goToLogs()`, `goToErrors()`, etc.) or `NavIndex.count` for bounds-checking — nothing hardcodes
  a raw index number. This means inserting a new tab and renumbering `settings` is low-risk; no
  hidden magic-number call sites to find and fix.
- `AutoRefreshBinder` runs one global timer (not tab-scoped) that currently refreshes
  `dashboardProvider`, `logsProvider`, and `errorsProvider` on an interval. `settingsProvider` is
  deliberately excluded (no live data). The new services catalog *is* live data and should join
  this loop.

---

## Step 1 — Navigation plumbing

**What:** Add a `services` entry to `NavIndex` positioned **before** `settings` (Dashboard · Logs
· Errors · Services · Settings), renumbering `settings` from `3` to `4` and `count` from `4` to
`5`. Add a `goToServices()` method to `NavigationNotifier` following the exact pattern of the
existing `goTo*()` methods. Add the new page to `HomePage`'s `pages` list and a matching
`NavigationDestination` to the `NavigationBar`, in the same position.

**Why:** Settings is configuration, not a data view — every other tab (Dashboard, Logs, Errors)
is a live-data view, and Services belongs with them. Keeping Settings last matches the
conventional placement for a settings/config tab and avoids putting a data tab after it.

**Sequencing:** First — everything else needs a destination to navigate to.

**Data flow:** N/A — pure navigation wiring.

**Edge cases:** None — confirmed above that no call site hardcodes a raw index, so renumbering
`settings` is safe.

**Design decisions:** Icon choice for the new destination is cosmetic — pick something that
reads as "catalog/list of services" distinct from the existing icons (Dashboard uses
`dashboard_outlined`, Logs uses `article_outlined`, Errors uses `error_outline`, Settings uses
`settings_outlined`); match the existing outlined/filled selected-state pattern.

---

## Step 2 — Build the Services catalog page

**What:** New page (e.g. `ServicesPage`) that renders `servicesListProvider`'s state as a list.
Trigger the initial load from `initState()` via `ref.read(servicesListProvider.notifier).load()`,
following the same initial-load pattern already used in `dashboard_page.dart` (`initState` →
`ref.read(...).notifier).loadX()`). Support pull-to-refresh calling the same `load()`. Each row
shows: service name/`label`, `totalRequests`, `errorRate` (formatted `%`, or "—" when null),
`avgLatency` (formatted `ms`, or "—" when null), `instanceCount` (only shown when `> 1`, same
"hide when not meaningful" rule already used elsewhere for instance counts), and `lastSeen`
(relative time, reuse the existing relative-time formatting already written for
`ServiceHealthCard`/`_compactRelative` rather than writing a second implementation of the same
thing). Tapping a row opens the existing `ServiceDetailsPage(serviceName: ...)` unchanged — do
not modify that page. Handle loading (spinner, matching other pages' style), error (retry
button, matching other pages' error-state style), and empty (a plain "no services reporting yet"
message, not a spinner or blank screen) states explicitly.

**Why:** This is the actual feature — a real, complete catalog view instead of the current
"view first overflow service's detail" placeholder.

**Sequencing:** Depends on Step 1 (needs somewhere to be mounted). Independent of Steps 3-4 in
principle, but land before them since they link to this page.

**Data flow:** `servicesListProvider` (already built) → row list → tap → existing
`serviceDetailProvider`/`ServiceDetailsPage` (already built, unchanged).

**Edge cases:** A service with `null` `errorRate`/`avgLatency` (present in the catalog but never
reported those — same "honest null, not fabricated" principle used throughout this app) must
show "—", not `0` or a crash. Empty catalog (no services at all) must not be confused with a
loading or error state.

**Design decision — flagged rather than picked silently:** `ServiceSummary` (the catalog model)
has no health-status string field — only `errorRate`. Two options: (a) show a colored status dot
per row derived from `errorRate` using the **same thresholds** already used in
`ServiceStats.healthStatus`'s numeric branch (`<1% healthy, <5% degraded, else unhealthy`, grey
when `errorRate` is null) for visual consistency with the rest of the app, or (b) keep the
catalog purely informational (name + numbers, no color-coded health at the list level, since deep
health detail already lives one tap away on `ServiceDetailsPage`). Recommend (a) — reusing the
exact same thresholds costs little and keeps the app's visual language for "what does a color
mean" consistent everywhere a service is listed. **Do not invent a new set of thresholds** —
import/reuse the existing ones rather than duplicating threshold literals in a second place.

**Do not build a new widget by feeding `ServiceSummary` through `ServiceHealthCard`** — that
widget is typed for `ServiceStats` (a different model, from the dashboard/metrics merge, carrying
fields `ServiceSummary` doesn't have like `customMetrics`/`reportedHealthStatus`). Converting one
model into the other just to reuse a widget would be a type-shape hack. Build a new, smaller row
widget for the catalog that matches the existing visual language (same fonts/colors/spacing
conventions as `ServiceHealthCard`) without pretending to be the same data.

---

## Step 3 — Fix the dashboard's "view all →" placeholder

**What:** In `service_health_list.dart`, replace the current behavior (`_openDetail(context,
entries[maxVisible].key)` — opens the first overflow service's detail page) with
`ref.read(navigationProvider.notifier).goToServices()`.

**Why:** This is the exact placeholder the original code comment flagged as temporary, now that
Step 1 gives it somewhere real to go.

**Sequencing:** Depends on Step 1 (needs `goToServices()`) and Step 2 (needs a real destination
worth going to).

**Data flow:** N/A — one call site, one behavior swap.

**Edge cases:** `ServiceHealthList` is a `ConsumerWidget`; confirm `WidgetRef` is already in
scope at the tap-handler call site (it is, per the existing `_openDetail` method signature) — no
new plumbing needed beyond swapping the call.

**Design decisions:** None.

---

## Step 4 — Register the catalog in auto-refresh

**What:** In `AutoRefreshBinder`, add `ref.read(servicesListProvider.notifier).load()` to the
same periodic block that already refreshes `dashboardProvider`, `logsProvider`, and
`errorsProvider`.

**Why:** The services catalog is live data (request counts, error rates, instance counts all
change over time) — it should stay fresh the same way the other three data views do, for the
same reason `settingsProvider` is deliberately excluded (it isn't live data, the catalog is).

**Sequencing:** Depends on Step 2 (provider must be in real use, not just defined) — technically
could land any time after Step 1, but do it last so it's tested against the finished page.

**Edge cases:** None beyond what the existing timer already guards (auto-refresh disabled,
API not configured — both already checked before the block runs).

**Design decisions:** None.

---

## Step 5 — Tests

**What:**
- Widget test: `ServicesPage` renders loading → list → tap-to-detail-navigation, using the
  existing `servicesListProvider`/repository test-double patterns already established elsewhere
  in this repo (e.g. `_FakeApiService` from `dashboard_repository_test.dart`).
- Widget test: empty catalog shows the "no services reporting yet" state, not a spinner.
- Widget test: a row with null `errorRate`/`avgLatency` shows "—", not `0` or a crash.
- Unit or widget test: `service_health_list.dart`'s "view all →" now calls `goToServices()`
  (verify via the navigation provider's state, not just that no exception is thrown).
- Confirm `NavIndex.count` bump doesn't break any existing test that hardcoded the old count of
  4 destinations (search for `NavIndex.count` or a literal `4` in existing nav-related tests
  before assuming none exist).

**Why:** This phase touches shared navigation state (`NavIndex`) that several other pages already
depend on — a regression here would be silent (wrong tab opens) rather than a crash, exactly the
kind of bug that needs a test rather than a visual check.

**Sequencing:** Last.

**Design decisions:** None.

---

## LOG.md update instruction

Append to this repo's `log.md` (recent entries use descriptive titles rather than strict
`Phase N, Step M` headers — either format is fine):

```
## Phase 23 — Dedicated Services tab
Completed: [timestamp]
Branch/commit: [if applicable]

### What was done
[what was actually implemented — nav renumbering, the new page, the health-color decision made]

### Key facts for next step
- [row widget name chosen, whether option (a) or (b) was used for status color, icon chosen]
- [...]

### Deviations from spec
[any places the implementation differed from this spec, and why]

### Status
[DONE / PARTIAL]
```

Paste the entry back to Claude when done.
