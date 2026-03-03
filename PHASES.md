# LogPulse Analytics — Transformation Phase Plan

> **Execution Model**: All changes in this plan are made exclusively using
> **Desktop Commander MCP** (`desktop-commander:write_file`, `edit_block`,
> `read_file`, `list_directory`, `start_process` etc.).  
> No manual edits, no other tools. Every action is traceable via DC tool calls.
>
> **Continuity**: The companion file `log.md` is updated after every
> semi-phase is completed. Any model picking up this work should read
> `log.md` first to understand exact current state, then consult the
> relevant phase section below for what remains.

---

## Project Location
```
/Users/kevinafenyo/Documents/GitHub/logpulse_analytics
```

---

## Overview

| # | Phase | Category | Priority |
|---|-------|----------|----------|
| 1 | Secure Storage Migration | Functionality | 🔴 Critical |
| 2 | Request Race-Condition & Cancellation | Functionality | 🔴 Critical |
| 3 | Config Boot & Migration Fix | Functionality | 🟠 High |
| 4 | Error Handling Specificity | Functionality | 🟠 High |
| 5 | Time-Series Architecture Improvement | Functionality | 🟡 Medium |
| 6 | Design Token System | UI Foundation | 🔴 Critical |
| 7 | Typography Integration | UI Foundation | 🔴 Critical |
| 8 | Core Component Redesign | UI Components | 🟠 High |
| 9 | Dashboard Screen Redesign | UI Screens | 🟠 High |
| 10 | Logs Screen Redesign | UI Screens | 🟠 High |
| 11 | Errors Screen Redesign | UI Screens | 🟡 Medium |
| 12 | Log Detail Screen Redesign | UI Screens | 🟡 Medium |
| 13 | Settings & ENV Switcher Redesign | UI Screens | 🟡 Medium |
| 14 | Navigation & Shell Redesign | UI Shell | 🟠 High |
| 15 | Animation & Micro-interactions | UI Polish | 🟢 Enhancement |

---

## ════════════════════════════════════════════
## BLOCK A — FUNCTIONALITY FIXES
## ════════════════════════════════════════════

---

### Phase 1 — Secure Storage Migration
**Status**: ⬜ Not Started  
**Files touched**:
- `pubspec.yaml`
- `lib/data/services/local_storage_service.dart`
- `lib/presentation/providers/service_providers.dart`

**Problem**:  
API keys are stored as plain strings in `SharedPreferences`. On iOS/Android,
SharedPreferences is not encrypted. Production API keys must not be stored
this way.

**Actions**:

#### 1-A: Add `flutter_secure_storage` dependency
In `pubspec.yaml`, under `dependencies`, add:
```yaml
flutter_secure_storage: ^9.2.2
```
Keep `shared_preferences` for non-sensitive settings (theme, refresh interval, etc.).

#### 1-B: Create a split storage strategy in `local_storage_service.dart`
- Import `flutter_secure_storage`
- Create a `_secureStorage` instance alongside the existing `_preferences`
- Move `setApiKey` / `getApiKey` to use `_secureStorage.write` / `_secureStorage.read`
- All other keys (theme, auto_refresh, refresh_interval, profiles JSON, active profile ID)
  stay in SharedPreferences as they are non-sensitive
- `getInstance()` must remain async and initialize both storages

#### 1-C: Update `service_providers.dart` `ApiConfigNotifier.loadConfig()`
- The profile JSON in SharedPreferences does NOT contain raw API keys.
  It contains `baseUrl`, `name`, `id` only.
- API key per profile is stored in SecureStorage keyed as `api_key_{profileId}`
- Update `addProfile`, `configure`, `removeProfile`, `setActiveProfile` to
  read/write keys via secure storage using the profile ID as the key suffix
- Update `clearConfig()` to also delete secure storage entries

#### 1-D: Update `ApiConnectionProfile` model
- Remove `apiKey` from the JSON serialization (it no longer lives in SharedPreferences)
- Keep `apiKey` as a runtime field only (populated after secure read at load time)
- Add `copyWith` note that `apiKey` is not persisted via `toJson()`

**Verification**: Run `flutter analyze`. No new warnings. Manually confirm
that a key saved, app restarted, key is still loaded correctly.

---

### Phase 2 — Request Race-Condition & Cancellation
**Status**: ⬜ Not Started  
**Files touched**:
- `lib/data/services/api_service.dart`
- `lib/data/repositories/dashboard_repository.dart`
- `lib/presentation/providers/dashboard_provider.dart`

**Problem**:  
Switching time ranges in quick succession fires multiple concurrent Dio
requests to the same stats endpoint. The last-to-arrive response wins,
potentially showing stale data. There's also no deduplication.

**Actions**:

#### 2-A: Add `CancelToken` tracking to `ApiService`
- Add a `Map<String, CancelToken> _activeTokens` field
- Add `cancelRequest(String key)` and `_getOrCreateToken(String key)` helpers
- In `getDashboardStats()` and `getErrorTrafficSeries()` calls, pass a
  `CancelToken` keyed on the endpoint string
- Before each new request for the same key, cancel the previous token

#### 2-B: Add request debounce in `DashboardNotifier.setTimeRange()`
- Use a `Timer` (dart:async) with a 300ms debounce before calling `loadStats()`
- Cancel the previous timer if `setTimeRange` is called again within the window
- Store the timer in the notifier state as a nullable `Timer? _debounceTimer`

#### 2-C: Handle `DioExceptionType.cancel` gracefully
- In `_handleDioError`, the `cancel` case already exists but rethrows.
- Instead: when a request is cancelled, return silently (don't update error state)
- In `DashboardNotifier`, catch `NetworkException` with code `CANCELLED` and
  do nothing (do not set `error` state)

**Verification**: Rapidly tap 4 time range options in quick succession.
Only one network request should complete. No error state should appear.

---

### Phase 3 — Config Boot & Migration Fix
**Status**: ⬜ Not Started  
**Files touched**:
- `lib/data/services/local_storage_service.dart`
- `lib/presentation/providers/service_providers.dart`
- `lib/core/constants/app_constants.dart`

**Problem**:  
`loadConfig()` runs a legacy migration branch on every cold start when no
profiles JSON exists. This silently uses the hardcoded
`defaultApiBaseUrl` as the base URL for a "Default" profile, which means
every fresh install points to the production endpoint without user consent.
The migration also never marks itself as "done".

**Actions**:

#### 3-A: Add a migration version key
In `AppConstants`, add:
```dart
static const String keyStorageVersion = 'storage_version';
static const int currentStorageVersion = 2;
```

#### 3-B: Rewrite the boot/migration logic in `loadConfig()`
- On first load, check `storage_version` key in SharedPreferences
- If version < 2 (or missing): run legacy migration once, then write
  `storage_version = 2`. After this, the migration branch never runs again.
- If version == 2: skip migration entirely, load profiles JSON directly
- Remove `AppConstants.defaultApiBaseUrl` from auto-configuration.
  New installs start with empty state and navigate user to Settings.

#### 3-C: Remove the hardcoded default URL from `AppConstants`
- Change `defaultApiBaseUrl` to an empty string or remove the constant.
- Replace any usage in `loadConfig()` with a proper "not configured" state.

#### 3-D: Add `isFirstRun` flag to `ApiConfigState`
- When no profiles exist and no URL is configured, `isFirstRun = true`
- `DashboardPage` checks this and shows an onboarding/setup prompt
  instead of the generic "API Not Configured" error

**Verification**: Fresh install (clear SharedPreferences), app opens,
shows setup prompt. Re-run app: setup prompt still shows (no phantom default
profile). Configure API, restart: saved profile loads correctly.

---

### Phase 4 — Error Handling Specificity
**Status**: ⬜ Not Started  
**Files touched**:
- `lib/data/services/api_service.dart`
- `lib/core/constants/app_constants.dart`

**Problem**:  
All network errors collapse to a single generic string from `AppConstants.errorNetwork`.
DNS failures, SSL errors, connection refused, and timeouts all show the same message.

**Actions**:

#### 4-A: Expand `_handleDioError` with specific messages
Replace the generic `AppConstants.errorNetwork` fallback with specific messages:

```dart
case DioExceptionType.connectionTimeout:
  return NetworkException('Connection timed out. Is the server reachable?', code: 'CONN_TIMEOUT');

case DioExceptionType.sendTimeout:
  return NetworkException('Request upload timed out.', code: 'SEND_TIMEOUT');

case DioExceptionType.receiveTimeout:
  return NetworkException('Server is taking too long to respond.', code: 'RECV_TIMEOUT');
```

For the default case, inspect `error.error`:
- `SocketException` → 'Cannot reach server. Check your network or URL.'
- `HandshakeException` → 'SSL/TLS error. Check the server certificate.'
- `CertificateException` → 'Certificate rejected. Check server SSL config.'
- Default → use `error.message ?? AppConstants.errorUnknown`

#### 4-B: Add `debug` logging for raw errors
In the `onError` interceptor, log the full `DioException` including
`error.error.runtimeType` when in debug mode using the existing `_logger`.

#### 4-C: Add error codes to `AppConstants`
```dart
static const String errCodeConnTimeout = 'CONN_TIMEOUT';
static const String errCodeSendTimeout = 'SEND_TIMEOUT';
static const String errCodeRecvTimeout = 'RECV_TIMEOUT';
static const String errCodeSSL = 'SSL_ERROR';
static const String errCodeCancelled = 'CANCELLED';
```

**Verification**: Misconfigure the API URL. Error message should be specific
('Cannot reach server...'), not the generic string.

---

### Phase 5 — Time-Series Architecture Improvement
**Status**: ⬜ Not Started  
**Files touched**:
- `lib/data/repositories/dashboard_repository.dart`
- `lib/core/constants/api_endpoints.dart`

**Problem**:  
`getErrorTrafficSeries()` fetches up to 1000 raw log entries client-side
to build a time-series chart. This is fragile for high-traffic services
and burns unnecessary bandwidth.

**Actions**:

#### 5-A: Add a backend-aware timeseries endpoint constant
In `ApiEndpoints`, add:
```dart
static String buildTimeseriesQuery({String? service, String? timeRange}) { ... }
static const String timeseries = '/logs/stats/timeseries';
```

#### 5-B: Add `getTimeSeries()` to `ApiService` with graceful fallback
```dart
Future<List<TimeSeriesPoint>> getTimeSeries({String? timeRange}) async {
  try {
    // Attempt dedicated endpoint first
    final response = await _dio.get('$_apiRoot${ApiEndpoints.timeseries}?timeRange=$timeRange');
    return _parseTimeSeriesResponse(response.data);
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) {
      // Backend doesn't have this endpoint yet — fall back to log-scan
      return _getTimeSeriesFromLogs(timeRange: timeRange);
    }
    throw _handleDioError(e);
  }
}
```

#### 5-C: Cap the fallback fetch at 200 entries with a warning log
In `_getTimeSeriesFromLogs`, change limit from 1000 to 200.
Add a `_logger.w('Time-series fallback: fetching 200 logs. Consider adding /stats/timeseries endpoint.')`.

#### 5-D: Update `DashboardRepository.getErrorTrafficSeries()` to use the new method

**Verification**: Network tab shows one small request for timeseries data.
No 1000-entry log dump requests.

---

## ════════════════════════════════════════════
## BLOCK B — UI DESIGN TRANSFORMATION
## ════════════════════════════════════════════

> **Design System**: Neo-Terminal Precision  
> **Fonts**: Syne (headings) + JetBrains Mono (data/labels) + Inter (body)  
> **Light bg**: #F7F6F3 | **Dark bg**: #0D1117  
> **Accent Light**: #0052FF | **Accent Dark**: #2D7EFF  

---

### Phase 6 — Design Token System
**Status**: ✅ Complete — 2026-03-03
**Files touched**:
- `pubspec.yaml` (google_fonts: ^6.2.1 added)
- `lib/core/theme/app_colors.dart` (rewrite — AppColorTokens typed container, light/dark variants, legacy compat)
- `lib/core/theme/app_text_styles.dart` (rewrite — Syne/JetBrains Mono/Inter via GoogleFonts, getter-based)
- `lib/core/theme/app_theme.dart` (NEW — AppTheme.lightTheme / darkTheme, full ThemeData)
- `lib/app.dart` (updated to use AppTheme)

**Actions**:

#### 6-A: Add `google_fonts` dependency
```yaml
google_fonts: ^6.2.1
```

#### 6-B: Rewrite `app_colors.dart` with new token system
Full Neo-Terminal palette for both light and dark.  
Key tokens: `bg`, `bgAlt`, `surface`, `surface2`, `border`, `borderSoft`,
`textPrimary`, `textSecondary`, `textTertiary`, `accent`, `accentGlow`,
`accentDim`, `error`, `errorBg`, `errorGlow`, `warning`, `warningBg`,
`success`, `successBg`, `info`, `infoBg`, `debug`, `pulse`.
Both light and dark variants for each.

#### 6-C: Rewrite `app_text_styles.dart` using GoogleFonts
- `display` → Syne 800, used for dashboard numbers
- `h1/h2/h3` → Syne 700/600
- `label` → JetBrains Mono 500, uppercase, letter-spacing 1.5px (for overlines, chips)
- `mono` / `monoSm` → JetBrains Mono 400/500 (paths, trace IDs, timestamps)
- `body` / `bodySmall` → Inter 400/500

#### 6-D: Create `lib/core/theme/app_theme.dart`
- `AppTheme.lightTheme` and `AppTheme.darkTheme` as full `ThemeData` objects
- Uses the new color tokens and text styles
- Sets `NavigationBarThemeData`, `CardTheme`, `ChipThemeData`, `InputDecorationTheme`

#### 6-E: Update `lib/app.dart` to use `AppTheme.lightTheme` / `AppTheme.darkTheme`

**Verification**: `flutter analyze` clean. Hot reload shows warm off-white
light background and deep slate dark background.

---

### Phase 7 — Typography Integration
**Status**: ✅ Complete — 2026-03-03
**Files touched**:
- `lib/presentation/pages/dashboard/dashboard_page.dart`
- `lib/presentation/pages/logs/logs_page.dart`
- `lib/presentation/pages/settings/settings_page.dart`
- `lib/presentation/pages/log_details/log_details_page.dart`
- `lib/presentation/pages/log_details/tabs/overview_tab.dart`
- `lib/presentation/pages/log_details/tabs/error_tab.dart`
- `lib/presentation/pages/log_details/tabs/request_tab.dart`
- `lib/presentation/pages/log_details/tabs/response_tab.dart`
- `lib/presentation/pages/log_details/tabs/timeline_tab.dart`
- `lib/presentation/widgets/common_widgets.dart`
- `lib/presentation/widgets/errors/error_group_card.dart`
- `lib/presentation/widgets/logs/enhanced_log_card.dart`
- `lib/presentation/widgets/filter_dialog.dart`
- `lib/presentation/widgets/dashboard/time_range_selector.dart`
- `lib/presentation/widgets/errors/error_group_card.dart`
- `lib/presentation/widgets/errors/summary_card.dart`
- `lib/presentation/widgets/logs/enhanced_log_card.dart`
- `lib/presentation/widgets/common_widgets.dart`
- `lib/presentation/widgets/filter_dialog.dart`

**Style Mapping** (old → new):
| Old | New | Font | Notes |
|-----|-----|------|-------|
| `TextStyle(fontSize:20, fontWeight:bold)` | `AppTextStyles.h2` | Syne 700 | Inline raw styles (dashboard/logs) |
| `Theme.of(context).textTheme.titleLarge` | `AppTextStyles.h3` | Syne 600 | common_widgets titles |
| `AppTextStyles.overline` | `AppTextStyles.label` | JetBrains Mono | Upgrade overline→label |
| `AppTextStyles.codeSmall` | `AppTextStyles.monoSm` | JetBrains Mono | All code/trace/path values |
| `AppTextStyles.code` | `AppTextStyles.mono` | JetBrains Mono | Longer code blocks |
| `TextStyle(fontWeight:bold)` | `AppTextStyles.bodyMedium` | Inter 500 | Raw bold in filter_dialog |
| `TextStyle(color: Colors.grey[600])` | `AppTextStyles.body` + token color | Inter 400 | Generic grey text |
| `TextStyle(color:Colors.red)` | `AppTextStyles.bodyMedium` + error token | Inter 500 | Danger text in settings |

**Actions**:

#### 7-A: Fix raw `TextStyle(...)` in `dashboard_page.dart`
Three instances at lines ~101, ~127, ~153 use `TextStyle(fontSize:20, fontWeight:FontWeight.bold)`.
Replace all three with `AppTextStyles.h2.copyWith(color: c.textPrimary)` where
`c = AppColors.of(context)`.

#### 7-B: Fix raw `TextStyle(...)` and `.textTheme.titleLarge` in `logs_page.dart`
- Line ~427: `TextStyle(fontSize: 20, fontWeight: FontWeight.bold)` → `AppTextStyles.h2`
- Line ~453: inline raw TextStyle → `AppTextStyles.body`
- Line ~462: `TextStyle(color: Colors.grey[600])` → `AppTextStyles.body.copyWith(color: c.textTertiary)`

#### 7-C: Fix raw `TextStyle(...)` in `filter_dialog.dart`
Four instances of `TextStyle(fontWeight: FontWeight.bold)` (lines ~49, ~71, ~94, ~116).
Replace all four with `AppTextStyles.bodyMedium`.

#### 7-D: Fix raw `TextStyle(...)` in `settings_page.dart`
- Lines ~471, ~500: `TextStyle(color: Colors.red)` → `AppTextStyles.bodyMedium.copyWith(color: c.error)`

#### 7-E: Fix `Theme.of(context).textTheme.titleLarge` in `common_widgets.dart`
- Lines ~53, ~102: `.textTheme.titleLarge?.copyWith(...)` → `AppTextStyles.h3.copyWith(...)`
- Lines ~62, ~108: `TextStyle(color: Colors.grey[600])` → `AppTextStyles.bodySmall.copyWith(color: c.textTertiary)`

#### 7-F: Upgrade `AppTextStyles.overline` → `AppTextStyles.label` app-wide
`overline` in `settings_page.dart` line ~359 → `AppTextStyles.label`.

#### 7-G: Upgrade `AppTextStyles.codeSmall` → `AppTextStyles.monoSm` app-wide
All occurrences across log_details_page, all tabs, error_group_card, enhanced_log_card.

#### 7-H: Fix `error_tab.dart` raw `TextStyle(...)` at line ~31
Raw `TextStyle(...)` → `AppTextStyles.monoSm`.

**Verification**:
- `flutter analyze` — no new issues vs Phase 6 baseline (75 pre-existing)
- No `TextStyle(` raw literals remain in any file listed above
- No `Colors.grey[600]`, `Colors.red` hardcoded color references remain
- No `AppTextStyles.codeSmall` or `AppTextStyles.overline` calls remain

---

### Phase 8 — Core Component Redesign
**Status**: ✅ Complete — 2026-03-03  
**Files touched**:
- `lib/presentation/widgets/cards/stat_card.dart` (rewrite)
- `lib/presentation/widgets/cards/service_health_card.dart` (rewrite)
- `lib/presentation/widgets/logs/enhanced_log_card.dart` (rewrite)
- `lib/presentation/widgets/errors/error_group_card.dart` (rewrite)
- `lib/presentation/widgets/errors/summary_card.dart` (rewrite)
- `lib/presentation/widgets/common_widgets.dart` (update)

**Actions**:

#### 8-A: Rewrite `StatCard`
- Remove the old Card+Icon pattern
- New design: left-border accent (3px, color from level), label in JetBrains Mono
  OVERLINE, value in Syne display, delta in JetBrains Mono with up/down color
- No shadow elevation — use border instead

#### 8-B: Rewrite `ServiceHealthCard`
- Left-border 2px in health color (green/amber/red)
- Pulsing dot animation for `healthy` status
- Error-pulse animation for `unhealthy` status (CSS-style animation via
  Flutter `AnimationController`)
- Service name in JetBrains Mono, detail row (err% · latency · uptime) in
  JetBrains Mono small with textTertiary

#### 8-C: Rewrite `EnhancedLogCard`
- Left-border 3px in level color
- Level chip: JetBrains Mono, uppercase, colored border + bg
- Service name: JetBrains Mono 600
- Method + path row: dedicated container, method in accent, path in mono
- Meta row: icon+text pairs for timestamp / duration / traceId (truncated)
- Error message preview: red bg pill at bottom if `log.error?.message != null`

#### 8-D: Add `SkeletonLogCard` loading placeholder
- Shimmer-style grey boxes matching the shape of `EnhancedLogCard`
- Replaces bottom spinner during `loadMore()`

#### 8-E: Update `EmptyState` and `ErrorState` in `common_widgets.dart`
- Use new text styles and colors

**Verification**: Log list, error list, service health list all show new
component designs. Pulse animation visible on healthy services.

---

### Phase 9 — Dashboard Screen Redesign
**Status**: ✅ Complete — 2026-03-03  
**Files touched**:
- `lib/presentation/pages/dashboard/dashboard_page.dart` (rewrite)
- `lib/presentation/widgets/dashboard/stats_grid.dart` (update)
- `lib/presentation/widgets/dashboard/error_rate_chart.dart` (update)
- `lib/presentation/widgets/dashboard/service_health_list.dart` (update)
- `lib/presentation/widgets/dashboard/recent_errors_list.dart` (update)
- `lib/presentation/widgets/dashboard/time_range_selector.dart` (update)

**Actions**:

#### 9-A: Add ENV Switcher widget
Create `lib/presentation/widgets/dashboard/env_switcher_bar.dart`:
- Shows active profile name + truncated URL
- Green pulsing dot for "connected", red for error state
- "SWITCH" button triggers a bottom sheet with profile list
- Positioned between top nav and time range pills

#### 9-B: Update `StatsGrid`
- Use 2-column grid always (remove the width check — mobile is always 2-col)
- Use new `StatCard` component

#### 9-C: Update `ErrorRateChart`
- Dual-line chart: traffic (solid) + errors (dashed)
- Chart background matches `surface` color (not white)
- Add legend row below chart (colored line + label)
- Gradient fill under each line using theme colors
- Empty state: more graceful placeholder with icon

#### 9-D: Update `TimeRangeSelector`
- Replace `ChoiceChip` with pill buttons using new design tokens
- Active pill: accent background, white text
- Inactive pill: surface background, textTertiary

#### 9-E: Update Dashboard page layout
- Add "last updated" timestamp below the ENV bar
- Section headers use `AppTextStyles.h3`
- Add `RefreshIndicator` with custom color

**Verification**: Dashboard loads with ENV bar, dual-chart, updated stats
grid, and service health list all using the new design language.

---

### Phase 10 — Logs Screen Redesign
**Status**: ✅ Complete — 2026-03-03  
**Files touched**:
- `lib/presentation/pages/logs/logs_page.dart` (update)
- `lib/presentation/widgets/logs/enhanced_log_card.dart` (already done in Phase 8)

**Actions**:

#### 10-A: Redesign the search bar
- Rounded 12px container matching `surface` with `border`
- Prefix: search icon (textTertiary)
- Suffix: `⌘K` shortcut badge + clear button
- Focus state: accent border color

#### 10-B: Redesign filter chips row
- Use pill-style chips instead of `ChoiceChip`
- Active level chip: colored border + colored text + colored bg (from token)
- Error chip → error colors, Warn → warning colors, Info → info colors

#### 10-C: Add results count divider
- After filter chips, show "N results · Xxx priority" in a label-divider
  style row (horizontal rule with text)

#### 10-D: Replace bottom loading spinner with `SkeletonLogCard`
- When `loadMore()` is in progress, show 3 skeleton cards

#### 10-E: Redesign saved filters bottom sheet
- Full-screen modal with handle
- Filters listed as rows with name + active filter summary
- Add/delete actions with swipe-to-delete

**Verification**: Log screen shows redesigned search, pill filters,
results count, skeleton loading.

---

### Phase 11 — Errors Screen Redesign
**Status**: ✅ Complete — 2026-03-03  
**Files touched**:
- `lib/presentation/pages/errors/errors_page.dart` (update)
- `lib/presentation/widgets/errors/error_group_card.dart` (already in Phase 8)
- `lib/presentation/widgets/errors/summary_card.dart` (already in Phase 8)

**Actions**:

#### 11-A: Update summary cards row
- Use full-width `ErrorSummaryCard` for total, then 2-column row for 5xx/4xx
- Use new design tokens for colors

#### 11-B: Add severity filter tabs
- Horizontal scrollable filter: ALL | CRITICAL | HIGH | MEDIUM | LOW
- Filters `errorsProvider` state locally (no new API call)

#### 11-C: Redesign error details bottom sheet
- Full `DraggableScrollableSheet` instead of fixed `showModalBottomSheet`
- Stack trace shown in a dark terminal-style container
- Actions section: "Find similar" + "View trace" as outlined buttons

**Verification**: Errors page shows summary cards, severity filter,
and improved detail sheet.

---

### Phase 12 — Log Detail Screen Redesign
**Status**: ✅ Complete — 2026-03-03  
**Files touched**:
- `lib/presentation/pages/log_details/log_details_page.dart` (update)
- `lib/presentation/pages/log_details/tabs/overview_tab.dart` (update)
- `lib/presentation/pages/log_details/tabs/request_tab.dart` (update)
- `lib/presentation/pages/log_details/tabs/response_tab.dart` (update)
- `lib/presentation/pages/log_details/tabs/error_tab.dart` (update)
- `lib/presentation/pages/log_details/tabs/timeline_tab.dart` (update)

**Actions**:

#### 12-A: Update the header card
- Level badge: new design token chip
- Method+path: dark terminal container with accent method color
- Timestamps and duration: JetBrains Mono
- Trace ID: styled as a link (underline + accent color), tap copies

#### 12-B: Update the tab bar
- Custom tab bar using `TabBar` with `labelStyle: AppTextStyles.label`
- Indicator: 2px bottom line in accent color (not full-width underline)
- Use scrollable tabs

#### 12-C: Update all tab content
- All key-value rows: left label in JetBrains Mono (textTertiary),
  right value in JetBrains Mono (textPrimary)
- Headers/JSON bodies: dark terminal container (`darkSurface` bg)
- Copy buttons: icon only, no label

#### 12-D: Update Timeline tab
- Real timeline dots with connecting lines (already exists, just restyle)
- Progress breakdown bars: use theme colors, not hardcoded Flutter colors

**Verification**: Log detail page opens with new header, styled tabs, and
terminal-style content containers.

---

### Phase 13 — Settings & ENV Switcher Redesign
**Status**: ✅ Complete — 2026-03-03  
**Files touched**:
- `lib/presentation/pages/settings/settings_page.dart` (rewrite)

**Actions**:

#### 13-A: Redesign the settings layout
- Remove `ListTile` stacking pattern
- Use grouped sections with `AppTextStyles.label` overline headers
- Each setting item: custom row with label, description, and control

#### 13-B: Redesign the API connection section
- Replace inline text fields with a dedicated "Connection Manager" card
- Each profile shown as a row: name, truncated URL, active indicator
- Active profile gets an accent left-border
- "Add Connection" → bottom sheet form (not AlertDialog)

#### 13-C: Redesign the theme picker
- Use an inline segmented control (Light | Dark | System)
  instead of a radio list dialog

#### 13-D: Redesign the danger zone
- Subtle destructive styling: muted background, red text only
  (not the full red `Card` background which looks alarming)

**Verification**: Settings page looks like a modern developer tool settings
panel, not a 2018 Material settings screen.

---

### Phase 14 — Navigation & Shell Redesign
**Status**: ⬜ Not Started  
**Files touched**:
- `lib/presentation/pages/home_page.dart` (update)
- `lib/app.dart` (update)

**Actions**:

#### 14-A: Redesign the `NavigationBar`
- Custom `NavigationBarThemeData` in `AppTheme`
- Active item: accent background pill (44x32px), accent icon + accent label
- Inactive item: textTertiary icon + textTertiary label
- No default Material 3 indicator blob — use custom pill shape
- Badge on Errors tab: small red dot with count

#### 14-B: Update nav item order
Current: Dashboard → Errors → Logs → Settings  
New: Dashboard → **Logs** → Errors → Settings  
(Logs is the most-used screen, should be position 2)

#### 14-C: Update the top AppBar style
- Remove default AppBar elevation
- Title: `AppTextStyles.h3` (Syne) instead of default title style
- Background: transparent, blurred (using `BackdropFilter`) or solid `surface`
- Action buttons: custom `nav-icon-btn` style (surface bg, border, rounded)

**Verification**: Navigation uses new pill indicator. Tab order updated.
App bar looks clean and intentional.

---

### Phase 15 — Animation & Micro-interactions
**Status**: ⬜ Not Started  
**Files touched**:
- `lib/presentation/widgets/cards/service_health_card.dart` (add animations)
- `lib/presentation/pages/dashboard/dashboard_page.dart` (stagger reveals)
- `lib/presentation/widgets/dashboard/env_switcher_bar.dart` (add pulse)

**Actions**:

#### 15-A: Health dot pulse animation
- `StatefulWidget` with `AnimationController` (repeat, 2s, easing)
- Healthy dot: gentle scale pulse (0.8x → 1.2x) + box-shadow grow
- Error dot: faster pulse (1s) with red glow

#### 15-B: Dashboard staggered entry animation
- Wrap each dashboard section in a `FadeTransition` + `SlideTransition`
- Stagger: stats (0ms), chart (100ms), services (200ms), errors (300ms)
- Trigger on first load only (not on refresh)

#### 15-C: Log card entry animation
- Each `EnhancedLogCard` fades in with a 20ms stagger per item
- Only for initial load — append (loadMore) has no animation

#### 15-D: ENV switcher pulse
- The green status dot uses the same pulse animation as health dots
- Red dot pulses faster when the last API call resulted in an error

**Verification**: Dashboard loads with staggered fade-in. Service health
dots pulse. Log cards fade in on first load.

---

## Handoff Notes for Continuation

When a new model picks up this work:

1. **Read `log.md` first** — it records exactly which semi-phases are done
2. **Check the git status** — `git diff --stat` shows changed files
3. **Run `flutter analyze`** — must be clean before starting new phase
4. **Run `flutter test`** — both test files must pass
5. **All edits via Desktop Commander** — no manual IDE edits
6. Each phase's "Verification" section must pass before marking done in `log.md`
