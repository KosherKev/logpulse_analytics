# LogPulse Analytics — Product & Engineering Backlog

> **Living document.** Snapshot after Phases 16–21 + **LP P0 consumers** (timeseries verify, `instanceCount` parse, full health vocabulary).  
> Companion plans: `PHASES.md` (UI transformation 1–15), `TELEMETRY_PATCH_PLAN.md` (16–21), `log.md` (execution log).  
> **OpenAPI shapes for `central-logging-service` are in §3** — P0 CLS shipped; next CLS slice is P1 (§3.3–3.4).

**Legend**

| Tag | Meaning |
|-----|---------|
| `CLS` | Work primarily in **central-logging-service** |
| `LP` | Work primarily in **logpulse_analytics** |
| `BOTH` | Needs coordinated change |
| P0 / P1 / P2 | Priority |

---

## 1. Status snapshot

| Area | State |
|------|--------|
| Core screens (Dashboard, Logs, Errors, Log Detail, Settings, Nav) | Built (Phases 1–14) |
| Per-service health from `GET /metrics` (PR-24 + Phase 20) | Wired |
| Metrics failure isolation (Phase 21) | Done |
| Real timeseries chart | **CLS live** — LP parser verified; 404 fallback kept as safety net |
| Multi-instance badge | **Wired** — parses top-level `instanceCount`; badge when `> 1` |
| Health status colors | Full vocab: `ok`/`error`/`degraded`/`starting`/`stopping` |
| Per-service err% / latency line | **Wired** — object `byService` → `errorRate`/`avgLatency`/`errorCount` |
| Logs list total count | **Wired** — envelope `total` / `pagination.hasMore` |
| Service details screen | Empty folder + unused route |
| Auto-refresh setting | UI only — not wired |
| Several AppBar / list taps | Dead (`onTap: () {}`) |

---

## 2. LogPulse client backlog (`LP`)

### 2.1 Dead / incomplete UI — P0–P1

| ID | Priority | Item | Location | Notes |
|----|----------|------|----------|-------|
| LP-01 | P1 | Dashboard bell button | `dashboard_page.dart` | `onTap: () {}` — implement notifications or remove |
| LP-02 | P1 | Dashboard search button | `dashboard_page.dart` | `onTap: () {}` — jump to Logs with focus, or remove |
| LP-03 | P0 | Recent Critical Errors tap | `recent_errors_list.dart` | `onTap: () {}` — open Errors tab or same detail sheet as Errors page |
| LP-04 | P1 | “view all →” on Service Health | `service_health_list.dart` | Currently goes to Logs; should list all services or dedicated health view |
| LP-05 | P1 | Service details route | `AppRoutes.serviceDetails`, empty `pages/service_details/` | Build page after CLS services API, or delete route + dead models |
| LP-06 | P2 | Stat card deltas | `stats_grid.dart` | Always `delta: null`; needs previous-period stats (CLS or client compare) |
| LP-07 | P2 | Errors nav badge | `home_page.dart` / Phase 14 | Planned red count badge — wire to real error group count |

### 2.2 Half-built features — P0–P1

| ID | Priority | Item | Location | Notes |
|----|----------|------|----------|-------|
| LP-08 | P0 | Auto-refresh | Settings + `settings_provider` | Toggle/interval persisted; nothing runs `Timer.periodic` for dashboard/logs |
| LP-09 | P2 | `serviceHealthProvider` | `dashboard_provider.dart` | `checkHealth()` unused by UI |
| LP-10 | P2 | `ApiEndpoints.ready` | constants only | Never called |
| LP-11 | P1 | Errors page data model | `errors_provider.dart` | Client-side grouping of currently loaded logs — incomplete without CLS groups API |
| LP-12 | P2 | `ErrorGroup.isResolved` | model | Always false; no resolve UX |
| LP-13 | ~~P1~~ **DONE** | Logs `totalCount` | Uses server `total` when present; bare list falls back to page length |
| LP-14 | P2 | Metrics soft-fail visibility | after Phase 21 | Failures only log a warning; optional “metrics unavailable” chip on dashboard |

### 2.3 Honest-but-thin UX (depends on CLS for richness)

| ID | Priority | Item | Blocked on |
|----|----------|------|------------|
| LP-15 | ~~P0~~ **DONE** | Traffic & Errors chart accuracy | CLS timeseries live; `parseTimeSeriesResponse` + 404 fallback retained |
| LP-16 | ~~P1~~ **DONE** | Instance badge on `ServiceHealthCard` | Parses top-level `instanceCount`; never from `health.instanceId` |
| LP-17 | ~~P1~~ **DONE** | Full numeric health line (`err% · ms`) | Object `byService`; uptime % optional; may pair with metrics duration |
| LP-18 | P2 | Timeline performance breakdown | Only if CLS adds real stage spans — do **not** re-fabricate |
| LP-19 | ~~P2~~ **DONE** | Health status color mapping | `ok`→healthy, `error`→unhealthy, `degraded`/`starting`/`stopping`→degraded |

### 2.4 Cleanup / tech debt — P1–P2

| ID | Priority | Item | Notes |
|----|----------|------|-------|
| LP-20 | P1 | Stale docs | Update `PHASES.md` table, `TELEMETRY_PATCH_PLAN` Phase 21 status, `handoff_context.md`, `log.md` quick summary |
| LP-21 | P1 | Dead models | `Service` + `EndpointStats` unused — delete or wire after CLS services catalog |
| LP-22 | P2 | Empty dirs | `pages/service_details/`, `widgets/charts/` |
| LP-23 | P2 | Dual packages | `provider` + `flutter_riverpod` — drop unused `provider` if nothing imports it |
| LP-24 | P1 | Regenerate codegen | `dart run build_runner build --delete-conflicting-outputs` after hand-edited `*.g.dart` |
| LP-25 | P2 | Analyze noise | ~100 infos/warnings (unused fields, deprecated Radio, redundant args) |
| LP-26 | P1 | Fix `key_widgets_test` paint failures | Non-uniform `Border` + `borderRadius` on StatCard / EnhancedLogCard (same class of bug fixed on ServiceHealthCard) |
| LP-27 | P2 | Naming cleanup | `metricsSummary` constant is `/metrics`; `hasHealthMetrics` means numeric err/latency/% only |
| LP-28 | P2 | Drop unused `http` package if Dio-only | Confirm no imports |
| LP-29 | P2 | Phase 15 polish | Stagger/pulse largely present; optional log-card entry fades, skeleton dashboard |

### 2.5 Suggested LogPulse implementation order (no CLS wait)

1. **LP-08** auto-refresh  
2. **LP-03** recent errors tap  
3. **LP-01 / LP-02** wire or remove dead AppBar actions  
4. **LP-14** optional metrics-unavailable chip  
5. **LP-20 / LP-24 / LP-26** docs + codegen + tests green  
6. **LP-05 / LP-21** after CLS services catalog — or delete dead code  

---

## 3. central-logging-service — OpenAPI shapes (`CLS`)

Implement these in the collector. LogPulse base path: **`/api/v1`**. Auth for read routes today: **same flat `X-API-Key` as `/logs`** (confirm; metrics write keys are separate and not used by LogPulse).

Shared conventions LogPulse already accepts:

- Envelope: `{ "success": true, "data": ... }` **or** bare array for list-like payloads  
- ISO-8601 timestamps, UTC preferred  
- `timeRange` enum used by the app: `last_hour` | `last_24h` | `last_7d` | `last_30d`

---

### 3.1 P0 — Log stats timeseries (Phase 17)

**Why:** Dashboard Traffic & Errors chart; today every load 404s and falls back to bucketing ≤200 raw logs.

**LogPulse client today**

- Path: `GET /api/v1/logs/stats/timeseries`
- Query: optional `service`, optional `timeRange`
- Parser accepts list **or** `{ data: [...] }`
- Point fields: `timestamp` (ISO string), `totalCount` **or** `total`, `errorCount` **or** `errors`

#### OpenAPI fragment

```yaml
# ─── GET /api/v1/logs/stats/timeseries ─────────────────────────────────────
paths:
  /api/v1/logs/stats/timeseries:
    get:
      operationId: getLogsStatsTimeseries
      summary: Bucketed request and error counts over a time window
      tags: [Logs Stats]
      security:
        - ApiKeyAuth: []
      parameters:
        - name: timeRange
          in: query
          required: false
          description: |
            Preset window ending at "now". Default: last_24h.
            Mutually exclusive with from+to if you support absolute bounds later.
          schema:
            type: string
            enum: [last_hour, last_24h, last_7d, last_30d]
            default: last_24h
        - name: service
          in: query
          required: false
          description: Filter to one service/app name (match log.service)
          schema:
            type: string
        - name: from
          in: query
          required: false
          description: Optional absolute start (ISO-8601). Prefer over inventing custom ranges client-side.
          schema:
            type: string
            format: date-time
        - name: to
          in: query
          required: false
          description: Optional absolute end (ISO-8601). Default now.
          schema:
            type: string
            format: date-time
      responses:
        '200':
          description: Ordered ascending by timestamp (bucket start)
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/TimeseriesResponse'
              examples:
                last24h:
                  value:
                    success: true
                    data:
                      - timestamp: "2026-07-21T00:00:00.000Z"
                        totalCount: 120
                        errorCount: 4
                      - timestamp: "2026-07-21T01:00:00.000Z"
                        totalCount: 98
                        errorCount: 1
        '401':
          $ref: '#/components/responses/Unauthorized'
        '500':
          $ref: '#/components/responses/ServerError'

components:
  schemas:
    TimeseriesBucket:
      type: object
      required: [timestamp, totalCount, errorCount]
      properties:
        timestamp:
          type: string
          format: date-time
          description: Bucket start (UTC)
        totalCount:
          type: integer
          minimum: 0
          description: Requests/logs in bucket (alias accepted by clients today - total)
        errorCount:
          type: integer
          minimum: 0
          description: Error-class count in bucket (alias - errors)
        # Optional extensions (LogPulse ignores today; safe to add)
        avgDuration:
          type: number
          description: Mean duration ms in bucket
        service:
          type: string
          description: Present only when filtered by service

    TimeseriesResponse:
      type: object
      required: [success, data]
      properties:
        success:
          type: boolean
          example: true
        data:
          type: array
          items:
            $ref: '#/components/schemas/TimeseriesBucket'
        meta:
          type: object
          description: Optional server-chosen bucket size for debugging
          properties:
            bucketMs:
              type: integer
              example: 3600000
            timeRange:
              type: string
              example: last_24h

  # Suggested bucket sizes (server-side; match LogPulse client fallback)
  # last_hour  → 5 minutes
  # last_24h   → 1 hour
  # last_7d    → 12 hours
  # last_30d   → 1 day
```

**Implementation notes (CLS)**

- Aggregate from stored logs (same source as `/logs/stats/summary`), not from a sample of 200 docs.
- Include zero-fill empty buckets if you want continuous charts; LogPulse charts work either way.
- Do **not** require new LogPulse code once 200 is stable — 404 branch stops firing. Keep fallback for a while as safety net.

---

### 3.2 P0 — Metrics read extensions (multi-instance + vocabulary)

**Why:** Badge UI exists; PR-24 returns a single latest `health.instanceId`, not a count. Fabricating “1 instance” is explicitly forbidden in LogPulse.

**Base route today (PR-24):** `GET /api/v1/metrics?appId=<optional>`

#### 3.2.1 Extended response shape (backward-compatible)

Keep existing fields; **add** optional aggregation fields.

```yaml
paths:
  /api/v1/metrics:
    get:
      operationId: getMetricsSnapshot
      summary: Latest health + free-form metrics per appId
      tags: [Metrics]
      security:
        - ApiKeyAuth: []
      parameters:
        - name: appId
          in: query
          required: false
          description: If omitted, return one row per known appId
          schema:
            type: string
        - name: instanceWindowSeconds
          in: query
          required: false
          description: |
            Window for counting distinct instanceIds (default e.g. 900 = 15m).
            Only affects instanceCount / instances; latest health/metrics still "latest".
          schema:
            type: integer
            minimum: 60
            maximum: 86400
            default: 900
      responses:
        '200':
          description: Array of per-app snapshots
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/MetricsListResponse'
              examples:
                multiInstance:
                  value:
                    success: true
                    data:
                      - appId: academicx
                        health:
                          status: ok
                          instanceId: rev-abc-xyz
                          uptimeSeconds: 86400
                          timestamp: "2026-07-21T12:00:00.000Z"
                        metrics:
                          students: 120
                          activeToday: 45
                        metricsReportedAt: "2026-07-21T12:01:00.000Z"
                        # ── NEW (v1.1) ──────────────────────────────────────
                        instanceCount: 3
                        instances:
                          - instanceId: rev-abc-xyz
                            lastSeen: "2026-07-21T12:00:00.000Z"
                            status: ok
                            uptimeSeconds: 86400
                          - instanceId: rev-def-uvw
                            lastSeen: "2026-07-21T11:58:00.000Z"
                            status: ok
                            uptimeSeconds: 1200
                          - instanceId: rev-ghi-rst
                            lastSeen: "2026-07-21T11:55:00.000Z"
                            status: degraded
                            uptimeSeconds: 300

components:
  schemas:
    HealthDoc:
      type: object
      nullable: true
      description: Latest kind=health document for the app, or null
      properties:
        status:
          type: string
          description: See HealthStatus enum
          example: ok
        instanceId:
          type: string
          description: Instance that produced this latest health doc (not a count)
        uptimeSeconds:
          type: integer
          minimum: 0
        timestamp:
          type: string
          format: date-time

    MetricsAppSnapshot:
      type: object
      required: [appId]
      properties:
        appId:
          type: string
        health:
          $ref: '#/components/schemas/HealthDoc'
        metrics:
          type: object
          nullable: true
          additionalProperties: true
          description: Free-form kind=metric payload; no fixed keys
        metricsReportedAt:
          type: string
          format: date-time
          nullable: true
        # ── Extensions for multi-instance (LogPulse Phase 18) ─────────────
        instanceCount:
          type: integer
          minimum: 0
          description: |
            Distinct instanceIds with health or metric docs in instanceWindowSeconds.
            Omit or null if not computed (LogPulse hides badge).
        instances:
          type: array
          description: Optional per-instance breakdown; LogPulse may ignore until drill-down UI exists
          items:
            $ref: '#/components/schemas/InstanceSnapshot'

    InstanceSnapshot:
      type: object
      required: [instanceId, lastSeen]
      properties:
        instanceId:
          type: string
        lastSeen:
          type: string
          format: date-time
        status:
          type: string
        uptimeSeconds:
          type: integer
          minimum: 0

    MetricsListResponse:
      type: object
      required: [success, data]
      properties:
        success:
          type: boolean
        data:
          type: array
          items:
            $ref: '#/components/schemas/MetricsAppSnapshot'
```

**LogPulse after this ships**

- Map `instanceCount` in `parseServiceMetricsResponse` (field already on DTO/model; currently forced null).
- Do **not** set `instanceCount` from presence of `health.instanceId`.

#### 3.2.2 Health status vocabulary (document + enforce)

```yaml
components:
  schemas:
    HealthStatus:
      type: string
      description: |
        Canonical vocabulary for health.status (reportHealth + read API).
        LogPulse today: "ok" → healthy; any other non-null → degraded.
        Prefer sticking to this enum so clients can map colors accurately.
      enum:
        - ok          # process healthy
        - degraded    # running but impaired (optional elevation from "other")
        - error       # unhealthy / failing checks
        - starting    # optional warm-up
        - stopping    # optional drain
      example: ok
```

**Ask for CLS:** validate on write; document in `METRICS_READ_CONTRACT.md`.

---

### 3.3 P1 — Per-service request aggregates (err% / latency)

**Why:** `ServiceHealthCard` full numeric line and `hasHealthMetrics` need `errorRate`, `avgLatency`, and optionally percentage `uptime` / `errorCount`. Logs summary `byService` is counts-only today.

**Preferred approach:** enrich existing summary (minimal new surface).

#### Option A — Extend `GET /api/v1/logs/stats/summary` (recommended)

```yaml
paths:
  /api/v1/logs/stats/summary:
    get:
      operationId: getLogsStatsSummary
      summary: Aggregate log stats (global + per service)
      tags: [Logs Stats]
      security:
        - ApiKeyAuth: []
      parameters:
        - name: timeRange
          in: query
          schema:
            type: string
            enum: [last_hour, last_24h, last_7d, last_30d]
            default: last_24h
        - name: service
          in: query
          schema:
            type: string
      responses:
        '200':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/LogsStatsSummaryResponse'
              examples:
                withPerService:
                  value:
                    success: true
                    data:
                      totalLogs: 1520
                      errorRate: "2.50"          # existing: string or number
                      avgDuration: 42
                      byLevel:
                        info: 1200
                        warn: 80
                        error: 40
                      byStatusCode:
                        "200": 1400
                        "500": 40
                      # ── EXISTING shape LogPulse already reads ────────────
                      # byService used to be { "svc": <count:int> } only.
                      # NEW: allow object values (backward-compatible if you
                      # keep accepting bare ints for old clients).
                      byService:
                        academicx:
                          totalRequests: 800
                          errorCount: 12
                          errorRate: 1.5
                          avgDuration: 38
                        payments-api:
                          totalRequests: 720
                          errorCount: 28
                          errorRate: 3.9
                          avgDuration: 51

components:
  schemas:
    ServiceStatsBucket:
      oneOf:
        - type: integer
          description: Legacy — request count only
          minimum: 0
        - type: object
          required: [totalRequests]
          properties:
            totalRequests:
              type: integer
              minimum: 0
            errorCount:
              type: integer
              minimum: 0
            errorRate:
              type: number
              description: Percentage 0–100 (same unit as global errorRate)
            avgDuration:
              type: number
              description: Mean duration ms (LogPulse field avgLatency)
            # Optional — only if you can define it honestly
            uptimePercent:
              type: number
              description: Do not invent; omit if unknown

    LogsStatsSummaryData:
      type: object
      properties:
        totalLogs:
          type: integer
        errorRate:
          oneOf:
            - type: number
            - type: string
        avgDuration:
          type: number
        byLevel:
          type: object
          additionalProperties:
            type: integer
        byStatusCode:
          type: object
          additionalProperties:
            type: integer
        byService:
          type: object
          additionalProperties:
            $ref: '#/components/schemas/ServiceStatsBucket'

    LogsStatsSummaryResponse:
      type: object
      required: [success, data]
      properties:
        success:
          type: boolean
        data:
          $ref: '#/components/schemas/LogsStatsSummaryData'
```

**LogPulse after Option A**

- Update `DashboardStats.fromApiJson` to read object-shaped `byService` values into `ServiceStats.errorRate` / `avgLatency` / `errorCount`.
- Keep null when only a bare int is present (honest “no per-service rates yet”).

#### Option B — Dedicated route (if summary must stay tiny)

```yaml
paths:
  /api/v1/logs/stats/by-service:
    get:
      operationId: getLogsStatsByService
      summary: Per-service request aggregates for a time window
      tags: [Logs Stats]
      security:
        - ApiKeyAuth: []
      parameters:
        - name: timeRange
          in: query
          schema:
            type: string
            enum: [last_hour, last_24h, last_7d, last_30d]
            default: last_24h
      responses:
        '200':
          content:
            application/json:
              schema:
                type: object
                required: [success, data]
                properties:
                  success:
                    type: boolean
                  data:
                    type: array
                    items:
                      type: object
                      required: [service, totalRequests]
                      properties:
                        service:
                          type: string
                        totalRequests:
                          type: integer
                        errorCount:
                          type: integer
                        errorRate:
                          type: number
                        avgDuration:
                          type: number
```

Prefer **Option A** unless payload size is a hard constraint.

---

### 3.4 P1 — Log list total count

**Why:** Logs page “N results” uses client page length.

```yaml
paths:
  /api/v1/logs:
    get:
      operationId: getLogs
      # ...existing query params: service, level, statusCode, from, to, limit, skip, search, traceId
      responses:
        '200':
          content:
            application/json:
              schema:
                oneOf:
                  - type: array
                    description: Legacy bare list (no total)
                    items:
                      type: object
                  - type: object
                    required: [success, data]
                    properties:
                      success:
                        type: boolean
                      data:
                        type: array
                        items:
                          type: object
                      # ── NEW ────────────────────────────────────────────
                      total:
                        type: integer
                        minimum: 0
                        description: Total matching documents (not page size)
                      meta:
                        type: object
                        properties:
                          limit:
                            type: integer
                          skip:
                            type: integer
```

**LogPulse:** Prefer envelope with `total`; fall back to page length if absent.

---

### 3.5 P2 — Server-side error groups

**Why:** Errors tab groups only whatever log pages were loaded client-side.

```yaml
paths:
  /api/v1/logs/errors/groups:
    get:
      operationId: getErrorGroups
      summary: Fingerprinted error groups over a time window
      tags: [Logs]
      security:
        - ApiKeyAuth: []
      parameters:
        - name: timeRange
          in: query
          schema:
            type: string
            enum: [last_hour, last_24h, last_7d, last_30d]
            default: last_24h
        - name: service
          in: query
          schema:
            type: string
        - name: limit
          in: query
          schema:
            type: integer
            default: 50
            maximum: 200
      responses:
        '200':
          content:
            application/json:
              schema:
                type: object
                required: [success, data]
                properties:
                  success:
                    type: boolean
                  data:
                    type: array
                    items:
                      $ref: '#/components/schemas/ErrorGroup'

components:
  schemas:
    ErrorGroup:
      type: object
      required: [id, message, count, firstSeen, lastSeen]
      properties:
        id:
          type: string
          description: Stable fingerprint (hash of normalized message / code)
        message:
          type: string
        errorCode:
          type: string
          nullable: true
        count:
          type: integer
          minimum: 1
        services:
          type: array
          items:
            type: string
        firstSeen:
          type: string
          format: date-time
        lastSeen:
          type: string
          format: date-time
        sampleStack:
          type: string
          nullable: true
        sampleTraceId:
          type: string
          nullable: true
        trend:
          type: string
          enum: [increasing, decreasing, stable]
```

Aligns with LogPulse `ErrorGroup` model (`id`, `message`, `errorCode`, `count`, `services`, `firstSeen`, `lastSeen`, `stackTrace`, `trend`).

---

### 3.6 P2 — Services catalog (optional, unlocks Service Details)

```yaml
paths:
  /api/v1/services:
    get:
      operationId: listServices
      summary: Known services/apps with rollups
      tags: [Services]
      security:
        - ApiKeyAuth: []
      parameters:
        - name: timeRange
          in: query
          schema:
            type: string
            enum: [last_hour, last_24h, last_7d, last_30d]
            default: last_24h
      responses:
        '200':
          content:
            application/json:
              schema:
                type: object
                required: [success, data]
                properties:
                  success:
                    type: boolean
                  data:
                    type: array
                    items:
                      $ref: '#/components/schemas/ServiceSummary'

  /api/v1/services/{name}:
    get:
      operationId: getService
      parameters:
        - name: name
          in: path
          required: true
          schema:
            type: string
        - name: timeRange
          in: query
          schema:
            type: string
            enum: [last_hour, last_24h, last_7d, last_30d]
      responses:
        '200':
          content:
            application/json:
              schema:
                type: object
                required: [success, data]
                properties:
                  success:
                    type: boolean
                  data:
                    $ref: '#/components/schemas/ServiceDetail'
        '404':
          description: Unknown service

components:
  schemas:
    ServiceSummary:
      type: object
      required: [name, totalRequests]
      properties:
        name:
          type: string
        displayName:
          type: string
        totalRequests:
          type: integer
        errorRate:
          type: number
        avgLatency:
          type: number
        lastSeen:
          type: string
          format: date-time
        instanceCount:
          type: integer

    EndpointStats:
      type: object
      required: [path, method, requestCount]
      properties:
        path:
          type: string
        method:
          type: string
        requestCount:
          type: integer
        errorRate:
          type: number
        avgLatency:
          type: number
        errorCount:
          type: integer

    ServiceDetail:
      allOf:
        - $ref: '#/components/schemas/ServiceSummary'
        - type: object
          properties:
            endpoints:
              type: array
              items:
                $ref: '#/components/schemas/EndpointStats'
            health:
              $ref: '#/components/schemas/HealthDoc'
            metrics:
              type: object
              additionalProperties: true
```

Maps cleanly to unused LogPulse `Service` / `EndpointStats` models if you keep them.

---

### 3.7 P2 — Optional request stage timings (Timeline tab)

Only if product wants real performance breakdowns. Do **not** implement Timeline fabrication again on the client.

```yaml
# Embed on log documents returned by GET /api/v1/logs
components:
  schemas:
    LogEntryExtensions:
      type: object
      properties:
        stages:
          type: array
          description: Ordered server-side spans for this request
          items:
            type: object
            required: [name, durationMs]
            properties:
              name:
                type: string
                example: db_query
              durationMs:
                type: integer
                minimum: 0
              startedAtMs:
                type: integer
                description: Offset from request start
```

---

### 3.8 Shared security scheme (for the full OpenAPI file)

```yaml
components:
  securitySchemes:
    ApiKeyAuth:
      type: apiKey
      in: header
      name: X-API-Key
      description: |
        Flat read key used by LogPulse for /logs and /metrics GET.
        Distinct from per-app metrics write keys (sk_live_ / sk_test_).

  responses:
    Unauthorized:
      description: Missing or invalid API key
      content:
        application/json:
          schema:
            type: object
            properties:
              success:
                type: boolean
                example: false
              message:
                type: string
    ServerError:
      description: Internal error
      content:
        application/json:
          schema:
            type: object
            properties:
              success:
                type: boolean
                example: false
              message:
                type: string
```

---

## 4. Cross-repo priority board

| Order | ID | Owner | Deliverable |
|------|-----|-------|-------------|
| ✅ | **CLS-TS** | CLS | `GET /logs/stats/timeseries` — shipped |
| ✅ | **CLS-IC** | CLS | `instanceCount` + `instances[]` on `GET /metrics` — shipped |
| ✅ | **CLS-HV** | CLS | Health status write-validated + docs — shipped |
| ✅ | **LP-15/16/19** | LP | Timeseries verify, instanceCount parse, full health map — done |
| ✅ | **CLS-PS** | CLS | Per-service err%/latency on summary `byService` — shipped |
| ✅ | **CLS-TC** | CLS | Log list `total` envelope — shipped |
| ✅ | **LP-17 / LP-13** | LP | Object byService + logs total consumers — done |
| **1 (next)** | **LP-08** | LP | Wire auto-refresh |
| 2 | **LP-03** | LP | Recent errors navigation |
| 3 | **CLS-EG** | CLS | Error groups API (§3.5) |
| 4 | **LP-cleanup** | LP | Docs, dead code, analyze, tests (LP-20–26) |
| 5 | **CLS-SV** | CLS | Services catalog (§3.6) → then LP service details |
| 6 | **CLS-ST** | CLS | Optional stage timings (§3.7) |

---

## 5. Explicit non-goals

- Do **not** wire LogPulse to `@bevingh/telemetry` (write client only).  
- Do **not** set `instanceCount` from a single `instanceId`.  
- Do **not** reintroduce fabricated Timeline stages or 100% uptime.  
- Do **not** make `ApiService.getServiceMetrics` swallow all errors — repository isolation (Phase 21) is intentional.  
- Do **not** remove timeseries client fallback until real endpoint is stable in prod.

---

## 6. How to use this doc

**For central-logging-service work:** copy §3.1 and §3.2 into a CLS PR / `docs/OPENAPI_READ_EXTENSIONS.md` and implement in that order. Field names are aligned with LogPulse parsers where possible.

**For LogPulse work:** pick IDs from §2; when a CLS item lands, tick the matching LP consumer (LP-15–17, LP-11, LP-13, LP-05).

**When closing an item:** append a short note to `log.md` and mark the row done here (or move to a “Completed” section at the bottom).

---

## 7. Completed recently (do not re-open)

| Phase | What |
|-------|------|
| 16 | Metrics DTO, parser, merge, chips UI, tests |
| 18 | `instanceCount` field + badge UI |
| 20 | PR-24 path/shape reconcile, three-state health card |
| 21 | Metrics fetch isolation in `DashboardRepository.getStats` |
| **LP P0 consumers** | `parseTimeSeriesResponse` public + CLS fixture tests; parse top-level `instanceCount`; full health vocab map (`error`→unhealthy); 404 timeseries fallback retained |
| **LP P1 consumers** | Object `byService` → err%/latency/errorCount; `hasHealthMetrics` no longer requires uptime %; `LogsPageResult` + `total`/`hasMore`; card detail line combines numerics + uptimeSeconds |
| Earlier | Fabrication audit (null health, honest timeline) |

---

*Last updated: 2026-07-21 — LP P1 consumers after CLS P1 summary/total landed.*
