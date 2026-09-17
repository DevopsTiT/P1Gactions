# Architecture All Apis Involved

```
What APIs does this architecture call?
  │
  ├─ Dynatrace internal: Davis Problem event + Workflow JS runtime
  ├─ ServiceNow Table API v2 (via Connector snow-* actions)
  ├─ PagerDuty Events API v2 /v2/enqueue
  └─ Optional: classic Problem notification → SNOW ITOM (separate)
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| SNOW path | Connector → `POST/GET/PUT /api/now/v2/table/incident` |
| PD path | JS `fetch` → `POST https://events.pagerduty.com/v2/enqueue` |
| You do not write SNOW URLs in YAML | Connection + `snow-*` actions wrap Table API |
| Same catalog | Also appended as **§13** in `20-dynatrace-snow-pd-architecture.md` |

## Summary

Every external and internal API used by the Problem → ServiceNow Connector + PagerDuty design is listed below, with method, path, host, and which workflow task owns it.

---

## Investigation

Mapped each workflow task in seq 19 to Dynatrace docs (ServiceNow Connector action → ServiceNow API endpoint) and to the explicit PagerDuty `fetch` URL in the YAML. Updated architecture seq 20 with the same §13.

## Result

Use the tables below as the API inventory. Fake example host: `silvastg.service-now.com`.

---

## 1) Required APIs (this pack)

| Workflow task | Dynatrace action | External API | Method + path | Fake full URL |
| --- | --- | --- | --- | --- |
| (trigger) | Davis Problem event | Internal event bus | n/a | Dynatrace environment |
| prepare-payload | `dynatrace.automations:run-javascript` | Internal JS runtime | n/a | Dynatrace |
| prepare-close-ids | same | Internal JS runtime | n/a | Dynatrace |
| create-servicenow-incident | `snow-create-incident` | ServiceNow Table API | `POST /api/now/v2/table/incident` | `https://silvastg.service-now.com/api/now/v2/table/incident` |
| cross-link-snow-pd | `snow-comment-on-incident` | ServiceNow Table API | `PUT /api/now/v2/table/incident/{sys_id}` | `https://silvastg.service-now.com/api/now/v2/table/incident/abcdef0123456789abcdef0123456789` |
| search-snow-incident | `snow-search-incidents` | ServiceNow Table API | `GET /api/now/v2/table/incident` | `https://silvastg.service-now.com/api/now/v2/table/incident?sysparm_query=correlation_id=P-240917001&sysparm_limit=1` |
| resolve-snow-incident | `snow-resolve-incident` | ServiceNow Table API | `PUT /api/now/v2/table/incident/{sys_id}` | same PUT pattern as comment |
| create-pagerduty-incident | JS `fetch` | PagerDuty Events API v2 | `POST /v2/enqueue` | `https://events.pagerduty.com/v2/enqueue` |
| resolve-pagerduty | JS `fetch` | PagerDuty Events API v2 | `POST /v2/enqueue` | same URL; body `event_action=resolve` |

### Auth

| API | How auth works here |
| --- | --- |
| ServiceNow | Dynatrace Connection (basic user/password or OAuth client credentials) |
| PagerDuty | `routing_key` field inside the JSON body |

### Fake PagerDuty body shapes

| Action | Body fields |
| --- | --- |
| Trigger | `routing_key`, `event_action: trigger`, `dedup_key`, `payload.summary`, … |
| Resolve | `routing_key`, `event_action: resolve`, `dedup_key` |

### Fake ServiceNow search query

| Query param | Fake example |
| --- | --- |
| `sysparm_query` | `correlation_id=P-240917001` |
| `sysparm_limit` | `1` |
| `sysparm_fields` | `number,sys_id,correlation_id,state` |

---

## 2) Optional classic notification APIs

| When | What | Typical SNOW landing |
| --- | --- | --- |
| ITOM ON on `servicenowstg` | Dynatrace Problem notification push | ITOM `em_event` (and related) |
| ITSM ON (do **not** with Connector INC) | Same notification family | Import set → `incident` (duplicate risk) |

Exact Scripted REST URL depends on the Dynatrace app installed on ServiceNow. It is **not** the same code path as Connector Table API.

---

## 3) Connector APIs available but unused in this pack

| Action | Endpoint |
| --- | --- |
| Create vulnerability item | `POST /api/now/v2/table/sn_vul_vulnerable_item` |
| Get Groups | `GET /api/now/v2/table/sys_user_group` |
| Generic Search | `GET /api/now/v2/table/{tableName}` |
| Generic Comment | `PUT /api/now/v2/table/{tableName}/{sysId}` |
| Create record | `POST /api/now/v2/table/{tableName}` |
| Update record | `PUT /api/now/v2/table/{tableName}/{sys_id}` |

Editor helpers may also query `sys_choice` and `sys_user_group` when you pick Category / Subcategory / groups in the UI.

---

## 4) Call order

```
OPEN
  Davis Problem (internal)
  → JS prepare (internal)
  → POST /api/now/v2/table/incident
  → POST https://events.pagerduty.com/v2/enqueue   (trigger)
  → PUT  /api/now/v2/table/incident/{sys_id}       (comment)

CLOSE
  Davis Problem close (internal)
  → JS prepare-close (internal)
  → GET  /api/now/v2/table/incident?...
  → PUT  /api/now/v2/table/incident/{sys_id}       (resolve)
  → POST https://events.pagerduty.com/v2/enqueue   (resolve)
```

---

## Data flow map

```
Dynatrace Problem event
        │
        ├─ OPEN tasks
        │     POST SNOW /api/now/v2/table/incident
        │     POST PD   /v2/enqueue (trigger)
        │     PUT  SNOW /api/now/v2/table/incident/{sys_id}
        │
        └─ CLOSE tasks
              GET  SNOW /api/now/v2/table/incident
              PUT  SNOW /api/now/v2/table/incident/{sys_id}
              POST PD   /v2/enqueue (resolve)

Optional classic ITOM notification → separate SNOW path
```

## Related files

| Path | Why |
| --- | --- |
| `../20-dynatrace-snow-pd-architecture/` | Full architecture (§13 APIs added) |
| `../19-snow-connector-workflow-again/` | YAML that performs these calls |
| `../22-yaml-with-all-example-data/` | Example-filled YAML |
| `23.sh` | Paths |

## Commands

See `23.sh` in this folder.
