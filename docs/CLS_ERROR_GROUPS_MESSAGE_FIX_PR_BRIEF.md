# CLS PR — Fix error-groups message extraction

Copy-paste ready for `central-logging-service`.  
**Bug:** `GET /api/v1/logs/errors/groups` collapses real failures into a single `"Unknown error"` megagroup.

**Auth:** unchanged — flat `X-API-Key` (same as other log GETs).  
**Contract:** response envelope and field names stay the same; only message / fingerprint / sample enrichment improve.

---

## Title

```
fix(api): extract error-group message from response.body (stop Unknown error megagroup)
```

---

## Summary

| | |
|---|---|
| **Symptom (prod)** | Errors tab shows **1 group**, message **`Unknown error`**, count **~247**, services merged |
| **Root cause** | Group fingerprint uses top-level `error.message` / `error.code` only. Producer services leave `error: null` and put the real text in **`response.body`** (JSON string or object). |
| **Impact** | Fingerprints collide → one megagroup; LogPulse cannot show distinct errors, trends, or useful Find Similar queries |
| **Fix** | Shared **display-message** resolver (same priority as LogPulse `LogEntry.displayError`) used for **fingerprint**, **`message`**, and optional **`errorCode` / `sampleStack`** |

**Out of scope:** new query params; changing `timeRange` semantics; LogPulse client workarounds; OpenAPI version bump unless you document optional `sampleStatusCode`.

---

## Evidence (live, 2026-07-21)

### Groups API (broken)

```http
GET /api/v1/logs/errors/groups?limit=10
```

```json
{
  "success": true,
  "data": [
    {
      "id": "fp_ea9d3a1bc650",
      "message": "Unknown error",
      "errorCode": null,
      "count": 247,
      "services": [
        "academicx-api",
        "fyp-management-backend",
        "payment-gateway-api"
      ],
      "sampleStack": null,
      "sampleTraceId": "54693b2d-158c-4708-91bb-10b8298de846",
      "trend": "increasing"
    }
  ]
}
```

### Raw error logs (same backend) — message is elsewhere

Top-level `error` is **null** on sampled rows. Real text lives in `response.body`:

| Example `response.body` (parsed) | Expected group `message` |
|----------------------------------|---------------------------|
| `{"success":false,"error":{"message":"Empty file","statusCode":500}}` | `Empty file` |
| `{"success":false,"message":"this.database.isConnected is not a function","error":"Internal Server Error"}` | `this.database.isConnected is not a function` |
| `{"success":false,"error":{"message":"connect ECONNREFUSED …","statusCode":500,"stack":"…"}}` | `connect ECONNREFUSED …` (+ `sampleStack` from `stack`) |

When the same extraction is applied client-side to a page of `level=error` logs, distinct messages appear (e.g. header Content-Disposition errors, missing `exceljs`, Mongo ECONNREFUSED) — **not** one “Unknown error”.

### Spec mismatch

P2 brief already said:

> Fingerprint = hash(normalize(`error.message` **or response message**) + optional `error.code`)

Implementation only did the first half. This PR completes the rule.

---

## Required behavior

### 1. Message extraction (canonical)

Implement once (e.g. `extractErrorDisplay(log) → { message, errorCode?, stack? }`) and reuse for grouping + samples.

**Priority order:**

1. **Top-level structured error**  
   - `log.error.message` (non-empty string)  
   - `log.error.code` → `errorCode` when present  
   - `log.error.stack` → candidate for `sampleStack`

2. **`response.body` (string or object)**  
   - If string: try `JSON.parse`; on failure treat raw string as message only if short / non-HTML (optional guard).  
   - If object / parsed map, in order:
     - `body.error.message` (when `error` is object)
     - `body.message`
     - `body.error` when it is a **string** (e.g. `"Internal Server Error"`) — prefer earlier keys if both exist; prefer specific `error.message` over generic `"Internal Server Error"` when both present
     - `body.error.code` / `body.code` / `body.statusCode` (only if 4xx/5xx integer or short code string) for `errorCode`
     - `body.error.stack` / `body.stack` for `sampleStack`

3. **HTTP fallback** (never invent `"Unknown error"` when status is known)  
   - `HTTP ${statusCode}` if `statusCode != null`  
   - Else `"Error"` (or keep a single documented sentinel only when **no** status and **no** body text)

4. **Normalize before fingerprint**  
   - Trim  
   - Collapse whitespace / newlines to single spaces for fingerprint only (display message may keep a truncated multi-line first line)  
   - Cap display `message` length (e.g. 500 chars); fingerprint on normalized form (e.g. first 200 chars) for stability  
   - Optional: strip volatile tokens (UUIDs, ObjectIds, IPs, ports) for fingerprint **only** — document if you do this so counts stay stable across similar connection errors

**Do not** default fingerprint key to the literal string `"Unknown error"` when steps 1–3 yield anything else.

### 2. Fingerprint

```
id = "fp_" + shortHash(normalize(message) + "\0" + (errorCode ?? ""))
```

Same algorithm as today is fine; **inputs** must use the extracted message/code above.

### 3. Group inclusion (unchanged intent)

Continue counting logs that match LogPulse `isError`:

- `level === 'error'` **or**
- `statusCode >= 400`

Document which rule you use if it differs.

### 4. Group fields after fix

| Field | Change |
|-------|--------|
| `message` | Real extracted text (not megagroup placeholder) |
| `errorCode` | From top-level or body when available (`ECONNREFUSED`, `404`, etc.) |
| `sampleStack` | Prefer top-level stack; else body stack |
| `sampleTraceId` | Unchanged (any representative log in the group) |
| `count` / `services` / `firstSeen` / `lastSeen` / `trend` | Same semantics; **counts split across real fingerprints** |

### 5. Optional additive field (nice-to-have, not required)

```json
"sampleStatusCode": 500
```

Helps LogPulse 5xx/4xx summary cards without client-side guessing. If omitted, clients keep inferring from code/message.

---

## Expected response shape (after fix)

Same envelope as P2. Example for the same traffic pattern:

```json
{
  "success": true,
  "data": [
    {
      "id": "fp_…",
      "message": "connect ECONNREFUSED 65.62.2.172:27017",
      "errorCode": null,
      "count": 3,
      "services": ["fyp-management-backend"],
      "firstSeen": "2026-07-21T00:16:45.095Z",
      "lastSeen": "2026-07-21T23:06:37.210Z",
      "sampleStack": "MongoServerSelectionError: connect ECONNREFUSED …",
      "sampleTraceId": "…",
      "trend": "stable"
    },
    {
      "id": "fp_…",
      "message": "Empty file",
      "errorCode": null,
      "count": 1,
      "services": ["fyp-management-backend"],
      "firstSeen": "…",
      "lastSeen": "…",
      "sampleStack": null,
      "sampleTraceId": "…",
      "trend": "stable"
    }
  ]
}
```

Multiple groups, distinct messages, no single `"Unknown error"` bucket for body-only failures.

---

## Acceptance criteria

- [ ] Fixtures with **`error: null`** + JSON `response.body.error.message` produce a group whose `message` equals that string (not `"Unknown error"`).
- [ ] Fixture with only `response.body.message` (string) groups on that message.
- [ ] Fixture with only top-level `error.message` still works (regression).
- [ ] Fixture with neither message nor body, but `statusCode: 502` → message like `HTTP 502` (not `"Unknown error"`).
- [ ] Two different body messages → **two** groups (fingerprints differ).
- [ ] Same message across two services → **one** group, `services` length 2, `count` summed.
- [ ] `sampleStack` populated when body includes `error.stack`.
- [ ] Empty window still `{ success: true, data: [] }`.
- [ ] Unit tests for extractor + fingerprint stability (normalize / trim / length cap).
- [ ] Manual check against prod traffic: groups list is multi-row when distinct body messages exist.

---

## Test plan (CLS)

1. **Unit — extractor**
   - Body shapes from academicx / fyp samples above.
   - Nested `error: { message, statusCode, stack }`.
   - Flat `message` + string `error`.
   - Non-JSON body string.
   - Empty body + status only.

2. **Unit — grouping**
   - N logs, 3 message classes → 3 groups with correct counts.
   - Fingerprint stable across reordering of the same inputs.

3. **Integration (optional)**
   - Seed Mongo/Firestore with body-only error docs → hit `GET /logs/errors/groups` → assert multi-group response.

4. **Regression**
   - Logs that already use top-level `error` still group correctly.
   - Auth 401 without key unchanged.

---

## LogPulse impact (no required app change)

After deploy:

| Before | After |
|--------|--------|
| 1 × “Unknown error” (247) | Distinct groups with real messages |
| Find Similar searches `"Unknown error"` | Searches useful message text |
| sampleStack always null for body-only | Stack when present in body |
| 5xx/4xx cards weak without status | Better if messages/`errorCode` carry HTTP class; best with optional `sampleStatusCode` |

LogPulse already shows `group.message` as returned. No client hotfix required for the megagroup once CLS ships this.

---

## Suggested commit / PR description

```
fix(api): extract error group messages from response.body

Producers log failures in response.body with top-level error null.
Groups only read error.message, so every row fingerprinted as
"Unknown error" and collapsed into one megagroup.

Add shared extractErrorDisplay() matching LogPulse displayError
priority (error.message → response.body → HTTP status). Use it for
fingerprint, message, errorCode, and sampleStack.

Fixes LogPulse Errors tab showing a single Unknown error group.
```

---

## Implementation checklist (CLS)

- [ ] Locate current groups route / aggregation (fingerprint + message assignment)
- [ ] Add `extractErrorDisplay` (or equivalent) with unit tests
- [ ] Wire extractor into fingerprint + group payload fields
- [ ] Drop / stop using literal `"Unknown error"` except as last-resort when nothing else exists
- [ ] Verify on staging with real academicx / fyp traffic
- [ ] Deploy; spot-check LogPulse Errors tab

---

## Related

- Original contract: `docs/CLS_P2_PR_BRIEF.md` §1 (grouping rule)
- OpenAPI: `docs/CLS_READ_API_EXTENSIONS.openapi.yaml` → `/logs/errors/groups`
- Consumer display parity: LogPulse `LogEntry.displayError` (`lib/data/models/log_entry.dart`)
- Consumer group model: `ErrorGroup.fromApiJson` (`lib/data/models/error_group.dart`)
