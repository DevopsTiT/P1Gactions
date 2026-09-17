# Snow Notification Via Javascript Rest

```
Want pic integration as a workflow task?
  │
  ├─ Cannot call Problem notification object directly
  │
  └─ YES via run-javascript REST (same URL/user/message intent)
        → create INC (ITSM) + em_event (ITOM)
        → parallel PagerDuty
        → turn OFF classic servicenowstg ITSM/ITOM (no duplicates)
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| Approach | `run-javascript` + ServiceNow REST (Basic auth) |
| Mimics pic | silvastg URL, `Tech_DynatraceJP_WS`, ITSM+ITOM, message style |
| Not the same as | Invoking Settings notification `servicenowstg` by name |
| Required | Allowlist host; replace `__SNOW_PASSWORD__` + `__PD_ROUTING_KEY__` |

## Summary

These workflows use **run-javascript** tasks to POST to ServiceNow (incident + em_event), matching what your Problem notification does, plus PagerDuty. Disable classic notification ITSM/ITOM while this is Active to avoid duplicates.

---

## Investigation

User asked to use the pic integration inside the workflow via run-javascript or others. Built REST-based JS tasks.

## Result

| File | Role |
| --- | --- |
| `1-open-snow-js-rest-and-pd.workflow.yaml` | OPEN |
| `2-close-snow-js-rest-and-pd.workflow.yaml` | CLOSE |

Path: `Daily Files/2026-09-17/18-snow-notification-via-javascript-rest/`

---

## Tasks

### OPEN

| Task | What it does |
| --- | --- |
| prepare-payload | Builds `[{State}] {ProblemID}: Problem {Title} {URL}` style text |
| create-snow-itsm-and-itom-js | POST `/api/now/table/incident` + POST `/api/now/table/em_event` |
| create-pagerduty-incident | PD trigger (parallel) |

### CLOSE

| Task | What it does |
| --- | --- |
| prepare-close-ids | problemId + dedupKey |
| resolve-snow-incident-js | GET by correlation_id → PATCH state Resolved |
| resolve-pagerduty | PD resolve |

---

## Setup

1. Classic `servicenowstg`: turn **ITSM OFF** and **ITOM OFF** (or disable notification) while testing this workflow — avoid duplicates.  
2. External requests: `silvastg.service-now.com`, `events.pagerduty.com`.  
3. In both YAML files replace:
   - `__SNOW_PASSWORD__` (password for `Tech_DynatraceJP_WS`)
   - `__PD_ROUTING_KEY__`
4. Upload → Activate → test one Problem.  
5. SNOW user needs rights to create `incident` and `em_event` (roles may differ from notification-only roles).

---

## Limits vs built-in notification

| Built-in Problem notification | This JS REST approach |
| --- | --- |
| Exact Dynatrace↔SNOW app payload/import set | Table API INC + em_event (close equivalent) |
| Managed in Settings UI | Managed in workflow script |
| Password in Settings | Placeholder in YAML (move to secret later) |

If `em_event` POST fails on your instance, keep ITSM JS and ask SNOW admin for the correct Event Management inbound API for your plugins.

---

## Data flow map

```
Problem OPEN
  prepare
    ├─ JS REST → SNOW INC + em_event
    └─ JS → PagerDuty
Problem CLOSE
  prepare
    ├─ JS REST → resolve INC by correlation_id
    └─ JS → PagerDuty resolve
```

## Related files

| Path | Why |
| --- | --- |
| YAML in this folder | Upload these |
| `../17-yaml-with-snow-tasks/` | Official Connection `snow-*` actions (alternative) |
| `18.sh` | Paths |

## Commands

See `18.sh` in this folder.
