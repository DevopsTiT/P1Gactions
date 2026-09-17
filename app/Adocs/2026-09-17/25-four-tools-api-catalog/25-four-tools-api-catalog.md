# Four Tools Api Catalog

```
Need APIs for Dynatrace + ServiceNow + PagerDuty + Splunk?
  │
  ├─ Used in YOUR current pack → §1 (highlight)
  ├─ Main API families per product → §2–§5
  └─ How they connect in one picture → §6
```

## Short takeaway

| Product | Primary API style | Base / host pattern |
| --- | --- | --- |
| Dynatrace | Environment API + Config API + Workflows | `https://{env}.live.dynatrace.com/api/v2/...` |
| ServiceNow | Table API (REST) | `https://{instance}.service-now.com/api/now/v2/table/{table}` |
| PagerDuty | Events API v2 + REST API | `https://events.pagerduty.com/v2/enqueue` and `https://api.pagerduty.com/...` |
| Splunk | REST on management port | `https://{splunk-host}:8089/services/...` |

This is an **SRE / integration catalog** of the main APIs. Each vendor has more niche endpoints; the tables cover what you use for monitoring, ticketing, paging, and log search.

## Summary

Below: (1) APIs your Dynatrace→SNOW→PD pack already calls, (2) Dynatrace API families, (3) ServiceNow, (4) PagerDuty, (5) Splunk, (6) how they fit together. Fake host examples use `abc12345`, `silvastg`, and `splunk.example.com`.

---

## Investigation

Compiled from your Connector/PD workflows (seq 19–23), Dynatrace Environment API docs, ServiceNow Connector→Table API mapping, PagerDuty Events/REST docs patterns, and Splunk REST `/services` search patterns used in earlier Splunk query packs.

## Result

Use §1 for allowlist + workflow design. Use §2–§5 when scripting outside Workflows (tokens, curl, automation).

---

## 1) APIs YOUR architecture already uses

| From | To | Method + path | Purpose |
| --- | --- | --- | --- |
| Dynatrace (internal) | Workflow runtime | Davis Problem event | Starts OPEN/CLOSE |
| Dynatrace Connector | ServiceNow | `POST /api/now/v2/table/incident` | Create INC |
| Dynatrace Connector | ServiceNow | `GET /api/now/v2/table/incident` | Search by correlation_id |
| Dynatrace Connector | ServiceNow | `PUT /api/now/v2/table/incident/{sys_id}` | Comment / resolve |
| Dynatrace JS `fetch` | PagerDuty | `POST /v2/enqueue` | Trigger + resolve alert |
| (optional) Classic notification | ServiceNow | Problem notification push | ITOM `em_event` path |

Allowlist hosts: `silvastg.service-now.com`, `events.pagerduty.com`.

---

## 2) Dynatrace APIs

Base (SaaS fake example): `https://abc12345.live.dynatrace.com`

Auth: API token header `Authorization: Api-Token <token>` (scopes per API).

### 2a) Environment API v2 (most used for ops)

| API family | Method | Path | What it means |
| --- | --- | --- | --- |
| Problems list | GET | `/api/v2/problems` | List open/closed Problems |
| Problem details | GET | `/api/v2/problems/{problemId}` | One Problem card |
| Problem close | POST | `/api/v2/problems/{problemId}/close` | Close a Problem |
| Problem comments | GET/POST | `/api/v2/problems/{problemId}/comments` | Comments on Problem |
| Events list | GET | `/api/v2/events` | List events |
| Event ingest | POST | `/api/v2/events/ingest` | Push custom events |
| Metrics query | GET | `/api/v2/metrics/query` | Timeseries metrics |
| Metrics ingest | POST | `/api/v2/metrics/ingest` | Push metrics |
| Entities | GET | `/api/v2/entities` | Monitored entities |
| Entity | GET | `/api/v2/entities/{entityId}` | One entity |
| Logs export / search | GET/POST | `/api/v2/logs/export`, `/api/v2/logs/search` | Log access (env-dependent) |
| Security problems | GET | `/api/v2/securityProblems` | AppSec problems |
| Settings objects | GET/PUT/POST | `/api/v2/settings/objects` | Many Settings as objects |
| ActiveGates | GET | `/api/v2/activeGates` | ActiveGate inventory |
| Network zones | GET | `/api/v2/networkZones` | Network zones |
| Audit logs | GET | `/api/v2/auditlogs` | Audit trail |
| Tokens | GET/POST | `/api/v2/apiTokens` | Manage tokens (careful) |
| Extensions | various | `/api/v2/extensions*` | Extension framework |

### 2b) Davis / Grail / query (modern analytics)

| API / feature | Path / entry | What it means |
| --- | --- | --- |
| DQL query (Grail) | Platform / query APIs (env-dependent; often via Workflows or Dynatrace Query API) | Query problems, logs, spans with DQL |
| Workflows Automations | App actions inside Dynatrace (not classic `/api/v2` path you curl for every task) | Runs `run-javascript`, Connector actions |

### 2c) Configuration API (classic, still common)

| Family | Path pattern | What it means |
| --- | --- | --- |
| Config API | `/api/config/v1/...` | Alerting profiles, anomaly detection, notification configs, etc. |
| Problem notifications (classic) | Configured in UI / Config API | Pushes Problems to SNOW / PD / webhooks |

### 2d) Dynatrace → others (from Dynatrace side)

| Integration | Mechanism | External API called |
| --- | --- | --- |
| ServiceNow Connector | Workflow `snow-*` | SNOW Table API (below) |
| PagerDuty from Workflow | JS `fetch` or classic notification | PD Events API |
| Splunk | Usually Splunk pulls Dynatrace **or** you export; not in your current YAML pack | Often Splunk HEC or Dynatrace→webhook; or Splunk queries its own indexes |

Fake Problem API example:

`GET https://abc12345.live.dynatrace.com/api/v2/problems?problemSelector=status("OPEN")`

---

## 3) ServiceNow APIs

Base fake example: `https://silvastg.service-now.com`

Auth: Basic (`user:pass`) or OAuth bearer (Connection in Dynatrace).

### 3a) Table API (what Connector uses)

| Operation | Method | Path | Used in your pack? |
| --- | --- | --- | --- |
| Create INC | POST | `/api/now/v2/table/incident` | Yes |
| List/search INC | GET | `/api/now/v2/table/incident` | Yes |
| Get one INC | GET | `/api/now/v2/table/incident/{sys_id}` | Indirect |
| Update INC (comment/resolve) | PUT / PATCH | `/api/now/v2/table/incident/{sys_id}` | Yes |
| Any table CRUD | POST/GET/PUT/PATCH/DELETE | `/api/now/v2/table/{tableName}` | Available |
| Groups | GET | `/api/now/v2/table/sys_user_group` | Connector helper / unused in YAML |
| Choices (category) | GET | `/api/now/v2/table/sys_choice` | UI helpers |
| Vulnerability item | POST | `/api/now/v2/table/sn_vul_vulnerable_item` | Unused here |

Also common: `/api/now/table/...` (v1 style; Connector docs use **v2**).

### 3b) Other ServiceNow API families (SRE-relevant)

| API | Path pattern | What it means |
| --- | --- | --- |
| Attachment API | `/api/now/attachment` | File attach to records |
| Import Set API | `/api/now/import/...` | Bulk/transform import |
| Aggregate API | `/api/now/stats/...` | Aggregations |
| Scripted REST APIs | `/api/{scope}/...` | Custom endpoints (classic Dynatrace app often lands here) |
| ITOM Event | table `em_event` via Table API or Event Management APIs | Classic Dynatrace ITOM notification target |

### 3c) Dynatrace classic notification (optional beside Connector)

| Path concept | Landing |
| --- | --- |
| Dynatrace Problem notification → SNOW | Scripted REST / import set → ITSM INC and/or ITOM `em_event` |

Keep **ITSM OFF** if Connector creates INC.

---

## 4) PagerDuty APIs

### 4a) Events API v2 (what your workflow uses)

| Host | Method + path | Body actions |
| --- | --- | --- |
| `https://events.pagerduty.com` | `POST /v2/enqueue` | `event_action`: `trigger`, `acknowledge`, `resolve` |

| Field | What it means |
| --- | --- |
| `routing_key` | Integration key for a PD service |
| `dedup_key` | Ties trigger and resolve (you use `dt-problem-<id>`) |
| `payload.summary` / `severity` | Alert text and severity |

Fake: `POST https://events.pagerduty.com/v2/enqueue`

### 4b) REST API (management — not in your current YAML)

Base: `https://api.pagerduty.com`  
Auth: `Authorization: Token token=<API_TOKEN>`

| Resource | Typical paths | What it means |
| --- | --- | --- |
| Incidents | `GET/POST /incidents`, `GET/PUT /incidents/{id}` | List/manage incidents |
| Services | `GET/POST /services` | PD services |
| Escalation policies | `GET /escalation_policies` | Who gets paged |
| Users / schedules | `GET /users`, `GET /schedules` | On-call directory |
| On-calls | `GET /oncalls` | Who is on call now |
| Log entries | `GET /incidents/{id}/log_entries` | Incident timeline |
| Priorities / statuses | various `/priorities`, etc. | Metadata |

Events API = **fire/resolve alerts**. REST API = **admin and incident management**.

---

## 5) Splunk APIs

Base fake example: `https://splunk.example.com:8089` (management port; cloud uses customer URL).

Auth: session key, token, or basic (env-dependent).

### 5a) Core REST (most common for SRE)

| API | Method | Path | What it means |
| --- | --- | --- | --- |
| Login / session | POST | `/services/auth/login` | Get session key |
| Oneshot search | POST | `/services/search/jobs/export` | Run search, stream results |
| Create search job | POST | `/services/search/jobs` | Async search |
| Job status | GET | `/services/search/jobs/{sid}` | Poll job |
| Job results | GET | `/services/search/jobs/{sid}/results` | Fetch rows |
| Saved searches | GET/POST | `/services/saved/searches` | Manage saved searches |
| Apps | GET | `/services/apps/local` | Installed apps |
| Indexes | GET | `/services/data/indexes` | Index list |
| Inputs | GET/POST | `/services/data/inputs/...` | Data inputs |
| Server info | GET | `/services/server/info` | Instance info |

### 5b) HEC (HTTP Event Collector) — ingest into Splunk

| API | Method | Path | What it means |
| --- | --- | --- | --- |
| HEC event | POST | `https://{hec-host}:8088/services/collector` or `/services/collector/event` | Push JSON events into Splunk |
| HEC raw | POST | `/services/collector/raw` | Push raw logs |

Auth: `Authorization: Splunk <HEC_TOKEN>`

### 5c) Splunk Cloud / Platform nuances

| Item | What it means |
| --- | --- |
| Cloud REST base | Customer-specific URL (not always `:8089`) |
| Search Language | SPL in the search body (`search index=...`) |
| Your earlier packs | SPL / query examples for top-N style investigations — those run **against Splunk**, not via Dynatrace Workflow YAML |

Dynatrace ↔ Splunk is usually: **export/webhook/HEC into Splunk**, or **humans/automation query Splunk REST** — your current Problem→SNOW→PD pack does **not** call Splunk APIs.

---

## 6) One picture — how the four connect

```
                    ┌──────────────┐
                    │  Dynatrace   │
                    │ Problems API │
                    │ Workflows    │
                    └──────┬───────┘
           ┌───────────────┼───────────────┐
           │               │               │
           ▼               ▼               ▼
    ServiceNow        PagerDuty         Splunk
    Table API         Events API        REST / HEC
    /api/now/v2/      /v2/enqueue       :8089 /services
    table/incident                      (or HEC :8088)
           │               │               │
           └──── tickets ──┴── pages ──────┴── logs/search
```

| Flow | APIs |
| --- | --- |
| Problem → ticket | Dynatrace Workflow → SNOW Table API |
| Problem → page | Dynatrace JS → PD Events API |
| Problem → logs investigation | Human/automation → Splunk search REST (separate) |
| Optional classic | Dynatrace notification → SNOW ITOM/ITSM |

---

## 7) Allowlist reminder (Dynatrace outbound)

| Host | Product |
| --- | --- |
| `silvastg.service-now.com` | ServiceNow |
| `events.pagerduty.com` | PagerDuty Events |
| Splunk host (only if Workflow `fetch`/HEC from Dynatrace) | e.g. `splunk.example.com` — **not** in current pack |

---

## Data flow map

```
Dynatrace (detect + automate)
  ├─ /api/v2/problems*          (read Problems via token, optional)
  ├─ Workflows (internal)
  │     ├─ SNOW POST/GET/PUT /api/now/v2/table/incident
  │     └─ PD  POST /v2/enqueue
  └─ (optional) Splunk not called by current YAML

Splunk (investigate)
  └─ POST/GET /services/search/jobs*   (SPL queries)
  └─ POST /services/collector*         (ingest, if used)
```

## Related files

| Path | Why |
| --- | --- |
| `../20-dynatrace-snow-pd-architecture/` | Architecture |
| `../23-architecture-all-apis-involved/` | Deep dive DT+SNOW+PD for your pack |
| `../24-dynatrace-external-links-allowlist/` | Hosts to grant |
| `../7-splunk-query-instructions/` / `../8-splunk-query-top10-examples/` | Splunk query side |
| `25.sh` | Paths |

## Commands

See `25.sh` in this folder.
