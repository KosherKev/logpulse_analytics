# LogPulse Analytics - Context & Handoff Document

## 1. Project Identity
- **Name**: LogPulse Analytics
- **Purpose**: A mobile analytics dashboard for a centralized API logging service. It provides real-time system health metrics, error tracking with smart grouping, log browsing, and service performance analytics.
- **Target Audience**: Developers, DevOps, and System Administrators monitoring APIs.
- **Stage/Version**: Version `1.0.0+1`. The app is currently undergoing a major "Transformation Phase" consisting of 15 phases. Phases 1-14 have been completed.

## 2. Tech Stack
- **Framework**: Flutter SDK (>= 3.0.0) / Dart SDK (>= 3.0.0)
- **State Management**: `flutter_riverpod` (^2.4.9) and `provider` (^6.1.1)
- **Networking**: `dio` (^5.4.0) and `http` (^1.1.2)
- **Storage**: `flutter_secure_storage` (^9.2.2) for API keys, `shared_preferences` (^2.2.2) for settings/profiles.
- **UI & Data Viz**: `fl_chart` (^1.1.1) for metrics, `google_fonts` (^6.2.1) (Syne, JetBrains Mono, Inter).
- **Code Gen/JSON**: `json_annotation`, `freezed_annotation`, `build_runner`.

## 3. Repo Structure
This is a standard Flutter project structure (`lib/`, `android/`, `ios/`, etc.). The primary logic lives under `lib/`:
```text
lib/
├── main.dart                 # App entry point
├── app.dart                  # App shell & theme wrapper
├── core/
│   ├── constants/            # API endpoints, app constants
│   ├── errors/               # Error handling
│   └── theme/                # Design tokens, AppColors, AppTextStyles
├── data/
│   ├── models/               # Data classes (JSON serializable)
│   ├── repositories/         # Data access layer
│   └── services/             # API service, Local storage service
└── presentation/
    ├── pages/                # Screens (Dashboard, Logs, Errors, Settings)
    ├── widgets/              # Reusable UI components
    └── providers/            # Riverpod/Provider state notifiers
```

## 4. Data Models
All data models reside in `lib/data/models/` and use `json_serializable`:
- **`LogEntry`**: Represents a single log. Includes embedded `RequestData`, `ResponseData`, and `ErrorData`.
- **`DashboardStats`**: Summarized system metrics (error rates, requests).
- **`ErrorGroup`**: Aggregated errors with count and trend data.
- **`TimeSeriesPoint`**: Data points for traffic and error charts.
- **`ApiConnectionProfile`**: Environment configuration (id, name, baseUrl). Note: The `apiKey` is loaded dynamically from secure storage, not serialized to SharedPreferences.
- **`LogFilter`**: Encapsulates active search, level, and service filters.

## 5. API Surface
Defined in `lib/core/constants/api_endpoints.dart`:
- `GET /logs` (supports query params: service, level, statusCode, from, to, limit, skip, search)
- `GET /logs?traceId={traceId}`
- `GET /logs/stats/summary`
- `GET /logs/stats/timeseries` (recently added, gracefully falls back to scanning `/logs` if the backend returns 404)
- `GET /health`
- `GET /ready`

## 6. Roles and Permissions
- Client-side roles are not heavily emphasized. 
- Access is governed by **API Keys** configured per `ApiConnectionProfile`.
- Production keys are securely stored using `flutter_secure_storage`.
- Onboarding handles first-time setup for unconfigured instances.

## 7. Current State
- **Fully Working**: Secure storage migration, request race-condition fixes, error handling specificity, core design tokens (Neo-Terminal precision), and complete UI screen redesigns (Dashboard, Logs, Errors, Log Details, Settings). 
- **Missing/To Do**: Phase 15 (Animation & Micro-interactions) is unstarted.

## 8. Recent Work
- **Completed Phases 1-14** (as documented in `log.md` and `PHASES.md`):
  - Migrated API keys to secure storage.
  - Implemented Dio `CancelToken` to prevent race conditions when changing time ranges rapidly.
  - Built a comprehensive design token system (`AppColors`, `AppTextStyles`, `AppTheme`).
  - Redesigned core components (cards, pills, search bars).
  - Remodeled all primary pages to the new dark/light terminal aesthetic.

## 9. Open Issues
- **Unfinished Work**: Phase 15 - Adding stagger animations to dashboard sections, pulse animations to service health icons, and log card entry fade-ins.
- **Tech Debt**: A few pre-existing `flutter analyze` warnings and infos remain in the codebase (unrelated to the recent phase updates).

## 10. File Location Reference
- **Entry Points**: `lib/main.dart`, `lib/app.dart`
- **Models**: `lib/data/models/` (e.g., `log_entry.dart`)
- **Services**: `lib/data/services/api_service.dart`, `lib/data/services/local_storage_service.dart`
- **State/Providers**: `lib/presentation/providers/` (e.g., `dashboard_provider.dart`, `service_providers.dart`)
- **Constants/Config**: `lib/core/constants/api_endpoints.dart`, `lib/core/constants/app_constants.dart`
- **Pages**: `lib/presentation/pages/`
- **Widgets**: `lib/presentation/widgets/` (e.g., `detail_widgets.dart`, `enhanced_log_card.dart`)
- **Theme**: `lib/core/theme/` (`app_colors.dart`, `app_text_styles.dart`)
- **Transformation Plan**: `PHASES.md` (What to do), `log.md` (What has been done)
