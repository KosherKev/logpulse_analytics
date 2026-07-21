# Phase 22 — Fix Traffic/Error Chart Y-Axis Scale

**Audience:** the secondary AI (CLI) implementing this in the `logpulse_analytics` repo.
**Author:** Claude, acting as reasoning/architecture AI in the split-AI workflow for this repo.
**Do not deviate from this spec without noting the deviation in the LOG.md entry (see the end of this document).**

## Background (read this before Step 1)

`ErrorRateChart` (`lib/presentation/widgets/dashboard/error_rate_chart.dart`) plots two series
on one chart: `trafficPoints` (request count per bucket, unbounded — could be 5 or 5,000) and
`errorPoints` (error rate as a 0–100 percentage, from `TimeSeriesPoint.errorRatePercent` via
`dashboard_page.dart`). Verified in the current code: `maxY` is computed from
`[...traffic, ...errors]` combined — one shared linear axis for two series with fundamentally
different units. In practice, when traffic dominates (the normal case), the error line gets
squashed near the bottom and reads as flat/near-zero even when the real error rate is
meaningfully varying. When traffic happens to be small, the two lines can sit at deceptively
similar heights despite meaning unrelated things (a count vs. a rate).

**Decision made (confirmed with the project owner):** keep one overlay chart rather than
splitting into two charts or normalizing both to 0–100% of their own peak. Rescale the error
series into the traffic series' coordinate space for plotting only, keep the true percentage
value available for the tooltip, and label both axes (left = counts, right = %) so the chart is
honest about what each line means. This preserves the at-a-glance traffic/error correlation the
overlay design was going for, at the cost of moderate implementation work (fl_chart has no
native secondary Y-axis — this is the standard fake-dual-axis technique: transform one series'
plotting coordinates into the other's range, decouple the axis *labels* from the actual plotted
coordinates).

Tooltips already correctly format each series in its own unit (fixed in the prior session, per
`getTooltipItems`'s `isTraffic`/`isErrorRate` branching) — **do not regress this.** The main risk
in this phase is exactly that: transforming error points for plotting will silently break the
tooltip's correctness unless the true values are kept queryable separately (see Step 2/4).

---

## Step 1 — Compute two independent axis ranges

**What:** Replace the single shared `maxY` (from `[...traffic, ...errors]`) with two
independently computed ranges:
- **Traffic range** `[0, trafficMaxY]`: `trafficMaxY = max(traffic y-values) * 1.25`, same
  headroom multiplier as today; falls back to `1.0` when traffic is empty or all-zero (matches
  the existing zero-guard).
- **Error range** `[0, errorMaxY]`: `errorMaxY = max(max(error y-values) * 1.25, floor)`, where
  `floor` is a minimum percentage-point range (recommend `5.0`) so a near-flat, very-low error
  rate (e.g. a steady 0.3%) doesn't get stretched to fill the whole chart height and read as
  artificially volatile. Clamp `errorMaxY` to a maximum of `100.0` (a rate can't exceed that,
  even though it will rarely approach it).

**Why:** This is the actual fix — the two series must never share one axis by accident again.
The floor on the error range exists because percentages are naturally bounded at 100 but in
practice usually sit in low single digits; without a floor, auto-scaling a mostly-flat low error
rate to fill the chart would visually exaggerate noise into what looks like real volatility.

**Sequencing:** First — every later step depends on having both ranges.

**Edge cases:** Traffic empty but errors present (defensively handle — traffic range still needs
a nonzero host scale, default `1.0`, same as today's zero-guard). Both series empty — unchanged,
falls through to the existing "No data" branch.

**Design decision — flagged rather than picked silently:** the `5.0` percentage-point floor is a
judgment call with no objectively correct value. Mark it with a `// TODO: revisit once real
telemetry gives a sense of typical error-rate distributions` comment at the definition site,
matching the pattern already used for the health-status-vocabulary mapping in Phase 20.

---

## Step 2 — Build the plotting transform; preserve true values

**What:** Traffic points plot unchanged — they define the host coordinate space. For error
points, build a *transformed* `FlSpot` list for `LineChartBarData.spots` where each point's y is
`(trueErrorValue / errorMaxY) * trafficMaxY` (projecting the error series into the traffic axis's
coordinate range, since `LineChartData` only exposes one `minY`/`maxY` for the whole chart — this
is the standard technique for faking a second Y-axis in a library without native support). Keep
the original, untransformed error points (true percentages) available separately, indexed the
same way (by x / bucket index), so later steps can look up the real value instead of reading the
transformed coordinate.

**Why:** Without preserving the true values separately, anything reading `spot.y` off the
transformed line (most importantly the tooltip) would show the rescaled coordinate instead of
the real percentage — a correctness regression hiding inside a readability fix.

**Sequencing:** Depends on Step 1's ranges. Must complete before Steps 3 and 4.

**Data flow:** Raw `errorPoints` (true %, from the widget's existing input) → transformed
`FlSpot` list (goes into the chart) + retained raw list (used for lookups in Step 4). Only y
values are transformed; x values (bucket index) stay identical between the two lists so they stay
alignable by index or by matching x.

**Edge cases:** None beyond what Step 1 already guards (`errorMaxY` is never zero, so no
divide-by-zero in the transform).

**Design decisions:** None — this step is a mechanical consequence of Step 1's decision.

---

## Step 3 — Dual axis tick labels

**What:** Turn on `leftTitles` (currently `showTitles: false`) to show sparse traffic-count
ticks, and `rightTitles` (also currently off) to show sparse error-percentage ticks. Both use the
existing minimal styling already established elsewhere in this widget and in `ServiceHealthCard`
(`AppTextStyles.monoSm`, `c.textTertiary`) — this is a "Neo-Terminal" minimal-chrome design
language; don't introduce a heavier axis style than what's already used for text elsewhere on
this card. Left-axis tick values come from the traffic range (Step 1); right-axis tick values
come from the error range (Step 1), suffixed with `%`, and must be computed independently from
the *true* error scale — not derived from the transformed plotting coordinates.

**Why:** "Dual-labeled axes" is the actual point of the chosen fix — without visible tick text on
both sides, a viewer still has no way to read either scale's real units except by tapping for a
tooltip.

**Sequencing:** Depends on Step 1 (needs both true ranges). Land after Step 2 to avoid touching
the same render tree twice.

**Edge cases:** Keep tick positions aligned with the existing horizontal gridlines
(`FlGridData.horizontalInterval`, computed from the traffic/host range) — derive right-axis
label positions at the *same fractional heights* as the gridlines/left-axis ticks, rather than
computing an independent, potentially misaligned interval for the error percentage scale. Ticks
should land on the same horizontal lines for both axes.

**Design decisions:** Exact tick count (recommend sparse — e.g. 3, roughly min/mid/max) is a
visual-density judgment call given the chart's compact 160px height and the existing minimal
aesthetic; match whatever reads cleanly at that height rather than a specific number.

---

## Step 4 — Fix the tooltip to read true values

**What:** In `getTooltipItems`, change the error-series branch to look up the true percentage
(from Step 2's retained raw list, matched by the touched spot's x/bucket index) instead of
formatting the touched spot's `y` directly — since that `y` is now the transformed plotting
coordinate, not the real value. The traffic-series branch is unaffected (traffic points were
never transformed, so `spot.y` there is already correct).

**Why:** This is the step that actually prevents Step 2's transform from becoming a silent
correctness regression. Without it, tapping the error line would show the wrong number.

**Sequencing:** Depends on Step 2. Should land in the same change as Step 2 conceptually, but is
listed separately because it's easy to forget once the chart *looks* right — a visually-correct
rescaled line with a wrong tooltip value would be an easy mistake to ship unnoticed.

**Edge cases:** Confirm the legacy single-series code path (`points`/`label`, used by non-dual
call sites, if any remain) is untouched — it only ever had one series and was never part of the
shared-scale bug, so its existing tooltip formatting (`spot.y` directly) should not change.

**Design decisions:** None.

---

## Step 5 — Tests

**What:** Add/extend widget or unit tests covering:
- Traffic-dominant data with a low-but-real error rate → the transformed error line's plotted
  points are visibly above the axis floor (not squashed near zero), confirming Step 1's
  independent scaling actually took effect.
- Tapping an error-series point shows the **true** percentage in the tooltip, not the
  transformed plotting coordinate — this is the regression Step 4 exists to prevent; test it
  directly rather than trusting a visual check.
- An all-zero error series still renders without dividing by zero (the `errorMaxY` floor from
  Step 1 applies).
- Empty traffic with present errors doesn't crash (host axis floor from Step 1 applies).
- The legacy single-series call path (if still exercised anywhere) renders unchanged.

**Why:** The transform-then-reverse-lookup relationship between Steps 2 and 4 is exactly the
kind of logic that regresses silently under a future refactor without a test pinning "tooltip
shows the true value" specifically, independent of "the line is drawn in the right place."

**Sequencing:** Last.

**Design decisions:** None.

---

## LOG.md update instruction

Append to this repo's `log.md` after each step (or as one combined entry if implemented as a
single pass — recent entries in this log have moved to descriptive titles rather than strict
`Phase N, Step M` headers; either format is fine, just make it findable):

```
## Phase 22 — Fix traffic/error chart Y-axis scale
Completed: [timestamp]
Branch/commit: [if applicable]

### What was done
[what was actually implemented — the axis ranges chosen, the transform, the tick styling]

### Key facts for next step
- [the actual floor value used for the error axis, tick count chosen, any judgment calls made]
- [...]

### Deviations from spec
[any places the implementation differed from this spec, and why]

### Status
[DONE / PARTIAL]
```

Paste the entry back to Claude when done.
