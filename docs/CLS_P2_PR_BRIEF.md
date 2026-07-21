# CLS PR — P2 Read API (for `central-logging-service`)

Copy-paste ready. **After P0 + P1**, these unlock a better Errors tab and a real Service Details surface in LogPulse.

**Auth:** same flat `X-API-Key` as log GETs (not per-app metrics write keys).

---

## Title

```
feat(api): P2 read routes — error groups + services catalog
```

---

## Summary

| # | Deliverable | LogPulse benefit |
|---|-------------|------------------|
| 1 | `GET /api/v1/logs/errors/groups` | Errors tab stops depending on partial client-side log pages |
| 2 | `GET /api/v1/services` | List of known services with rollups |
| 3 | `GET /api/v1/services/{name}` | Service detail page (endpoint rollups + latest health/metrics) |

**Out of scope:** stage timings / timeline spans (P3); webhooks/notifications.

---

## 1. `GET /api/v1/logs/errors/groups`

### Query

| Param | Default | Notes |
|-------|---------|--------|
| `timeRange` | `last_24h` | `last_hour` \| `last_24h` \| `last_7d` \| `last_30d` — unknown → 400 |
| `service` | — | optional filter |
| `limit` | `50` | max 200 |

### Response

```json
{
  "success": true,
  "data": [
    {
      "id": "fp_a1b2c3",
      "message": "Connection refused to redis",
      "errorCode": "ECONNREFUSED",
      "count": 47,
      "services": ["academicx", "payments-api"],
      "firstSeen": "2026-07-21T08:00:00.000Z",
      "lastSeen": "2026-07-21T12:30:00.000Z",
      "sampleStack": "Error: ...\n    at ...",
      "sampleTraceId": "trace-abc",
      "trend": "increasing"
    }
  ]
}
```

| Field | Required | Notes |
|-------|----------|--------|
| `id` | yes | Stable fingerprint (hash of normalized message ± code) |
| `message` | yes | Display message |
| `errorCode` | no | From error.code when present |
| `count` | yes | Occurrences in window |
| `services` | yes | Distinct service names (array, may be empty) |
| `firstSeen` / `lastSeen` | yes | ISO-8601 UTC |
| `sampleStack` | no | One representative stack |
| `sampleTraceId` | no | One representative trace for deep-link |
| `trend` | no | `increasing` \| `decreasing` \| `stable` — compare recent vs earlier half of window |

### Grouping rule (recommended)

Fingerprint = hash(normalize(`error.message` or response message) + optional `error.code`).  
Count all logs with `level === 'error'` **or** `statusCode >= 400` in the window (document which rule you pick; prefer matching LogPulse `LogEntry.isError`).

### Acceptance

- [ ] Empty window → `{ success: true, data: [] }`
- [ ] Sorted by `lastSeen` desc (or document sort)
- [ ] Auth 401 without key
- [ ] Unit tests for fingerprint stability + count

---

## 2. `GET /api/v1/services`

### Query

| Param | Default |
|-------|---------|
| `timeRange` | `last_24h` |

### Response

```json
{
  "success": true,
  "data": [
    {
      "name": "academicx",
      "displayName": "AcademicX",
      "totalRequests": 800,
      "errorRate": 1.5,
      "avgLatency": 38,
      "lastSeen": "2026-07-21T12:01:00.000Z",
      "instanceCount": 3
    }
  ]
}
```

| Field | Source |
|-------|--------|
| `name` | log.service / appId |
| `totalRequests` / `errorRate` / `avgLatency` | same semantics as summary `byService` (ms for latency) |
| `lastSeen` | max timestamp from logs **or** latest metrics/health |
| `instanceCount` | same window logic as metrics `instanceCount` when available; omit/null if unknown |

### Acceptance

- [ ] Includes services that only report metrics (no logs) **or** document logs-only — prefer **union** of log services + metrics appIds
- [ ] Sorted by `totalRequests` desc or `lastSeen` desc (document)

---

## 3. `GET /api/v1/services/{name}`

### Query

| Param | Default |
|-------|---------|
| `timeRange` | `last_24h` |

### Response

```json
{
  "success": true,
  "data": {
    "name": "academicx",
    "displayName": "AcademicX",
    "totalRequests": 800,
    "errorRate": 1.5,
    "avgLatency": 38,
    "lastSeen": "2026-07-21T12:01:00.000Z",
    "instanceCount": 3,
    "endpoints": [
      {
        "path": "/v1/students",
        "method": "GET",
        "requestCount": 400,
        "errorRate": 0.5,
        "avgLatency": 30,
        "errorCount": 2
      }
    ],
    "health": {
      "status": "ok",
      "instanceId": "rev-abc",
      "uptimeSeconds": 86400,
      "timestamp": "2026-07-21T12:00:00.000Z"
    },
    "metrics": {
      "students": 120,
      "activeToday": 45
    },
    "instances": [
      {
        "instanceId": "rev-abc",
        "lastSeen": "2026-07-21T12:00:00.000Z",
        "status": "ok",
        "uptimeSeconds": 86400
      }
    ]
  }
}
```

- `404` if name unknown (no logs and no metrics for that id).
- `endpoints`: top N by requestCount (e.g. 20); group by method+path.
- `health` / `metrics` / `instances`: same shapes as `GET /metrics` for that appId (may be null / []).

### Acceptance

- [ ] 404 for unknown name
- [ ] Endpoints aggregate matches raw logs for a fixture
- [ ] Reuses metrics snapshot helpers (no divergent health shape)

---

## Test plan (CLS)

1. Seed mixed errors across services → groups count/fingerprint.  
2. Seed multi-instance metrics + logs → services list has instanceCount.  
3. GET service detail for one name → endpoints + health + metrics.  
4. Auth: missing key → 401 on all three.

---

## LogPulse follow-up (after you merge)

1. `ErrorsNotifier` → call groups API instead of client-side grouping (keep fallback).  
2. Rebuild `Service` model + service details page from catalog routes.  
3. Optional: deep-link from group `sampleTraceId` to log search.

---

## References

- Full backlog: `logpulse_analytics/BACKLOG.md` §3.5–3.6  
- OpenAPI draft: `logpulse_analytics/docs/CLS_READ_API_EXTENSIONS.openapi.yaml`  
- Existing contracts: timeseries, metrics, summary `byService` objects, logs `total`
