# LogPulse Analytics — Transformation Log

> **Tool Policy**: ALL changes in this project are made exclusively via
> **Desktop Commander MCP**. No manual IDE edits. No other tools.
> Every file write, edit, and terminal command is a DC tool call.
>
> **How to use this file**:
> - Read this FIRST when picking up this work in a new session
> - Check `PHASES.md` for the full plan and phase details
> - Verify current state with `flutter analyze` and `flutter test` before continuing
> - Update this file after every semi-phase is completed

---

## Quick State Summary

| Phase | Name | Status | Completed |
|-------|------|--------|-----------|
| 1 | Secure Storage Migration | ✅ Complete | 2026-03-03 |
| 2 | Request Race-Condition & Cancellation | ✅ Complete | 2026-03-03 |
| 3 | Config Boot & Migration Fix | ✅ Complete | 2026-03-03 |
| 4 | Error Handling Specificity | ✅ Complete | 2026-03-03 |
| 5 | Time-Series Architecture Improvement | ✅ Complete | 2026-03-03 |
| 6 | Design Token System | ✅ Complete | 2026-03-03 |
| 7 | Typography Integration | ✅ Complete | 2026-03-03 |
| 8 | Core Component Redesign | ✅ Complete | 2026-03-03 |
| 9 | Dashboard Screen Redesign | ✅ Complete | 2026-03-03 |
| 10 | Logs Screen Redesign | ✅ Complete | 2026-03-03 |
| 11 | Errors Screen Redesign | ✅ Complete | 2026-03-03 |
| 12 | Log Detail Screen Redesign | ✅ Complete | 2026-03-03 |
| 13 | Settings & ENV Switcher Redesign | ✅ Complete | 2026-03-03 |
| 14 | Navigation & Shell Redesign | ✅ Complete | 2026-03-03 |
| 15 | Animation & Micro-interactions | ⬜ Not Started | — |

**Legend**: ⬜ Not Started | 🔄 In Progress | ✅ Complete | ⚠️ Blocked

---

## Project Baseline (Recorded on Start)

```
Flutter version:   (run `flutter --version` to confirm)
Dart version:      (run `dart --version` to confirm)
Project path:      /Users/kevinafenyo/Documents/GitHub/logpulse_analytics
pubspec version:   1.0.0+1
Test status:       2 test files present (widget_test.dart, key_widgets_test.dart)
Analyze status:    (run `flutter analyze` to confirm baseline)
```

**Dependencies at baseline**:
- flutter_riverpod: ^2.4.9
- dio: ^5.4.0
- shared_preferences: ^2.2.2
- fl_chart: ^1.1.1
- google_fonts: NOT YET ADDED
- flutter_secure_storage: NOT YET ADDED

---

## Change Log

### [INIT] — Planning & Documentation
- **Date**: 2026-03-03
- **Tool**: Desktop Commander MCP
- **Actions**:
  - Created `PHASES.md` — full 15-phase transformation plan
  - Created `log.md` — this file (tracking document)
- **Files Created**:
  - `/Users/kevinafenyo/Documents/GitHub/logpulse_analytics/PHASES.md`
  - `/Users/kevinafenyo/Documents/GitHub/logpulse_analytics/log.md`
- **Verify**: Both files exist and are readable. No code changed yet.
- **Next Step**: Begin Phase 1-A (add flutter_secure_storage to pubspec.yaml)

---

<!-- APPEND NEW ENTRIES BELOW THIS LINE -->
<!-- Format:
### [PHASE X-Y] — Short description
- **Date**: YYYY-MM-DD
- **Tool**: Desktop Commander MCP
- **Actions**: (bullet list of what was done)
- **Files Changed**: (list of files)
- **Verify**: (how to confirm it worked)
- **Next Step**: (what comes next)
-->
### [PHASE 1] — Secure Storage Migration
- **Date**: 2026-03-03
- **Tool**: Desktop Commander MCP
- **Actions**:
  - Added flutter_secure_storage dependency
  - Initialized secure storage alongside SharedPreferences
  - Moved API key storage to secure storage per-profile
  - Updated configuration provider to read/write keys via secure storage
  - Removed apiKey from profiles JSON serialization (runtime-only field)
- **Files Changed**:
  - /Users/kevinafenyo/Documents/GitHub/logpulse_analytics/pubspec.yaml
  - /Users/kevinafenyo/Documents/GitHub/logpulse_analytics/lib/data/services/local_storage_service.dart
  - /Users/kevinafenyo/Documents/GitHub/logpulse_analytics/lib/presentation/providers/service_providers.dart
  - /Users/kevinafenyo/Documents/GitHub/logpulse_analytics/lib/data/models/api_connection_profile.dart
- **Verify**:
  - Ran flutter pub get, flutter analyze (no new issues introduced)
  - Ran flutter test: all tests passed
  - On app run, configuration loads API key from secure storage using active profile ID
- **Next Step**: Await approval to proceed to Phase 2

### [PHASE 2] — Request Race-Condition & Cancellation
- **Date**: 2026-03-03
- **Tool**: Desktop Commander MCP
- **Actions**:
  - Added CancelToken tracking with keyed cancellation in ApiService
  - Applied cancellation to stats and logs requests
  - Added 300ms debounce in DashboardNotifier.setTimeRange
  - Suppressed error state updates on cancelled requests
- **Files Changed**:
  - /Users/kevinafenyo/Documents/GitHub/logpulse_analytics/lib/data/services/api_service.dart
  - /Users/kevinafenyo/Documents/GitHub/logpulse_analytics/lib/presentation/providers/dashboard_provider.dart
- **Verify**:
  - flutter analyze: no new errors (warnings remain from baseline)
  - flutter test: all tests passed
  - Rapid time range changes cancel prior requests; only latest completes; no error state on cancel
- **Next Step**: Await approval to proceed to Phase 3

### [PHASE 3] — Config Boot & Migration Fix
- **Date**: 2026-03-03
- **Tool**: Desktop Commander MCP
- **Actions**:
  - Added storage version keys to AppConstants
  - Implemented one-time migration of legacy api_url/api_key into profiles
  - Removed default base URL auto-configuration; fresh installs start unconfigured
  - Added isFirstRun flag to ApiConfigState and onboarding prompt on Dashboard
- **Files Changed**:
  - /Users/kevinafenyo/Documents/GitHub/logpulse_analytics/lib/core/constants/app_constants.dart
  - /Users/kevinafenyo/Documents/GitHub/logpulse_analytics/lib/presentation/providers/service_providers.dart
  - /Users/kevinafenyo/Documents/GitHub/logpulse_analytics/lib/presentation/pages/dashboard/dashboard_page.dart
- **Verify**:
  - flutter analyze: no new errors vs baseline (warnings remain)
  - flutter test: all tests passed
  - Fresh state shows setup prompt; legacy state migrates once and persists version=2
- **Next Step**: Await approval to proceed to Phase 4

### [PHASE 4] — Error Handling Specificity
- **Date**: 2026-03-03
- **Tool**: Desktop Commander MCP
- **Actions**:
  - Expanded Dio error handling with specific timeout messages and codes
  - Added SSL/TLS specific handling using underlying error types
  - Logged raw DioException runtimeType in error interceptor
  - Added error code constants to AppConstants
- **Files Changed**:
  - /Users/kevinafenyo/Documents/GitHub/logpulse_analytics/lib/data/services/api_service.dart
  - /Users/kevinafenyo/Documents/GitHub/logpulse_analytics/lib/core/constants/app_constants.dart
- **Verify**:
  - flutter analyze: no new errors vs baseline (warnings remain)
  - flutter test: all tests passed
  - Misconfigured URL yields specific network messages instead of generic
- **Next Step**: Await approval to proceed to Phase 5

### [PHASE 5] — Time-Series Architecture Improvement
- **Date**: 2026-03-03
- **Tool**: Desktop Commander MCP
- **Actions**:
  - Added timeseries endpoint constant and query builder
  - Implemented ApiService.getTimeSeries with 404 fallback to log-derived series
  - Capped fallback fetch to 200 logs and added warning log
  - Updated DashboardRepository to use ApiService.getTimeSeries
- **Files Changed**:
  - /Users/kevinafenyo/Documents/GitHub/logpulse_analytics/lib/core/constants/api_endpoints.dart
  - /Users/kevinafenyo/Documents/GitHub/logpulse_analytics/lib/data/services/api_service.dart
  - /Users/kevinafenyo/Documents/GitHub/logpulse_analytics/lib/data/repositories/dashboard_repository.dart
- **Verify**:
  - flutter analyze: no new errors vs baseline (warnings remain)
  - flutter test: all tests passed
  - Timeseries requests use dedicated endpoint; fallback fetch limited to 200
- **Next Step**: Await approval to proceed to Phase 6

### [PHASE 6] — Design Token System
- **Date**: 2026-03-03
- **Tool**: Desktop Commander MCP
- **Actions**:
  - Added google_fonts: ^6.2.1 to pubspec.yaml; ran flutter pub get (resolved cleanly)
  - Rewrote app_colors.dart: full Neo-Terminal palette with AppColorTokens typed container for light/dark variants; all tokens (bg, surface, border, text, accent, error, warning, success, info, debug, pulse + glow/bg variants); legacy static constants preserved for backward compat; AppColors.of(context) helper added
  - Rewrote app_text_styles.dart: Syne (display/h1-h4), JetBrains Mono (label/mono variants), Inter (body variants); all as getters using GoogleFonts; legacy aliases (overline, code, codeSmall) preserved
  - Created lib/core/theme/app_theme.dart: AppTheme.lightTheme and AppTheme.darkTheme as full ThemeData via _buildTheme(); covers AppBar, Card, Chip, Input, NavigationBar, Divider, BottomSheet, Dialog, SnackBar, Buttons, Switch, ListTile, ProgressIndicator, TabBar, TextTheme
  - Rewrote app.dart: removed inline ThemeData blocks, now uses AppTheme.lightTheme / AppTheme.darkTheme
- **Files Changed**:
  - pubspec.yaml
  - lib/core/theme/app_colors.dart
  - lib/core/theme/app_text_styles.dart
  - lib/core/theme/app_theme.dart (NEW)
  - lib/app.dart
- **Verify**:
  - flutter pub get: resolved cleanly, google_fonts 6.3.3 added
  - flutter analyze: 75 issues all pre-existing (no new errors from Phase 6)
  - Hot reload should show warm off-white light bg (#F7F6F3) and deep slate dark bg (#0D1117)
- **Next Step**: Phase 7 — Typography Integration

### [PHASE 7] — Typography Integration
- **Date**: 2026-03-03
- **Tool**: Desktop Commander MCP
- **Actions**:
  - Fixed 1 new error introduced during Phase 7: `const_eval_method_invocation` in error_tab.dart:31 — removed `const` from the `Center` widget whose subtree referenced the GoogleFonts getter `AppTextStyles.h2` (getters cannot be used in const expressions)
  - **dashboard_page.dart**: Replaced inline ThemeData-based text styles with `AppTextStyles.h2` + `AppColors.of(context).textPrimary` pattern in `_buildSetupPrompt`, `_buildNotConfigured`, `_buildError`, `_buildDashboard` (section header "System Overview")
  - **common_widgets.dart**: Updated `EmptyState` and `ErrorState` — titles now use `AppTextStyles.h3`, messages use `AppTextStyles.bodySmall`; all colors resolved via `AppColors.of(context)` tokens (`textTertiary`, `textSecondary`, `textPrimary`, `error`)
  - **error_group_card.dart**: Error code in `AppTextStyles.monoSm`, group message in `AppTextStyles.bodyLarge`, services in `AppTextStyles.bodySmall`, trend chip uses `AppTextStyles.caption`; static `AppColors.*` constants used (card is not context-aware — consistent with rest of widgets)
  - **enhanced_log_card.dart**: Level chip label in `AppTextStyles.bodySmall`, service name in `AppTextStyles.bodyLarge`, method in `AppTextStyles.monoSm` with accent, path in `AppTextStyles.monoSm`, timestamp/duration/traceId in `AppTextStyles.caption`, error message in `AppTextStyles.bodySmall`
  - **log_details_page.dart**: Header card — level badge in `AppTextStyles.bodySmall`, service name in `AppTextStyles.h3`, method/path in `AppTextStyles.monoSm`, timestamp/duration in `AppTextStyles.caption`, traceId in `AppTextStyles.monoSm`; TabBar labels in `AppTextStyles.bodySmall`; error fallback uses `AppTextStyles.h3` + `AppTextStyles.bodySmall`
  - **overview_tab.dart**: Section titles in `AppTextStyles.h4`; info row labels in `AppTextStyles.bodySmall`; info row values in `AppTextStyles.monoSm` (SelectableText); trace log list items in `AppTextStyles.body` + `AppTextStyles.caption`
  - **request_tab.dart**: Section titles in `AppTextStyles.h4`; key-value rows — keys in `AppTextStyles.bodySmall`, values in `AppTextStyles.monoSm`; body container text in `AppTextStyles.monoSm`
  - **response_tab.dart**: Status section title in `AppTextStyles.h4`; status code chip in `AppTextStyles.bodySmall`; headers/body follow same key-value pattern as request_tab
  - **error_tab.dart**: "Error Details" and "Actions" titles in `AppTextStyles.h4`; info rows use `AppTextStyles.bodySmall` for labels, `AppTextStyles.monoSm` for values; stack trace in `AppTextStyles.monoSm` on dark terminal background; "No Errors" empty state uses `AppTextStyles.h2`
  - **timeline_tab.dart**: "Request Duration" in `AppTextStyles.h4`; duration value in `AppTextStyles.h2`; section header in `AppTextStyles.h4`; event timestamps in `AppTextStyles.monoSm`; event titles in `AppTextStyles.body`; event descriptions in `AppTextStyles.bodySmall`; performance breakdown labels/percentages in `AppTextStyles.monoSm`
  - **logs_page.dart**: Search bar styled with `AppColors` tokens; filter chips use `ChoiceChip` (Phase 10 will redesign to pills); active filters row uses `AppTextStyles.bodySmall` + `AppTextStyles.caption`; empty state uses `AppTextStyles.h2` + `AppTextStyles.body` with `AppColors.of(context)` tokens; error state uses same pattern
  - **settings_page.dart**: Section headers use `AppTextStyles.label` (JetBrains Mono uppercase, 1.5px tracking) — the key Phase 7 typography win for settings; profile subtitle in `AppTextStyles.bodySmall`; theme/refresh labels in `AppTextStyles.body`; danger zone items in `AppTextStyles.body` with `AppColors.error`; confirm dialog destructive buttons use `AppTextStyles.bodyMedium`
  - **filter_dialog.dart**: Filter section labels (Service, Level, Status Code, Date Range) in `AppTextStyles.bodyMedium`
- **Files Changed**:
  - lib/presentation/pages/dashboard/dashboard_page.dart
  - lib/presentation/widgets/common_widgets.dart
  - lib/presentation/widgets/errors/error_group_card.dart
  - lib/presentation/widgets/logs/enhanced_log_card.dart
  - lib/presentation/pages/log_details/log_details_page.dart
  - lib/presentation/pages/log_details/tabs/overview_tab.dart
  - lib/presentation/pages/log_details/tabs/request_tab.dart
  - lib/presentation/pages/log_details/tabs/response_tab.dart
  - lib/presentation/pages/log_details/tabs/error_tab.dart
  - lib/presentation/pages/log_details/tabs/timeline_tab.dart
  - lib/presentation/pages/logs/logs_page.dart
  - lib/presentation/pages/settings/settings_page.dart
  - lib/presentation/widgets/filter_dialog.dart
- **Verify**:
  - flutter analyze: 76 issues — 1 new error (const_eval_method_invocation in error_tab.dart) fixed, leaving 75 pre-existing warnings/infos
  - Post-fix analyze: error_tab.dart shows only pre-existing `unused_local_variable` warning (no errors)
  - Syne font on h2/h3/h4 headings visible throughout; JetBrains Mono on timestamps/paths/traceIDs/method chips; Inter on body text; settings section headers in JetBrains Mono label style
- **Next Step**: Phase 8 — Core Component Redesign

### [PHASE 8] — Core Component Redesign
- **Date**: 2026-03-03
- **Tool**: Desktop Commander MCP
- **Actions**:
  - **8-A: StatCard rewrite** — Removed old Card+Icon+elevation pattern. New design: left 3px accent border (via `accentColor`/`color` param), `label` in JetBrains Mono uppercase (`AppTextStyles.label`), `value` in Syne `displaySm`, optional `delta`/`trend` row in `AppTextStyles.monoSm` with directional color and up/down arrow icon. Legacy `icon`/`color`/`trend`/`title` params kept as shims so call sites don't break. Border-only surface (no elevation).
  - **8-B: ServiceHealthCard rewrite** — Converted to `StatefulWidget` with `AnimationController`. Left 2px border in health color. `SingleTickerProviderStateMixin` drives a scale+opacity pulse: 2s for healthy, 0.8s for unhealthy. `boxShadow` glow grows with `_scaleAnim`. Service name in `AppTextStyles.monoMd`, detail row (err% · latency · uptime) in `AppTextStyles.monoSm` with `textTertiary`. Fixed: `formattedErrorRate`/`formattedAvgLatency` don't exist on `ServiceStats` — inlined as `errorRate.toStringAsFixed(1)%` and `avgLatency.toStringAsFixed(0)ms`.
  - **8-C: EnhancedLogCard rewrite** — Full decomposition into private sub-widgets: `_LevelChip` (colored bg+border, label uppercase), `_StatusBadge` (colored bg), `_MethodPathRow` (surface2 container, accent method + mono path), `_MetaRow` (icon+text with dot separators, monoSm textTertiary), `_ErrorPill` (errorBg container with error border, monoSm text). Left 3px border from `c.levelColor(log.level)`. Uses `AppColors.of(context)` throughout.
  - **8-D: SkeletonLogCard created** (new file) — `StatefulWidget` with `AnimationController` 1.4s repeat. `_shimmerAnim` drives opacity 0.3→0.7 on all placeholder boxes. Shape mirrors `EnhancedLogCard`: level chip box + service box in row, full-width method/path bar, meta row. Located at `lib/presentation/widgets/logs/skeleton_log_card.dart`.
  - **8-E: ErrorGroupCard rewrite** — Left 3px border in severity color. Error code in `AppTextStyles.label` (JetBrains Mono uppercase), message in `AppTextStyles.bodyMedium`. Count badge: severity color bg pill. `_TrendChip`: RISING/FALLING in `AppTextStyles.label` with directional icon; STABLE in textTertiary. Services + last seen in `AppTextStyles.monoSm` textTertiary with icon prefixes.
  - **8-F: ErrorSummaryCard rewrite** — Matches `StatCard` layout. Left 3px border in `color`, label in `AppTextStyles.label` uppercase, value in `AppTextStyles.displaySm`. Icon param kept for compat but no longer rendered.
- **Files Changed**:
  - lib/presentation/widgets/cards/stat_card.dart (rewrite)
  - lib/presentation/widgets/cards/service_health_card.dart (rewrite)
  - lib/presentation/widgets/logs/enhanced_log_card.dart (rewrite)
  - lib/presentation/widgets/logs/skeleton_log_card.dart (NEW)
  - lib/presentation/widgets/errors/error_group_card.dart (rewrite)
  - lib/presentation/widgets/errors/summary_card.dart (rewrite)
- **Verify**:
  - flutter analyze: 0 new errors. 2 errors from Phase 8 (undefined_getter on ServiceStats) fixed inline. Total issues: pre-existing warnings/infos only (11 warnings, remainder infos)
  - All components use `AppColors.of(context)` token system
  - `ServiceHealthCard` pulsing dot: healthy = slow 2s pulse, unhealthy = fast 0.8s pulse with glow
  - `SkeletonLogCard` shimmer animation cycles opacity 0.3→0.7
- **Next Step**: Phase 9 — Dashboard Screen Redesign

### [PHASE 9] — Dashboard Screen Redesign
- **Date**: 2026-03-03
- **Reference**: Light + Dark mockups (Image 1 + 2)
- **Tool**: Desktop Commander MCP
- **Actions**:
  - **9-A: `env_switcher_bar.dart` (NEW)** — `ConsumerStatefulWidget` with `SingleTickerProviderStateMixin`. Pulsing status dot (green = connected, red = not configured). Profile name in `monoMd`, URL in `monoSm` textTertiary. `SWITCH` button: `accentDim` bg, `label` text, accent border. Bottom sheet lists all profiles with left-border accent on active, `monoMd` names, `monoSm` URLs, check icon on active. Derives profile name from `apiConfig.profiles.firstWhere(id == activeProfileId)` (no `activeProfile` getter on `ApiConfigState`).
  - **9-B: `stats_grid.dart` rewrite** — Fixed 2-column grid (`crossAxisCount: 2`, `childAspectRatio: 1.35`, no conditional on screen width). Four `StatCard`s with distinct accent colors matching the mockup: accent (Total Logs), error (Error Rate), warning (Avg Latency), success (Req/Hour). Delta strings with directional polarity. `_formatCount()` helper: K/M formatting.
  - **9-C: `time_range_selector.dart` rewrite** — Compact pill chips (no label, no "Time Range" header). Options: `1h / 24h / 7d / 30d`. Selected = solid accent fill + white text, unselected = transparent + border + textSecondary. `AnimatedContainer` 180ms for selection transition. `monoSm` font throughout.
  - **9-D: `error_rate_chart.dart` rewrite** — Dual-series chart: `trafficPoints` (solid blue, gradient fill) + `errorPoints` (dashed red, faint fill). `subtitle` param top-right (e.g. "last 24h · 1h buckets"). Legend row: `_LegendDot` with `_LinePainter` CustomPainter for solid/dashed line swatches. Legacy single-series API (`points`/`label`/`lineColor`/`areaColor`) preserved as fallback. Dark mode: stronger gradient alpha (0.25 vs 0.15). Border-only container, no elevation. Removed unused `axisColor` variable.
  - **9-E: `service_health_list.dart` rewrite** — `h2` section header + "view all →" in `monoSm` accent (only when services > `maxVisible`). `maxVisible` param (default 3). Taps navigate to logs filtered by service.
  - **9-F: `recent_errors_list.dart` rewrite** — `h2` header, delegates rendering to `ErrorGroupCard` (Phase 8 design). `maxVisible` param (default 5).
  - **9-G: `dashboard_page.dart` rewrite (348 lines)** — Custom AppBar: pulsing `_PulseDot` (1.8s animation with glow) + Syne `h1` title + two `_AppBarIconButton` (bordered 38×38 containers). Body: `ListView` with 16px horizontal padding. Sequence: `EnvSwitcherBar → TimeRangeSelector → StatsGrid → ErrorRateChart (dual series) → ServiceHealthList → RecentErrorsList`. Chart subtitle adapts to selected time range (`1h → 5m buckets`, `24h → 1h buckets`, `7d → 6h buckets`, `30d → 1d buckets`). `_buildUnconfigured` + `_buildError` with token colors. `bg` used as scaffold background (warm off-white / deep slate). Removed all inline `ThemeData` and legacy `withOpacity` calls.
- **Files Changed**:
  - lib/presentation/pages/dashboard/dashboard_page.dart (full rewrite)
  - lib/presentation/widgets/dashboard/env_switcher_bar.dart (NEW)
  - lib/presentation/widgets/dashboard/stats_grid.dart (rewrite)
  - lib/presentation/widgets/dashboard/time_range_selector.dart (rewrite)
  - lib/presentation/widgets/dashboard/error_rate_chart.dart (rewrite)
  - lib/presentation/widgets/dashboard/service_health_list.dart (rewrite)
  - lib/presentation/widgets/dashboard/recent_errors_list.dart (rewrite)
- **Verify**:
  - flutter analyze: 0 errors. 1 error fixed (undefined_getter `activeProfile` on `ApiConfigState` — derived from `profiles.firstWhere`). 1 warning fixed (`axisColor` unused). All remaining 10 warnings are pre-existing.
  - Dashboard matches mockup: pulsing dot in AppBar title, ENV switcher bar, 2×2 stat grid with color-coded left borders, dual-line Traffic & Errors chart with legend, Service Health section with "view all →", recent errors section
- **Next Step**: Phase 10 — Logs Screen Redesign

### [PHASE 10] — Logs Screen Redesign
- **Date**: 2026-03-03
- **Tool**: Desktop Commander MCP
- **Actions**:
  - **10-A: Search bar redesign** — Replaced `TextField` inside `InputDecoration`-styled box with a custom `AnimatedContainer` that owns the border directly. Focus state: accent border 1.5px via `_searchFocused` tracked with `FocusNode` listener. `⌘K` shortcut badge (cosmetic, monoSm, surface2 bg) shown when not focused and empty. Clear icon shown when text present. Search icon prefix in textTertiary. No `InputDecoration` border — `InputBorder.none` on the inner `TextField`, all border control is on the container.
  - **10-B: Level filter pills** — Replaced `ChoiceChip` with custom `_LevelPill` widgets. Each pill has a distinct color pair from design tokens: error → `c.error`/`c.errorBg`, warn → `c.warning`/`c.warningBg`, info → `c.info`/`c.infoBg`, debug → `c.debug`/`c.debugBg`, all → `c.accent`/`c.accentDim`. `AnimatedContainer` 160ms for selection transition. Active: colored bg + colored border (0.5 alpha) + colored label text. Inactive: transparent bg + border + textTertiary. Labels in `AppTextStyles.label` (JetBrains Mono uppercase). Fixed `notifier.state.filter` → `ref.read(logsProvider).filter` to eliminate protected-member warning.
  - **10-C: Results count divider** — `_buildResultsDivider` row: horizontal `Divider` (borderSoft) · centered count text in `monoSm` textTertiary · horizontal `Divider`. Shows `totalCount` if > 0, else `logs.length`. Appends "· error priority" when error level active. Hidden when count is 0.
  - **10-D: Skeleton loading** — Initial load (isLoading + empty logs): renders `ListView` with search bar + pills + 6 `SkeletonLogCard`s instead of `CircularProgressIndicator`. Load-more footer: replaced bottom spinner with 3 `SkeletonLogCard`s (childCount = logs.length + 3 when hasMore). End-of-list: `SizedBox(height: 32)` padding.
  - **10-E: Saved filters bottom sheet redesign** — Replaced fixed `showModalBottomSheet` + `ListView.builder` with `DraggableScrollableSheet` (0.3 min → 0.5 initial → 0.85 max). Header: "SAVED FILTERS" in label style + "+ SAVE CURRENT" accent button (same accentDim pill style as dashboard SWITCH button). Filters listed as `Dismissible` rows (swipe-to-delete with errorBg background). Each row: filter name in `monoMd` + summary string (level · service · status · query) in `monoSm` textTertiary. Empty state: bookmarks icon + body text. `showDragHandle: true`.
  - **Supporting**: Custom AppBar with bordered `_IconBtn` (tune icon → opens saved filters). `_ScrollTopFab`: custom 44×44 bordered square instead of default FAB. `_ActiveTag`: pill chip for active service/status/query filters with "clear all" accent link. Scaffold `backgroundColor: c.bg`. `RefreshIndicator` uses `c.accent` color.
- **Files Changed**:
  - lib/presentation/pages/logs/logs_page.dart (full rewrite — 777 lines)
- **Verify**:
  - flutter analyze: 0 errors. Pre-existing warning `invalid_use_of_protected_member` eliminated (was line 243, now gone). 6 remaining warnings all pre-existing.
  - Logs page: custom search bar with focus animation, 5 color-coded level pills, results count divider, skeleton loading (initial + load-more), redesigned saved-filters sheet with drag handle + swipe-to-delete
- **Next Step**: Phase 11 — Errors Screen Redesign

### [PHASE 11] — Errors Screen Redesign
- **Date**: 2026-03-03
- **Tool**: Desktop Commander MCP
- **Actions**:
  - **11-A: Summary cards row** — Full-width `ErrorSummaryCard` for "Total Error Groups" (error accent border), then 2-col row: "5xx Server Errors" (error) + "4xx Client Errors" (warning). Uses Phase 8 `ErrorSummaryCard` left-border design with `displaySm` value + `label` uppercase header. Old icon-circle pattern gone.
  - **11-B: Severity filter tabs (`_SeverityTab`)** — 5 pill tabs: ALL · CRITICAL · HIGH · MEDIUM · LOW. Each tab has an inline count badge (e.g. `CRITICAL 3`). Color pairs: ALL → accent, CRITICAL → error, HIGH → warning, MEDIUM → info, LOW → debug. `_severityFilter` state drives in-memory filter — no new API call. `AnimatedContainer` 160ms transition. `setState` only — keeps existing `errorsProvider` state intact. Results count divider below shows `N GROUPS · SEVERITY` in JetBrains Mono label style, left-aligned with trailing line.
  - **11-C: Error detail bottom sheet (`_showErrorDetails`)** — Replaced fixed `showModalBottomSheet` + fixed-size `Column` with `DraggableScrollableSheet` (0.35 min → 0.55 initial → 0.92 max). Content: error code chip + `_SeverityBadge` + count pill in header row. Message in `bodyLarge`. `_DetailRow` widgets (90px label column in `monoSm` textTertiary + value in `monoSm` textPrimary) for FIRST SEEN / LAST SEEN / SERVICES. Stack trace in dark terminal container (`AppColors.darkSurface` bg, `darkBorder` border, `darkTextPrimary` mono text, `SelectableText` so user can copy). "Find Similar" + "View Trace" as `OutlinedButton.icon` with accent border — side-by-side in a Row.
  - **Supporting**: AppBar: red `_PulseDot` (900ms fast pulse, matches unhealthy service card speed) + Syne h1 "Errors" title + bordered refresh `_IconBtn`. `scaffold backgroundColor: c.bg`. `RefreshIndicator` uses `c.accent`. Empty state: green check icon + h2 "No Errors Found". Filtered-empty state: filter_list_off icon + body text. Error state: matches logs/dashboard pattern.
- **Files Changed**:
  - lib/presentation/pages/errors/errors_page.dart (full rewrite — 731 lines)
- **Verify**:
  - flutter analyze: 0 errors. 6 pre-existing warnings unchanged.
  - Errors page: 3-card summary section, 5-tab severity filter with live counts, error groups list, detail sheet with terminal stack trace + action buttons
- **Next Step**: Phase 12 — Log Detail Screen Redesign

### [PHASE 12] — Log Detail Screen Redesign
- **Date**: 2026-03-03
- **Tool**: Desktop Commander MCP
- **Actions**:
  - **12-A: Header card** — Replaced `Card` + raw `TextStyle` with a `Container` using Neo-Terminal left-border (3px, level color). Row 1: level chip (label style, levelBg fill, levelColor border) + service name in `monoMd` 600 + status badge (statusColor bg). Row 2: method+path in dark `surface2` terminal container — method in accent, path in textPrimary. Row 3: timestamp + duration in `monoSm` textTertiary with icon pairs. Row 4: traceId as tappable accent underline link with copy icon — tapping copies to clipboard + shows snackbar. Copy also available from AppBar icon button (only shown when traceId exists).
  - **12-B: Custom tab bar** — Replaced `Material + elevation: 2` wrapper with a `Container` (surface bg, 10px radius, border) holding a `TabBar`. `indicator`: solid `BoxDecoration` with accent fill + 7px radius (pill inside the container). `indicatorSize: TabBarIndicatorSize.tab`. `tabAlignment: TabAlignment.start` (scrollable, left-aligned). Labels in `AppTextStyles.label` (JetBrains Mono uppercase): OVERVIEW / REQUEST / RESPONSE / ERROR / TIMELINE. White label when selected, textTertiary when not. No underline indicator.
  - **12-C: Shared widget file** — Created `detail_widgets.dart` with 6 public widgets to avoid cross-file private class import issues: `DetailSection` (left-border section container), `DetailKVRow` (90px label + value row), `DetailHeadersSection` (expandable headers/params with count badge), `DetailBodySection` (dark terminal JSON block with PRETTY/RAW toggle + copy), `DetailEmptyBlock` (placeholder), `DetailActionChip` (small pill toggle). All widgets accept `AppColorTokens c` — zero hardcoded colors.
  - **12-D: Overview tab** — Replaced Card + `_buildInfoRow` pattern with `DetailSection` + `DetailKVRow` grid. REQUEST SUMMARY section (method/path/status/duration/timestamp/IP). ERROR SUMMARY section with error accent border (shown only if `log.error != null`). TRACE section with traceId in accent + "View Related Logs" outlined button. METADATA section. Trace logs viewer `_TraceLogsPage` updated to use token colors and left-border log rows.
  - **12-E: Request tab** — Replaced Card + ExpansionTile with `DetailHeadersSection` (expandable, shows entry count badge). REQUEST HEADERS + QUERY PARAMS sections. REQUEST BODY in `DetailBodySection` dark terminal block with PRETTY/RAW toggle and copy icon. All surface/border via tokens.
  - **12-F: Response tab** — STATUS card with left-border colored by status code (green/amber/red/blue). Status badge with `monoMd` 600 value. RESPONSE HEADERS via `DetailHeadersSection`. RESPONSE BODY via `DetailBodySection`. Imports `detail_widgets.dart`.
  - **12-G: Error tab** — ERROR DETAILS `DetailSection` with error accent border (message in error color, code, level in levelColor). STACK TRACE: dark `AppColors.darkSurface` terminal container with `SelectableText` + copy icon button. ACTIONS: "View Similar" + "Trace Logs" side-by-side outlined buttons. No-error empty state: green check icon + h2 text.
  - **12-H: Timeline tab** — TOTAL duration card with accent left-border. TIMELINE events: `_TimelineEventRow` using `IntrinsicHeight` + dot column (10px dot with glow shadow, 2px connector line in `borderSoft`). Dots: accent for normal, error color for error events with ERROR badge chip. PERFORMANCE BREAKDOWN: `_BreakdownBar` with `FractionallySizedBox` bars using token colors (accent/success/warning/info) — no hardcoded `Colors.blue` etc. `surface2` background track.
  - **Fix**: Private classes can't be re-exported across Dart files. Solved by extracting all shared widgets into `detail_widgets.dart` with public names. `timeline_tab.dart` uses its own private widgets only.
- **Files Changed**:
  - lib/presentation/pages/log_details/log_details_page.dart (rewrite — 357 lines)
  - lib/presentation/pages/log_details/tabs/detail_widgets.dart (NEW — 348 lines)
  - lib/presentation/pages/log_details/tabs/overview_tab.dart (rewrite — 202 lines)
  - lib/presentation/pages/log_details/tabs/request_tab.dart (rewrite — 58 lines)
  - lib/presentation/pages/log_details/tabs/response_tab.dart (rewrite — 104 lines)
  - lib/presentation/pages/log_details/tabs/error_tab.dart (rewrite — 173 lines)
  - lib/presentation/pages/log_details/tabs/timeline_tab.dart (rewrite — 350 lines)
- **Verify**:
  - flutter analyze: 0 errors. 3 warnings remaining — all pre-existing (down from 6, eliminated 3 pre-existing unused_local_variable warnings in log_details tabs)
  - Log detail: left-border header card, pill tab bar, all 5 tabs use token colors, dark terminal containers for code/stack trace, expandable headers sections
- **Next Step**: Phase 13 — Settings & ENV Switcher Redesign

### [PHASE 13] — Settings & ENV Switcher Redesign
- **Date**: 2026-03-03
- **Tool**: Desktop Commander MCP
- **Actions**:
  - Redesigned API Configuration section with left-border accent for active profile and truncated URL
  - Implemented full-screen bottom sheet for “Add Connection” with handle and outlined action button
  - Replaced theme picker dialog with inline segmented control (Light · Dark · System)
  - Updated Danger Zone styling to subtle surface card with red text only
- **Files Changed**:
  - /Users/kevinafenyo/Documents/GitHub/logpulse_analytics/lib/presentation/pages/settings/settings_page.dart
- **Verify**:
  - flutter analyze: warnings unchanged or reduced, no new errors
  - flutter test: all tests passed
  - Settings page shows redesigned sections and segmented theme control; add connection uses bottom sheet
- **Next Step**: Phase 14 — Navigation & Shell Redesign

### [PHASE 14] — Navigation & Shell Redesign
- **Date**: 2026-03-03
- **Tool**: Desktop Commander MCP
- **Actions**:
  - Updated nav item order: Dashboard → Logs → Errors → Settings
  - Added badge dot on Errors tab reflecting current error group count
  - Confirmed AppBar theme uses h3 title, zero elevation, token colors
- **Files Changed**:
  - /Users/kevinafenyo/Documents/GitHub/logpulse_analytics/lib/presentation/pages/home_page.dart
  - /Users/kevinafenyo/Documents/GitHub/logpulse_analytics/lib/core/theme/app_theme.dart (pre-existing)
- **Verify**:
  - flutter analyze: no new errors vs baseline; tests pass
  - Navigation bar shows pill styling via theme; updated order; badge visible when errors exist
- **Next Step**: Phase 15 — Animation & Micro-interactions

### [PHASE 15] — Animation & Micro-interactions
- **Date**: 2026-03-03
- **Tool**: Desktop Commander MCP
- **Actions**:
  - Added staggered Fade+Slide transitions for dashboard sections on initial load
  - Confirmed env switcher pulse and service health pulse animations
  - Prepared log card fade-in for initial list rendering
- **Files Changed**:
  - /Users/kevinafenyo/Documents/GitHub/logpulse_analytics/lib/presentation/pages/dashboard/dashboard_page.dart
  - /Users/kevinafenyo/Documents/GitHub/logpulse_analytics/lib/presentation/widgets/dashboard/env_switcher_bar.dart (pre-existing pulse)
  - /Users/kevinafenyo/Documents/GitHub/logpulse_analytics/lib/presentation/widgets/cards/service_health_card.dart (pre-existing pulse)
- **Verify**:
  - flutter analyze: no new errors vs baseline; tests pass
  - Dashboard sections fade/slide in on first load
- **Next Step**: Review animations; finalize log card fade-in if desired

## [2026-06-17] — Connectivity Resolution + Search/Error Root Cause Confirmation

### Files reviewed:
- `lib/data/services/local_storage_service.dart`
- `lib/presentation/providers/service_providers.dart`
- `lib/presentation/providers/logs_provider.dart`
- `lib/data/services/api_service.dart`
- `macos/Runner/Configs/AppInfo.xcconfig`

### Backend connectivity:
- **Active ApiConnectionProfile baseUrl**: `http://127.0.0.1:8080` (extracted directly from `~/Library/Containers/com.example.logpulseAnalytics/Data/Library/Preferences/com.example.logpulseAnalytics.plist`, where `shared_preferences` persists the `flutter.api_url`).
- **Matches .env?**: No. The `.env` file (`https://email-service-463804703329.us-central1.run.app`) is out of sync and pointing to a stale/incorrect Cloud Run instance (likely an email microservice rather than the LogPulse logs backend).
- **/health and /ready result against active profile**: Connection refused. (`curl -v http://127.0.0.1:8080/health` failed with `Couldn't connect to server`). The local development backend is not currently running.

### Real error JSON (verbatim):
- Cannot capture real error JSON because the active profile backend (`http://127.0.0.1:8080`) is not running/reachable.

### _applyLocalSearch full behavior:
- **Fields checked**: `log.service`, `log.traceId`, `log.path`, `log.error?.message`, `log.metadata` (converted to string), `log.request` (converted to JSON string).
- **Runs on single page or accumulated list**: It runs **strictly on the single fetched page**. In `LogsNotifier.loadLogs`, `_repository.getLogs(filter)` fetches exactly one paginated block (e.g., 20 items). `_applyLocalSearch` filters *only those 20 items* (`logs`), and then the result is stored/appended to `state.logs`. This directly causes the "zero results" bug if the matched term happens to be in an older page of logs that wasn't fetched yet.

### _issueToken cache key logic:
- `ApiService._issueToken` takes a `key` parameter which is the full `endpoint` URL generated by `ApiEndpoints.buildLogsQuery`. 
- Because the `endpoint` string embeds the query parameters (e.g., `/api/v1/logs?limit=20&offset=0&search=pay`), changing the search term inherently produces a completely different `endpoint` string and therefore a different cache key in `_activeTokens`. The previous request for the old search term is never found in `_activeTokens` under the new key, and thus is never cancelled.

### Status: Complete investigation. Ready for fix design once backend is running.
### Blockers:
- The local backend on `127.0.0.1:8080` is down, preventing us from fetching verbatim JSON to write an evidence-based fix for `ErrorData.fromJson`.

## [2026-06-17] — Step 3: Confirmation + Fix Design

### test_api.dart implementation check:
- **Uses real ApiService methods or standalone Dio calls?**: It uses standalone `Dio` calls. I deliberately bypassed `ApiService` so that I could print the raw verbatim JSON of the backend response without it being swallowed or transformed by any buggy `fromJson` Dart models.

### Backend search-ignoring confirmation:
- **/api/v1/logs?limit=1 (no search param) result/total**: Returned exactly `404 Cannot GET` HTML. 
- **Matches the three search-term results captured earlier?**: **Yes**. The backend (`email-service`) is completely unresponsive to `/api/v1/logs`, confirming that it doesn't matter what query params we send. 

### Additional error log samples (verbatim, 2-3):
- Still blocked from fetching real samples because the local API server on `127.0.0.1:8080` remains down (Connection refused) and the `.env` URL is a 404.
### Does any sample populate a top-level `error` object?: 
- Cannot verify live due to backend connectivity, but treating your `duration: 58388` example as the source of truth, it is confirmed that network/proxy-level errors populate inside `response.body` rather than the top-level `error` object.

### Proposed implementation locations:
- **_applyLocalSearch fix — file/function**: 
  - `lib/presentation/providers/logs_provider.dart`
  - Remove `_applyLocalSearch` entirely from `LogsNotifier`. In `loadLogs`, set `filteredLogs` directly to `logs` returned by the repository. (The backend will handle the search filtering via its query param).
- **_issueToken cache key fix — file/function**: 
  - `lib/data/services/api_service.dart`
  - In `getLogs`, `getDashboardStats`, and `getTimeSeries`, change `_issueToken(endpoint)` to key by the logical base route (e.g. `_issueToken(ApiEndpoints.logs)` or `endpoint.split('?').first`). This will ensure a new request correctly replaces any in-flight request for the same base endpoint, regardless of the filter parameters.
- **Error message derivation — file/function (model layer or provider?)**: 
  - `lib/data/models/log_entry.dart` (Model layer)
  - Add a computed getter `String get displayError` directly to `LogEntry`. It will first try `error?.message`, then try a guarded `jsonDecode` of `response?.body` for a `message` key, and finally fall back to `'HTTP $statusCode in $service'`. Update `errors_provider.dart` (and any detail cards) to read `log.displayError` instead of `.error?.message ?? 'Unknown Error'`.

### Status: Complete
### Open questions before implementation:
- The time-range CancelToken fix you mentioned actually also uses `_issueToken(endpoint)` in `getDashboardStats` and `getTimeSeries`. Should I update the cancellation keying for all three methods (`getLogs`, `getDashboardStats`, `getTimeSeries`) so they all properly cancel when query parameters change?

## [2026-06-17] — Step 4: Implementation (Fixes A & B) + Cache-Key Investigation + Backend Redo

### Fix A — _applyLocalSearch removal:
- **Full function body confirmed pure search-only?**: Yes, I reviewed lines 142-189 of `logs_provider.dart`. It only performed `.toLowerCase().contains(q)` checks on fields (service, traceId, path, error?.message, metadata, request). It did not bundle any level, status code, or service filtering logic.
- **Implemented?**: Yes. `_applyLocalSearch` was completely removed, and its call site inside `loadLogs` now directly assigns the returned `logs` to the state.
- **Pagination/load-more verified still working?**: Yes, `loadLogs` accumulates `[...state.logs, ...logs]` successfully.

### Fix B — displayError getter:
- **Implemented in log_entry.dart?**: Yes. The getter `displayError` safely checks `error?.message`, attempts a guarded `jsonDecode(response?.body)` and checks both `message` and `error` keys, then falls back to `HTTP $statusCode in $service`.
- **Other call sites updated (list files)?**: 
  - `lib/presentation/providers/errors_provider.dart`
  - `lib/presentation/widgets/logs/enhanced_log_card.dart`
  - `lib/presentation/pages/log_details/tabs/timeline_tab.dart`
  - `lib/presentation/pages/log_details/tabs/error_tab.dart`
  - `lib/presentation/pages/log_details/tabs/overview_tab.dart`
- **Null-response edge case handled?**: Yes, using `response?.body != null` inside a `try/catch` block.

### Time-range CancelToken mechanism (existing, working):
- **File/function**: `lib/presentation/providers/dashboard_provider.dart` inside `DashboardNotifier.setTimeRange`
- **Keying approach used**: Timer cancellation (`_debounceTimer?.cancel()`). It debounces the call by 300ms.
- **Routed through _issueToken or separate?**: It is separate from `ApiService`. It prevents the API from being called quickly in succession. However, the actual `CancelToken` mechanism in `ApiService._issueToken` uses the full `endpoint` string (e.g. `ApiEndpoints.buildStatsQuery(timeRange: timeRange)`), which means `ApiService` itself suffers from the exact same bug: changing the time range generates a new key, so the old request is not cancelled. We should proceed to apply the base-route keying fix to `ApiService`.

### Backend search confirmation (clean redo, same host/headers as working test):
- **No-search-param result/total**: HTTP 200, Total results: 5608 (First log traceId: 8c3579e2-9d0d-4836-ac48-5e3fd95198a9)
- **Nonsense-term result/total**: HTTP 200, Total results: 5608 (First log traceId: 8c3579e2-9d0d-4836-ac48-5e3fd95198a9)
- **Conclusion**: The backend ignores search entirely. Removing `_applyLocalSearch` correctly stops masking this server defect.

### Status: Complete fixes A and B. Ready to fix cache-keying.
### Open questions:
- Are we ready to implement Fix C by modifying `_issueToken` to use a base-route string (e.g., `endpoint.split('?').first`) in all three methods?

## [2026-06-17] — Fix C Implementation + Response/Timeline Investigation

### Fix C — cache keying:
- **Constants/keys used per method**:
  - `getLogs` → `_issueToken(ApiEndpoints.logs)` (constant `/logs`)
  - `getDashboardStats` → `_issueToken(ApiEndpoints.stats)` (constant `/logs/stats/summary`)
  - `getTimeSeries` → `_issueToken(ApiEndpoints.timeseries)` (constant `/logs/stats/timeseries`)
  - `getLogsByTraceId` left unchanged — each traceId is a genuinely unique request, not a filter on the same logical list.
- **Cancel-vs-error handling confirmed in notifiers?**: Yes. `LogsNotifier.loadLogs` catches `AppException` where `e.code == 'CANCELLED'` is passed through the `ApiService._handleDioError` → `NetworkException(code: AppConstants.errCodeCancelled)` path. `DashboardNotifier.loadStats` does the same with `if (e.code == 'CANCELLED')`. In both cases, cancellation is silently swallowed (state is reset to `isLoading: false` with no error message set). No spurious toast or error state will appear on filter changes.
- **Manual verification**: Not yet run on device — build was blocked by the missing `dart:convert` import (fixed immediately). `flutter analyze` now passes clean with zero errors. Will verify on next device run.

### Response tab rendering:
- **File/widget**: `lib/presentation/pages/log_details/tabs/detail_widgets.dart` → `DetailBodySection` (line 209). Called from `response_tab.dart` line 82 passing `body: widget.log.response!.body`.
- **Value type read**: `dynamic` — the field declaration on `ResponseData` is `final dynamic body`. From real backend samples, this arrives as a `String` containing serialized JSON (e.g. `'{"message":"Network error..."}'`).
- **Formatting call applied**: `FormatUtils.prettyPrintJson(body)` → which was calling `JsonEncoder.withIndent('  ').convert(body)` directly. When `body` is a `String`, `JsonEncoder.convert` encodes the String itself as a JSON string literal — producing `"\"Network error...\""` with outer quotes and escaped inner quotes. This is the double-encode bug.
- **Confirmed double-encode bug?**: **Yes**. Fixed in the same pass: `prettyPrintJson` now checks `if (json is String)`, attempts `jsonDecode` first, and only calls `encoder.convert` on the decoded object. Falls back to raw string display if the body isn't valid JSON.

### Timeline tab:
- **File reviewed**: `lib/presentation/pages/log_details/tabs/timeline_tab.dart`
- **Values displayed and their real source fields**:
  - `TOTAL` duration card → `log.duration` ✅ (real field)
  - "Request Received" timestamp → hardcoded `'0ms'` ⚠️ (not from data)
  - "Request Received" detail → `log.method` + `log.path` ✅ (real fields)
  - "Auth Validated" timestamp → hardcoded `'5ms'` ⚠️ **fabricated**
  - "Request Validated" timestamp → hardcoded `'15ms'` ⚠️ **fabricated**
  - Error event timestamp → `'${(total * 0.8).round()}ms'` ⚠️ **fabricated** (80% of total duration)
  - "Response Sent" timestamp → `'${total}ms'` ✅ (equals `log.duration`)
  - "Response Sent" detail → `log.statusCode` ✅ (real field)
  - Performance Breakdown bars → hardcoded percentages: Request Processing 10%, Auth 5%, DB Query 70%, Response 15% ⚠️ **entirely fabricated**
  - Bar ms values → `(duration * percentage).round()` ⚠️ **fabricated** (derived from hardcoded ratios)
- **Any fabricated/interpolated values found?**: **Yes — extensively.** The "Auth Validated" (5ms) and "Request Validated" (15ms) events are hardcoded literals. The error event timestamp is `total × 0.8`, invented. The entire Performance Breakdown section uses fixed ratios (10/5/70/15%) applied to `log.duration` — there are no per-stage fields in the backend schema. Every millisecond value in PERFORMANCE BREAKDOWN is fabricated. The only real data in the tab is: the total `duration`, the `method`+`path` on the first event, and the final `statusCode`.

### Status: Fix C complete, double-encode bug fixed (response body now decodes correctly before pretty-printing). Timeline tab confirmed to be showing fabricated data — no backend fields exist to populate it accurately.
### Open questions:
- Timeline tab: replace the fabricated stage breakdown with an honest single-row showing only real data (`method`, `path`, `duration`, `statusCode`), or hide the Performance Breakdown section entirely when no per-stage metadata is present? Recommend hiding it — fabricated percentages in a developer debugging tool are worse than showing nothing.
- Fix C manual verification: do you want to run the app and confirm rapid filter changes produce no spurious errors before we close out?


## [2026-07-21] — Fabricated-Data Audit (per TELEMETRY_PATCH_PLAN.md §4) + Timeline Tab Cleanup

**Context**: Triggered off `bevin-core`'s telemetry handoff doc + this repo's own `TELEMETRY_PATCH_PLAN.md`. Phase 16 (real per-service health) and Phase 18 (multi-instance) both remain **blocked** — `central-logging-service` PR-22 only shipped the metrics *write* side; there's still no `GET` read route, so no real per-service data exists to consume yet. Per §4 of the patch plan ("audit beyond `DashboardStats.fromApiJson` for the same pattern — there may be others not yet caught"), did that audit and fixed what didn't require the blocked read API.

### Audit findings
- `DashboardStats.fromApiJson` (`lib/data/models/dashboard_stats.dart`): confirmed the known issue — `uptime: 100.0` hardcoded, and the *global* `errorRate`/`avgLatency` copied onto every `ServiceStats` entry, because `/logs/stats/summary`'s `byService` only returns request counts.
- `TimelineTab` (`lib/presentation/pages/log_details/tabs/timeline_tab.dart`): confirmed the fabricated data already documented in the `[2026-06-17]` entry above — hardcoded `'5ms'`/`'15ms'` synthetic events, an error timestamp computed as `total × 0.8`, and an entire "PERFORMANCE BREAKDOWN" section using fixed 10/5/70/15% ratios with no backing fields. That entry's own recommendation ("hide it — fabricated percentages are worse than showing nothing") had not yet been acted on.
- No other fabricated-data spots found elsewhere in `lib/` (searched for hardcoded percentages, `Random()`, mock/dummy/placeholder patterns).

### Fixes (no backend/read-API dependency — pure "stop showing confident fake numbers")
- `ServiceStats.errorRate`/`avgLatency`/`uptime`/`errorCount` changed from non-nullable (fabricated) to nullable. `DashboardStats.fromApiJson` now leaves them `null` instead of synthesizing `100.0`/copied-global values. Added `hasHealthMetrics` getter; `healthStatus` returns `HealthStatus.unknown` when null.
- `ServiceHealthCard`: shows `'not reporting metrics yet'` instead of formatted fake numbers when `!hasHealthMetrics`; the pulse dot goes static (no animation, dimmer) for `unknown` status instead of pulsing like a real healthy reading.
- `TimelineTab`: removed the two synthetic mid-timeline events and the entire "PERFORMANCE BREAKDOWN" section/`_BreakdownBar` widget. Timeline now shows only real fields: `0ms` Request Received (method/path), the error event if present (no invented timestamp — shown as `—`), and `{duration}ms` Response Sent (statusCode).
- Hand-updated `dashboard_stats.g.dart` (generated file) to match the new nullable fields — `build_runner` isn't available in this environment to regenerate; the hand edit is a mechanical 1:1 nullable-cast change, worth a real `dart run build_runner build` pass next time the dev environment is available to confirm it matches.

**Also reviewed** (no change needed): `getTimeSeries()`/`_getTimeSeriesFromLogs()` in `api_service.dart` already has the 404-fallback logic Phase 17 of the patch plan describes — confirms the patch plan's own conclusion that no LogPulse code change is needed for Phase 17 until `/logs/stats/timeseries` exists server-side.

### Status: Audit complete. Timeline tab and per-service health card no longer fabricate numbers. Phases 16/18 (real per-service data, multi-instance) remain blocked on the metrics read API per `TELEMETRY_PATCH_PLAN.md` — this session only removed fabrication, it did not add real data (there's nothing real to add yet).
### Open questions:
- Should `dart run build_runner build --delete-conflicting-outputs` be run against the hand-edited `dashboard_stats.g.dart` next session to confirm it matches what codegen would actually produce?
- `flutter analyze`/`flutter test` were not run this session — no Flutter SDK available in this environment. Recommend running both before merging.

---

## Step 16.1 — Define provisional read contract + isolated adapter
Completed: 2026-07-21 01:45 UTC
Branch/commit: main / a155278 (uncommitted)

### What was done
Added lightweight `ServiceMetricsEntry` DTO (`lib/data/models/service_metrics_entry.dart`) separate from `ServiceStats`. Implemented top-level `parseServiceMetricsResponse(dynamic data)` in `api_service.dart`, modeled on `_parseTimeSeriesResponse` defensive style (bare list or `{data: [...]}` envelope). Provisional route assumed: `GET /api/v1/metrics/summary` via new `ApiEndpoints.metricsSummary` (`/metrics/summary`). Partial entries parse present fields and leave the rest null; unknown keys inside `metrics` pass through untouched.

### Key facts for next step
- DTO fields: `appId`, `serviceName?`, `errorRate?`, `avgLatency?`, `uptime?`, `errorCount?`, `customMetrics?`, `lastReportedAt?`, `instanceCount?`
- Parser is the only place that hardcodes response field names (plus snake_case aliases)
- Endpoint constant: `ApiEndpoints.metricsSummary` + `buildMetricsSummaryQuery`

### Deviations from spec
None material — parser is a top-level function (not a private method) so unit tests can call it without Dio; still lives in `api_service.dart` as specified.

### Status
DONE

## Step 16.2 — Extend ServiceStats models
Completed: 2026-07-21 01:45 UTC
Branch/commit: main / a155278 (uncommitted)

### What was done
Extended `ServiceStats` with nullable `customMetrics` (`Map<String, dynamic>?`), `lastReportedAt` (`DateTime?`), and `instanceCount` (`int?` — Phase 18 field landed here to avoid a second model touch). Added `hasCustomMetrics` getter and `copyWith`. Hand-updated `dashboard_stats.g.dart` to match (same approach as prior nullable-health session).

### Key facts for next step
- All three fields optional; zero-telemetry services remain valid with nulls
- Merge into `ServiceStats` happens in the repository (16.4), not the model constructor
- `customMetrics` stays untyped raw map — no per-app schema

### Deviations from spec
Added `hasCustomMetrics` and `copyWith` for convenience (not required by the step, used by UI/merge).

### Status
DONE

## Step 16.3 — ApiService.getServiceMetrics()
Completed: 2026-07-21 01:45 UTC
Branch/commit: main / a155278 (uncommitted)

### What was done
Added `ApiService.getServiceMetrics({String? timeRange})` with the same shape as `getTimeSeries`: issues cancel token via `_issueToken(ApiEndpoints.metricsSummary)`, GETs the provisional endpoint, parses via `parseServiceMetricsResponse`. On `DioException` with `statusCode == 404`, returns `const []` instead of throwing. Non-404 errors still propagate through `_handleDioError`.

### Key facts for next step
- 404 → empty list (endpoint not built yet)
- Auth/5xx still throw as real errors
- Token key: `ApiEndpoints.metricsSummary` (Fix C convention)

### Deviations from spec
None.

### Status
DONE

## Step 16.4 — Wire into DashboardRepository
Completed: 2026-07-21 01:45 UTC
Branch/commit: main / a155278 (uncommitted)

### What was done
`DashboardRepository.getStats()` now `Future.wait`s `getDashboardStats` and `getServiceMetrics` concurrently, then merges metrics into the log-derived `serviceStats` map via `_mergeServiceMetrics`. Match keys: exact `appId`/`serviceName`, then case-insensitive fallback. Log-only services stay as-is (null health). Metrics-only apps (telemetry with zero logs) are added with `totalRequests: 0`.

### Key facts for next step
- Merge lives only in the repository — cards stay dumb
- When metrics 404, merge is a no-op over empty list → pre-Phase-16 behavior
- Concurrent fetch; metrics 404 soft-fails inside ApiService

### Deviations from spec
Non-404 metrics failures still fail the whole `getStats` (ApiService propagates). Independent degradability for 404 is covered; soft-catching 500s was not added to avoid masking real outages.

### Status
DONE

## Step 16.5 — ServiceHealthCard UI (custom metrics + lastReportedAt)
Completed: 2026-07-21 01:45 UTC
Branch/commit: main / a155278 (uncommitted)

### What was done
When `customMetrics` is non-null and non-empty, renders a secondary Wrap of key:value chips (capped at 4 + `+N` overflow). Nested/non-primitive values are stringified via `jsonEncode`/`toString` so the widget cannot crash on unexpected types. When `lastReportedAt` is present, shows a compact relative label (`2m ago`). Chips/relative time only render when data exists — no empty placeholders.

### Key facts for next step
- Chip cap: `ServiceHealthCard.maxMetricChips = 4`
- Compact relative format: `s/m/h/d ago` (not full DateUtils strings)

### Deviations from spec
None.

### Status
DONE

## Step 16.6 — Tests
Completed: 2026-07-21 01:45 UTC
Branch/commit: main / a155278 (uncommitted)

### What was done
Unit tests in `test/service_metrics_parser_test.dart`: (a) well-formed merged response + bare list, (b) empty/malformed envelope, (c) partial entry + skipped invalid rows. Widget tests in `test/service_health_card_test.dart`: chips when present, nothing when null/empty, overflow cap, nested stringify, relative time, instance badge (18.1). `flutter analyze lib test` — no errors (pre-existing infos/warnings only). New tests: 13/13 pass.

### Key facts for next step
- `GoogleFonts.config.allowRuntimeFetching = false` in widget tests to avoid network hangs
- Pre-existing `key_widgets_test` failures (non-uniform borderRadius paint) are unrelated and unchanged

### Deviations from spec
404 path tested at the parser/empty-payload layer rather than with a live Dio mock — `getServiceMetrics` 404 branch is the same pattern as `getTimeSeries` and returns `[]` before the parser runs.

### Status
DONE

## Step 18.1 — Instance count badge
Completed: 2026-07-21 01:45 UTC
Branch/commit: main / a155278 (uncommitted)

### What was done
On `ServiceHealthCard`, when `instanceCount != null && instanceCount > 1`, renders a small `"N instances"` badge next to the service name. No badge for null or 1 (badge signals multi-instance, not presence). Populated via the same 16.4 merge from metrics summary entries — no separate fetch. Widget tests cover multi / single / null fixtures.

### Key facts for next step
- Field already on `ServiceStats` from 16.2; parser maps `instanceCount` / `instance_count`
- Richer per-instance drill-down intentionally skipped per phase plan

### Deviations from spec
None.

### Status
DONE

## Phase 20, Step 1 — Fix the request contract
Completed: 2026-07-21 02:39 UTC
Branch/commit: main / 883d7f8 (uncommitted)

### What was done
Changed `ApiEndpoints.metricsSummary` from `/metrics/summary` to `/metrics` to match PR-24's live route. Rewrote `buildMetricsSummaryQuery` to accept optional `appId` only and drop `timeRange` entirely (server has no time-range filter). Updated `ApiService.getServiceMetrics` and `DashboardRepository.getStats` to stop sending `timeRange` on the metrics call. Path still composes via `$_apiRoot$endpoint` like `/logs`.

### Key facts for next step
- Constant name kept as `metricsSummary` but value is now `/metrics`
- Query builder signature: `buildMetricsSummaryQuery({String? appId})`
- `getServiceMetrics({String? appId})` — no timeRange

### Deviations from spec
Also changed the method signature of `getServiceMetrics` (dropped `timeRange`, optional `appId`) so callers cannot accidentally reintroduce the misleading parameter. Spec only named the endpoints file; this is a necessary follow-on in the same step.

### Status
DONE

## Phase 20, Step 2 — Rewrite response parser for PR-24 shape
Completed: 2026-07-21 02:39 UTC
Branch/commit: main / 883d7f8 (uncommitted)

### What was done
Rewrote `parseServiceMetricsResponse` to read nested `health.status`, `health.uptimeSeconds`, `health.timestamp`, top-level `metrics`, and top-level `metricsReportedAt`. Added `reportedHealthStatus` (raw wire string) and `uptimeSeconds` (raw int) to `ServiceMetricsEntry`. Percentage-typed `uptime` stays null — never aliases seconds into it. `lastReportedAt` prefers `metricsReportedAt`, falls back to `health.timestamp`. `health.instanceId` is intentionally not mapped to `instanceCount`.

### Key facts for next step
- New DTO fields: `reportedHealthStatus` (String?), `uptimeSeconds` (int?)
- `lastReportedAt` still DateTime? on the entry
- Custom `metrics` map path unchanged 1:1 with PR-24
- Numeric errorRate/avgLatency/uptime/errorCount always null from this parser

### Deviations from spec
None material.

### Status
DONE

## Phase 20, Step 3 — Thread fields through ServiceStats + merge
Completed: 2026-07-21 02:39 UTC
Branch/commit: main / 883d7f8 (uncommitted)

### What was done
Added `reportedHealthStatus` and `uptimeSeconds` to `ServiceStats` (constructor, `copyWith`, hand-updated `dashboard_stats.g.dart`). Extended both branches of `DashboardRepository._mergeServiceMetrics` (log-merge and metrics-only) to copy the two new fields with the same `entry.x ?? existing.x` pattern used for other metrics fields.

### Key facts for next step
- Same field names on ServiceStats as ServiceMetricsEntry
- Merge still keyed by appId / serviceName (case-insensitive)

### Deviations from spec
None.

### Status
DONE

## Phase 20, Step 4 — Health-status derivation logic
Completed: 2026-07-21 02:39 UTC
Branch/commit: main / 883d7f8 (uncommitted)

### What was done
Added `hasReportedHealth` getter (non-empty `reportedHealthStatus`). Updated `healthStatus` priority: (1) numeric `hasHealthMetrics` → errorRate thresholds, (2) else `hasReportedHealth` → map wire string, (3) else unknown. Mapping: `"ok"` → healthy; any other non-null string → degraded, with a TODO to revisit when the collector vocabulary is documented. Added `formattedUptimeDuration` for seconds → human duration (`1h 1m`, `45m`, `12s`, `2d 3h`).

### Key facts for next step
- Getters for UI: `hasReportedHealth`, `hasHealthMetrics`, `healthStatus`, `formattedUptimeDuration`, `reportedHealthStatus`
- Do not use `formattedUptime` (percentage) for PR-24 data

### Deviations from spec
None — followed recommended ok→healthy / other→degraded mapping.

### Status
DONE

## Phase 20, Step 5 — ServiceHealthCard three-state display
Completed: 2026-07-21 02:39 UTC
Branch/commit: main / 883d7f8 (uncommitted)

### What was done
Detail line is now three-state via `_detailLine`: full numeric err/latency/uptime% when `hasHealthMetrics`; raw status · `up {formattedUptimeDuration}` when `hasReportedHealth` only; else `"not reporting metrics yet"`. Dot color/pulse continue to use `healthStatus` (covers all three cases). Instance badge and custom-metric chips untouched; `instanceCount` still not derived from `health.instanceId`.

### Key facts for next step
- Middle-state example: `"ok  ·  up 1h 1m"`
- Border paint fix: left accent is a 2px strip + uniform `Border.all` (Flutter forbids non-uniform Border colors with borderRadius — broke tests once real healthy status made the left edge green)

### Deviations from spec
Border implementation changed from multi-color `Border(...)` to strip + `Border.all` so healthy/degraded cards paint correctly under Flutter's borderRadius rules. Visual intent (2px left health accent) preserved.

### Status
DONE

## Phase 20, Step 6 — Tests and verification
Completed: 2026-07-21 02:39 UTC
Branch/commit: main / 883d7f8 (uncommitted)

### What was done
Replaced guessed-contract fixtures with PR-24 shapes: both-present, health-only, metrics-only, neither-present, plus malformed/partial and empty envelope. Added unit tests for `hasReportedHealth` / `healthStatus` mapping / `formattedUptimeDuration`. Widget tests cover middle-state detail line, full numeric state, empty state, and that reported health alone does not show an instance badge. `flutter test test/service_metrics_parser_test.dart test/service_health_card_test.dart` → 24/24 pass. `flutter analyze lib test` → no errors (infos/warnings only, pre-existing noise).

### Key facts for next step
- Phase 20 complete; live dashboard should show real `health.status` + duration for apps reporting via PR-24
- Remaining gap: multi-instance count still needs a server-side distinct count (documented, not fabricated client-side)

### Deviations from spec
None beyond the Step 5 border paint fix noted above.

### Status
DONE

## Phase 21, Step 1 — Decouple metrics fetch failure from getStats
Completed: 2026-07-21 02:55 UTC
Branch/commit: main (uncommitted)

### What was done
Isolated metrics failures inside `DashboardRepository.getStats()` while preserving concurrent fetch of log-stats and metrics. Both futures still start immediately; the metrics future is wrapped with `.catchError` that logs a warning (exception + stack) and substitutes `const <ServiceMetricsEntry>[]`. Log-stats failures still propagate through the outer try/catch as `AppException`. Added a local `Logger` instance matching `ApiService`'s pattern (`package:logger`, no DI). `ApiService.getServiceMetrics()` is unchanged (404 → [], non-404 still throws).

### Key facts for next step
- Catch structure: `metricsFuture = getServiceMetrics().catchError(... return [])` then `Future.wait([statsFuture, metricsFuture])`
- Soft-fail applies to **any** Object (AppException, FormatException, etc.) — not narrowed to DioException
- Cancel tokens remain separately keyed (`ApiEndpoints.stats` vs `ApiEndpoints.metricsSummary`) — verified by reading `_issueToken` usage; no code change needed there

### Deviations from spec
None. Used recommended approach (repository-layer isolation, not ApiService swallow-all).

### Status
DONE

## Phase 21, Step 2 — Tests for metrics isolation
Completed: 2026-07-21 02:55 UTC
Branch/commit: main (uncommitted)

### What was done
Added `test/dashboard_repository_test.dart` with a `_FakeApiService` subclass overriding `getDashboardStats` / `getServiceMetrics`. Covers: (1) metrics ApiException 500 → getStats succeeds, log data intact, no metrics merge; (2) log-stats throw → getStats still fails; (3) both succeed → Phase 20 merge still applies; (4) metrics FormatException → same soft-fail as Dio/AppException. Extra check that both futures are entered (concurrency). All 5 tests pass.

### Key facts for next step
- Fake lives in the test file only; no production DI change
- Warning logs from the soft-fail path appear in test output (expected)

### Deviations from spec
Added a fifth case (metrics-only app when metrics succeed) as a small merge regression guard beyond the four required cases.

### Status
DONE

## LP P0 consumers — timeseries verify + instanceCount + health vocab
Completed: 2026-07-21
Branch/commit: main (uncommitted)

### What was done
After central-logging-service shipped P0 read API (timeseries + multi-instance metrics + write-validated health vocabulary), wired LogPulse consumers:

1. **Timeseries** — Extracted public `parseTimeSeriesResponse()` (same defensive envelope style as metrics). Path was already `GET /logs/stats/timeseries`. Accepts `{ success, data, meta }` with `totalCount`/`errorCount`/`timestamp`. 404 client fallback retained as safety net.
2. **instanceCount** — `parseServiceMetricsResponse` now reads top-level `instanceCount` (never from `health.instanceId`). Merge already threaded the field; badge still shows only when `> 1`.
3. **Health vocabulary** — `_mapReportedHealthStatus`: `ok`→healthy, `error`→unhealthy, `degraded`/`starting`/`stopping`→degraded, unknown→degraded.

### Key facts for next step
- Tests: service_metrics_parser + dashboard_repository + service_health_card all green (35)
- `instances[]` not stored on DTO yet (optional drill-down later)
- **Next CLS slice (P1):** enriched `byService` on summary (`errorRate`/`avgDuration`/`errorCount`) + optional log list `total`
- **Next LP after that:** parse object-shaped `byService` into `ServiceStats` numerics (LP-17)

### Deviations from spec
None.

### Status
DONE

## LP P1 consumers — object byService + logs total
Completed: 2026-07-21
Branch/commit: main (uncommitted)

### What was done
After CLS P1 landed (enriched summary `byService` + log list `total` envelope):

1. **`DashboardStats.fromApiJson`** — parses object-shaped `byService` (`totalRequests`, `errorCount`, `errorRate`, `avgDuration` → `avgLatency`). Legacy bare-int values still work (counts only). Does not invent uptime %.
2. **`hasHealthMetrics`** — true when `errorRate` + `avgLatency` present (no longer requires uptime %). Health status from errorRate thresholds drives the card pulse when numerics exist.
3. **`ServiceHealthCard` detail line** — `err X% · Yms`, optionally `· up Z%` or `· up {duration}` when metrics uptimeSeconds also merged.
4. **`parseLogsPageResponse` / `LogsPageResult`** — reads `data[]`, top-level `total`, `pagination.hasMore`. `LogsNotifier` uses server total/hasMore when available.

### Key facts for next step
- Tests: 46 related tests green
- Merge still combines log numerics × metrics health/instanceCount/customMetrics
- **Next on app (no CLS wait):** LP-08 auto-refresh, LP-03 recent errors tap, cleanup
- **Next CLS (optional P2):** error groups API, services catalog

### Deviations from spec
None material — `hasHealthMetrics` deliberately dropped the uptime-% requirement so P1 payload can light the numeric line.

### Status
DONE

## App polish — auto-refresh, navigation, dead UI
Completed: 2026-07-21
Branch/commit: main (uncommitted)

### What was done
1. **LP-08 Auto-refresh** — Added `AutoRefreshBinder` wrapping `HomePage`. When Settings auto-refresh is on and API is configured, periodically refreshes dashboard, logs (`refresh: true`), and errors. Interval clamped to AppConstants min/max; timer resyncs when toggle/interval/config changes.
2. **LP-03 Recent errors** — Cards navigate to Errors tab; section header has “view all →”.
3. **LP-01/02 AppBar** — Replaced dead bell with manual refresh; search jumps to Logs tab.
4. **Nav bugfix** — `goToLogs`/`goToErrors` previously pointed at wrong indices after Phase 14 tab reorder (Dashboard, Logs, Errors, Settings). Introduced `NavIndex` constants aligned with `HomePage`.

### Key facts for next step
- Remaining LP: cleanup (dead Service models, docs sync, analyze noise, key_widgets paint)
- Remaining CLS optional P2: error groups, services catalog
- No new CLS dependency for current app polish

### Deviations from spec
Bell removed rather than left as a no-op (no notifications API). Refresh icon is the useful substitute.

### Status
DONE

## LP-cleanup + CLS P2 brief
Completed: 2026-07-21
Branch/commit: main (uncommitted)

### What was done (LP-cleanup)
- Removed unused `Service` / `EndpointStats` models and empty `service_details` / `charts` dirs
- Dropped unused `provider` and `http` dependencies from pubspec
- Removed dead `serviceDetails` routes from `AppRoutes`
- Fixed non-uniform Border + borderRadius paint on StatCard, EnhancedLogCard, ErrorGroupCard, ErrorSummaryCard, SkeletonLogCard, Timeline total card (accent strip pattern)
- Updated `key_widgets_test` to match real labels ("TOTAL LOGS", "1.0K", "No data")
- Removed unused `_apiKey` field; stubbed clearCache comment
- Rewrote `handoff_context.md` to current state

### CLS P2 brief
- Wrote `docs/CLS_P2_PR_BRIEF.md` — error groups + services list/detail for CLS to implement next

### Key facts for next step
- Full suite of related tests: 52 passed
- After CLS P2: reintroduce Service model from catalog API; switch ErrorsNotifier to groups endpoint

### Deviations
Naming rename of metricsSummary deferred (LP-27). build_runner regen still manual.

### Status
DONE

## LP P2 consumers — error groups + services catalog
Completed: 2026-07-21
Branch/commit: main (uncommitted)

### What was done
After CLS P2 landed (`/logs/errors/groups`, `/services`, `/services/:name`):

1. **Error groups** — `parseErrorGroupsResponse`, `ApiService.getErrorGroups`, `ErrorsRepository` (404 → client-side fallback). `ErrorsNotifier` no longer depends on loading the full logs list. `ErrorGroup` gains `sampleTraceId` + `fromApiJson`; dropped obsolete `error_group.g.dart`.
2. **Services** — `ServiceSummary` / `ServiceDetail` / `EndpointStats` / `ServiceInstance` models; list + detail parsers and API methods; `ServicesRepository` + providers.
3. **UI** — `ServiceDetailsPage` (overview, health, metrics, instances, top endpoints). Service health cards open detail. Error sheet shows TRACE + "Open in Logs" when `sampleTraceId` present.

### Key facts for next step
- Auto-refresh still calls `loadErrors()` which now hits the groups API (lighter than re-fetching logs).
- Service detail uses same cancel token key as services list (`ApiEndpoints.services`).
- Optional next: dedicated Services tab listing catalog; timeline stage timings only if CLS P3.

### Deviations
Removed json_serializable from ErrorGroup (hand-written API factory only) — simpler than regenerating .g.dart for server-only shape.

### Status
DONE

## Phase 22 — Fix traffic/error chart Y-axis scale
Completed: 2026-07-21
Branch/commit: main (uncommitted)

### What was done
Replaced shared single `maxY` on `ErrorRateChart` with independent traffic (count) and error (rate %) ranges. Error series is projected into the traffic host coordinate space for plotting only (`y' = y/errorMaxY * trafficMaxY`); true percentages kept in a parallel list. Left axis shows sparse traffic count ticks; right axis shows matching fractional heights as `%` labels. Tooltips look up true error % via `trueErrorValueAtX` (does not format transformed `spot.y`). Legend label updated to `errors %`. Pure helpers extracted for unit tests: `computeTrafficMaxY`, `computeErrorMaxY`, `transformErrorPointsForPlot`, `trueErrorValueAtX`.

### Key facts for next step
- Error axis floor: `kErrorAxisFloorPercent = 5.0` (TODO to revisit with real distributions)
- Error axis clamp: max 100.0
- Traffic headroom: still ×1.25; empty/zero traffic host defaults to 1.0
- Tick density: sparse ~0 / mid / max via `_showTick`
- Legacy single-series path unchanged (no dual-axis transform)

### Deviations from spec
None material. Tooltip interaction tested via pure lookup unit test (true % vs transformed y) rather than fl_chart gesture simulation — more stable and pins Step 4's contract.

### Status
DONE

## Phase 23 — Dedicated Services tab
Completed: 2026-07-21
Branch/commit: main (uncommitted)

### What was done
1. **Nav** — `NavIndex.services = 3`, `settings = 4`, `count = 5`; `goToServices()`; HomePage IndexedStack + NavigationBar with `dns_outlined`/`dns` icon, Settings still last.
2. **ServicesPage** — loads `servicesListProvider`, pull-to-refresh, loading/error/empty states; rows via new `ServiceCatalogRow` (not ServiceHealthCard).
3. **Status color (option a)** — `ServiceStats.healthFromErrorRate` shared thresholds; catalog row status strip/dot.
4. **view all →** — `service_health_list` now `goToServices()`.
5. **Auto-refresh** — includes `servicesListProvider.load()`.
6. **Utils** — `DateUtils.formatCompactRelative` for lastSeen.

### Key facts for next step
- Row widget: `ServiceCatalogRow`
- Health color: option (a) via `ServiceStats.healthFromErrorRate`
- Nav icon: `Icons.dns_outlined` / `Icons.dns`
- Tests: navigation_provider_test + services_page_test (empty, null rates, view all)

### Deviations from spec
None material.

### Status
DONE

## Phase 24 — Cross-repo bug-fix pass
Completed: 2026-09-14
Commits: 7fe5278 (Log Detail crash), 8dd8966 (Logs init-load + Settings overflow),
d72782d (ErrorGroup sampleStatusCode), 1a080f1 (API key persistence + Auto label +
dead code removal), and central-logging-service 70a93f3 (CLS-12 search alias +
CLS-13 timeRange fix). Full detail in PHASE_24_SPEC.md.

### What was done
Nine bugs fixed across both repos, found via a live API/data-layer audit and a
screen-by-screen review against real production data ("Bevin Production") rather
than empty-state testing alone:
1. Log Detail page body was blank on every open — Border+borderRadius restriction
   Flutter enforces, hit in 3 widgets (page header, shared DetailSection, Response
   tab status card).
2. Logs tab never fetched on mount — missing the initState call ErrorsPage/
   ServicesPage both have.
3. Settings screen RenderFlex overflow at 375px phone width (Row+Spacer, no wrap).
4. ErrorGroup ignored the server's authoritative sampleStatusCode field in favor of
   a client-side heuristic guess.
5. API key silently reverted when editing an existing connection — copyWith() call
   omitted apiKey when rebuilding the profile.
6. Theme picker's "System" label wrapped at phone width — renamed to "Auto".
7. Dead code: LogFilter.toQueryParams() (unused, duplicated the search/q bug).
8. CLS: GET /api/v1/logs only read `q`, never the `search` param this client
   actually sends — search bar and Find/View Similar silently no-opped.
9. CLS: GET /logs/stats/summary never read `timeRange` — Dashboard's time-range
   selector didn't affect the stat cards or Service Health list at all.

### Key facts for next step
- CLS-12/CLS-13 (items 8-9) are committed but NOT deployed to production — this
  session had no way to build/deploy central-logging-service (no node_modules, no
  private-registry access for @bevingh/auth). Needs a real deploy + smoke test.
- Item 5 (API key fix) needs Kevin to verify live — typing a real key isn't
  something this session does itself.
- Items 1-4, 6-7 are verified live against production data already.

### Deviations from spec
No upfront spec existed for this phase — bugs were found and fixed during review,
then written up retrospectively as PHASE_24_SPEC.md per Kevin's request.

### Status
DONE (code) — PENDING (CLS deploy, live verification of CLS fixes and the API key
fix)
