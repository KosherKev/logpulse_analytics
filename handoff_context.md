# LogPulse Analytics — Context & Handoff

## 1. Project identity
- **Name**: LogPulse Analytics  
- **Purpose**: Mobile analytics dashboard for `central-logging-service` (logs + metrics read).  
- **Stack**: Flutter ≥3 / Riverpod / Dio / fl_chart / google_fonts / flutter_secure_storage  

## 2. Current product state (2026-07-21)

### Done
- UI transformation Phases 1–14 (+ partial 15 animations)  
- Phases 16–21: metrics read, PR-24 reconcile, metrics isolation  
- **CLS P0 + LP consumers**: timeseries, `instanceCount`, health vocabulary  
- **CLS P1 + LP consumers**: object `byService` (err%/latency), logs list `total`  
- **App polish**: auto-refresh, nav fix, recent-errors / AppBar actions  
- **LP-cleanup**: dead `Service` models removed, card borderRadius paint fix, dropped unused `provider`/`http` deps  

### Live CLS routes used by the app
| Call | Route |
|------|--------|
| Logs list | `GET /api/v1/logs` (+ `total` envelope) |
| Logs by trace | `GET /api/v1/logs?traceId=` |
| Summary | `GET /api/v1/logs/stats/summary` (object `byService`) |
| Timeseries | `GET /api/v1/logs/stats/timeseries` (404 → client fallback) |
| Metrics | `GET /api/v1/metrics` |
| Health | `GET /health` |

### Open
- **CLS P2** (optional): error groups + services catalog — see `docs/CLS_P2_PR_BRIEF.md`  
- LP after P2: server-backed Errors tab, service details page  
- Remaining polish: analyze infos, regenerate `*.g.dart` with build_runner when convenient  

## 3. Key paths
```
lib/
  data/services/api_service.dart     # HTTP + parsers
  data/repositories/                 # dashboard + logs
  presentation/pages/                # screens
  presentation/widgets/auto_refresh_binder.dart
BACKLOG.md                           # living backlog
docs/CLS_READ_API_EXTENSIONS.openapi.yaml
docs/CLS_P2_PR_BRIEF.md              # next CLS work
log.md                               # execution log
```

## 4. Auth
- LogPulse uses **flat `X-API-Key`** for all read routes (logs + metrics GET).  
- Metrics **write** keys (`sk_live_` / `sk_test_`) are not used by this app.

## 5. Design principles (do not regress)
- No fabricated health / timeline / uptime numbers  
- Never invent `instanceCount` from a single `instanceId`  
- Metrics failures soft-fail at repository; log-stats failures stay loud  
- Keep timeseries 404 fallback until prod endpoint is proven stable  
