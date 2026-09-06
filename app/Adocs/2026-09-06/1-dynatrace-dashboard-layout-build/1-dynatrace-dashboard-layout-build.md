# Dynatrace Dashboard Layout Build

```
Build this board?
  │
  ├─ Row 1  → Variables / filters (All, EIP, API, Payment…)
  ├─ Rows 2–3 → Problems + Davis root cause + alert summary
  ├─ Rows 4–5 → Requests / Errors / Response time
  ├─ Rows 6–7 → Windows CPU / Linux CPU / Memory
  ├─ Rows 8–9 → Error logs / Exception traces
  ├─ Rows 10–11 → DB connections / Queries / External services
  └─ Every data tile → filter by the same app variable (never mix apps)
```

| Question | Answer |
| --- | --- |
| What the picture is | A **row blueprint** for one Dynatrace dashboard |
| How many rows | **11** (1 filter + 5 section headers + 5 metric rows) |
| Build order | Shell → variables → headers → data tiles top to bottom |
| App chips | `All` / `EIP` / `API` / `Payment` (extend as needed) |
| Safe start | Tag entities `app:eip` etc., or use Management Zone + dashboard variable |

## Summary

This guide turns your **DASHBOARD LAYOUT VISUAL** into a real Dynatrace dashboard. Read it top-down like an L1 screen: **pick an app → see critical problems → check golden signals → hosts → logs → DB/deps**. Section title rows are Markdown only; metric rows are charts/tables/Problems/Logs tiles, all filtered by the same application selector.

---

## What each row means (beginner)

| Row | On the picture | What it is | Why you care |
| --- | --- | --- | --- |
| 1 | APPLICATION SELECTOR \| [All][EIP][API][Payment]… | Global filter | One click changes **every** tile below |
| 2 | CRITICAL ALERTS & AI ROOT CAUSE | Section title | Tells L1 “alerts live here” |
| 3 | Problems \| Root Cause \| Alert Summary | Live alert tiles | Fast answer: what broke, why Davis thinks so |
| 4 | APPLICATION PERFORMANCE METRICS | Section title | App golden signals |
| 5 | Requests \| Errors \| Response Time | Three KPI charts | Traffic, failures, latency |
| 6 | INFRASTRUCTURE STATUS | Section title | Hosts under the app |
| 7 | Windows CPU \| Linux CPU \| Memory | Host resource tiles | Is the box sick? |
| 8 | LOGS & ERRORS | Section title | Log deep dive |
| 9 | Error Logs \| Exception Traces | Log / exception views | Evidence for RCA |
| 10 | DATABASE & DEPENDENCIES | Section title | Backend health |
| 11 | DB Connections \| Queries \| External Services | DB + outbound calls | Slow DB or bad dependency? |

---

## Prerequisites (do once)

| Step | What to do | Pass means |
| --- | --- | --- |
| 1 | Apps/services exist in Dynatrace (OneAgent or OpenTelemetry) | Services show request metrics |
| 2 | Tag each app family | e.g. `app:eip`, `app:api`, `app:payment` (or use service name contains) |
| 3 | Optional Management Zone per env | `MZ-STG` / `MZ-PROD` so you do not mix prod |
| 4 | Logs ingested for those services | Logs UI returns ERROR lines |
| 5 | DB / external calls visible in service flow | Called databases / services exist |

---

## Step-by-step build in Dynatrace UI

### Step A — Create the shell

1. **Dashboards** → **Create dashboard**
2. Name: `App-Health-Layout` (or `App-Health-STG` if staging only)
3. Default timeframe: **Last 2 hours**
4. Save once

### Step B — Row 1: Application selector (variables)

**What this is:** A dashboard **variable** so every tile can say “only this app.”

1. Dashboard **Edit** → **Variables** (or Settings → Variables, wording varies by Dashboards Classic vs new Dashboards)
2. Add variable:
   - Name: `app`
   - Type: list / free-text / entity filter (use what your tenant supports)
   - Values: `All`, `EIP`, `API`, `Payment` (add more chips to match your estate)
3. On every data tile, filter with:
   - Tag `app:$app` when `$app` ≠ `All`
   - Or entity name contains `$app`
   - When `All`: no app tag filter (still keep env filter if you have one)

**Markdown strip for Row 1 (optional visual):**

```text
## APPLICATION SELECTOR
Use variable **app** = All | EIP | API | Payment
All tiles below must honor this filter.
```

### Step C — Rows 2–3: Critical alerts & AI root cause

**Row 2 — Markdown header**

```text
## CRITICAL ALERTS & AI ROOT CAUSE
Open problems · Davis root cause · short alert summary
```

**Row 3 — three tiles side by side**

| Tile | Dynatrace tile type | What to configure |
| --- | --- | --- |
| **Problems** | Problems list / Problems chart | Open problems; severity Critical+Error; filter by `$app` / MZ |
| **Root Cause** | Problems detail / Markdown link to Problems | Show Davis root-cause entity if available; or “Open selected problem → Root cause” shortcut text |
| **Alert Summary** | Single value / chart | Count of open problems by severity (Critical / Error / Warning) |

**Beginner pass:** With no incidents, Problems = 0 and summary bars are empty/green. After a known STG failure, Problems gets a row and Root Cause names a service/host.

### Step D — Rows 4–5: Application performance metrics

**Row 4 — Markdown**

```text
## APPLICATION PERFORMANCE METRICS
Requests · Errors · Response time (golden signals)
```

**Row 5 — three charts**

| Tile | Metric idea (classic / Data explorer) | Chart |
| --- | --- | --- |
| **Requests** | Service request count / throughput | Timeseries |
| **Errors** | Failure rate `%` or failed request count | Timeseries |
| **Response Time** | Response time (prefer P50 + P90 if available) | Timeseries |

Filter each chart to services tagged with `$app` (or selected service entity list).

### Step E — Rows 6–7: Infrastructure status

**Row 6 — Markdown**

```text
## INFRASTRUCTURE STATUS
Hosts behind the selected application
```

**Row 7 — three charts**

| Tile | Filter | Metric |
| --- | --- | --- |
| **Windows CPU** | Hosts OS = Windows + related to `$app` | CPU usage `%` |
| **Linux CPU** | Hosts OS = Linux + related to `$app` | CPU usage `%` |
| **Memory** | Same host set | Memory used `%` |

If you cannot split OS cleanly on day one: one **CPU** + one **Memory** tile is OK; keep the Windows/Linux split as a follow-up.

### Step F — Rows 8–9: Logs & errors

**Row 8 — Markdown**

```text
## LOGS & ERRORS
Error lines and exception traces for the selected app
```

**Row 9 — two tiles**

| Tile | Type | Query idea |
| --- | --- | --- |
| **Error Logs** | Logs table / chart | `status="ERROR"` (plus app/service filter) |
| **Exception Traces** | Logs or PurePath/exceptions view | content contains `Exception` / stack traces; or Errors & Exceptions explorer link |

Mask PII in queries if your org requires it (do not put customer IDs in shared boards).

### Step G — Rows 10–11: Database & dependencies

**Row 10 — Markdown**

```text
## DATABASE & DEPENDENCIES
DB pool health · query time · outbound / external calls
```

**Row 11 — three tiles**

| Tile | What to pin |
| --- | --- |
| **DB Connections** | Database / connection pool metric, or called DB service throughput |
| **Queries** | DB response time / query time / slow query count |
| **External Services** | Top called services / HTTP backends by error rate or latency (from service flow) |

---

## Layout map (match the picture)

```
Row1  [ APPLICATION SELECTOR | All | EIP | API | Payment | … ]
Row2  [ CRITICAL ALERTS & AI ROOT CAUSE                      ]
Row3  [ Problems ] [ Root Cause ] [ Alert Summary ]
Row4  [ APPLICATION PERFORMANCE METRICS                     ]
Row5  [ Requests ] [ Errors ] [ Response Time ]
Row6  [ INFRASTRUCTURE STATUS                               ]
Row7  [ Windows CPU ] [ Linux CPU ] [ Memory ]
Row8  [ LOGS & ERRORS                                       ]
Row9  [ Error Logs ] [ Exception Traces ]
Row10 [ DATABASE & DEPENDENCIES                             ]
Row11 [ DB Connections ] [ Queries ] [ External Services ]
```

In the editor: put **full-width Markdown** on even header rows; put **equal-width tiles** on metric rows (3-up or 2-up as drawn).

---

## Suggested tile sizes

| Row type | Width hint |
| --- | --- |
| Selector / section headers (1,2,4,6,8,10) | Full width |
| Triple metric rows (3,5,7,11) | 3 columns equal |
| Dual log row (9) | 2 columns equal |

---

## Acceptance checklist (must meet the visual)

| # | Requirement from picture | Pass? |
| --- | --- | --- |
| 1 | App selector works (All / EIP / API / Payment) | |
| 2–3 | Critical alerts section + Problems / Root Cause / Alert Summary | |
| 4–5 | App metrics: Requests / Errors / Response Time | |
| 6–7 | Infra: Windows CPU / Linux CPU / Memory | |
| 8–9 | Logs: Error Logs / Exception Traces | |
| 10–11 | DB Connections / Queries / External Services | |
| — | Changing `$app` updates tiles (no wrong-app data) | |
| — | Headers readable like the visual (Markdown titles) | |

---

## Investigation

| Source | Use |
| --- | --- |
| User layout PNG | Exact 11-row order and labels |
| Prior STG L1 runbook (`2026-08-31/9-…`) | Tag/MZ/synthetic practice; different section names — **this board follows the new visual**, not the old L1 11 list |

---

## Result

Build **one** dashboard named clearly (`App-Health-Layout` or `App-Health-STG`). Implement **Row 1 variable first**, then headers, then data tiles top to bottom. Do not promote to prod until the acceptance table is green and filters cannot show the wrong app.

---

## Data flow map

```
User picks app (Row1 variable)
        │
        ▼
Problems / Davis (Rows 2–3)
        │
        ▼
App KPIs: requests · errors · latency (Rows 4–5)
        │
        ▼
Hosts: Win/Linux CPU · memory (Rows 6–7)
        │
        ▼
Logs · exceptions (Rows 8–9)
        │
        ▼
DB · queries · external calls (Rows 10–11)
```

---

## Related files

| File | Purpose |
| --- | --- |
| `1-dynatrace-dashboard-layout-build.md` | This guide |
| `1-dynatrace-dashboard-layout-build-tiles.yaml` | Machine-readable tile spec |
| `1.sh` | Bookmark / open Dynatrace (placeholders) |
| Prior STG steps | `Daily Files/2026-08-31/9-dynatrace-stg-dashboard-steps/` |

## Commands

See [`1.sh`](./1.sh). Review before use. No live Dynatrace API calls unless you ask later.
