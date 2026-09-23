# SILVA HTTP Snow And PagerDuty Sync Workflows

```
Cannot use snow-* connector?
  → YES: use run-javascript HTTP (this pack)
  → POST SILVA/SNOW + POST PagerDuty in parallel
  → Sync with correlation_id + dedup_key

Sandbox fails but EU STG worked?
  → Check External requests allowlist first
  → silvastg.service-now.com + events.pagerduty.com
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| Why not connector | Matches your chat: cannot build / use SNOW connector → HTTP to SILVA |
| Two YAMLs | **OPEN** create + **CLOSE** resolve (keep both Active) |
| Sync | `correlation_id = problemId` (SILVA) and `dedup_key = dt-problem-<id>` (PD) |
| Language | JavaScript inside `dynatrace.automations:run-javascript` |
| Hard gate | Outbound allowlist + replace `__SNOW_PASSWORD__` / `__PD_ROUTING_KEY__` |

## Summary

These two Dynatrace workflows fire on Davis Problem open/close. They do **not** use `dynatrace.servicenow:snow-*`. They HTTP POST to SILVA/SNOW Table API and PagerDuty Events API, then stay in sync with shared IDs. SILVA/CMDB may skip creating an INC (for example retired host) — CLOSE treats “not found” as a soft miss.

## Investigation

Chat context: SILVA integration via HTTP (not connector); EU STG worked; Sandbox may need outbound whitelist for `silvastg.service-now.com` / related hosts; PagerDuty via `events.pagerduty.com`. Built open/close YAML pair with explicit sync keys and allowlist error hints.

## Result

| File | Role |
| --- | --- |
| `1-open-silva-http-and-pagerduty.workflow.yaml` | Problem OPEN → SILVA INC + PD trigger |
| `2-close-silva-http-and-pagerduty.workflow.yaml` | Problem CLOSE → SILVA resolve + PD resolve |

---

## 1) Situation → design

| Constraint from chat | Design choice |
| --- | --- |
| Cannot build SNOW connector | Use `run-javascript` + `fetch` HTTP |
| Push to SILVA | POST `https://silvastg.service-now.com/api/now/v2/table/incident` |
| Also page on-call | POST `https://events.pagerduty.com/v2/enqueue` |
| Keep both sides in sync | Same `problemId` → correlation_id + dedup_key |
| SILVA CMDB gate | CLOSE does not hard-fail if INC was never created |
| Sandbox vs EU STG | Document allowlist as first check |

---

## 2) Sync map

| Side | Field | Value |
| --- | --- | --- |
| Dynatrace | Problem display id | e.g. `P-12345` |
| SILVA / SNOW | `correlation_id` | `P-12345` |
| PagerDuty | `dedup_key` | `dt-problem-P-12345` |
| PagerDuty custom_details | `snow_correlation_id` + `problem_url` | for humans / SRE Agent |

```
OPEN:  DT Problem CREATED → prepare → SILVA POST + PD trigger (parallel)
CLOSE: DT Problem CLOSED  → prepare → SILVA PATCH + PD resolve (parallel)
```

---

## 3) OPEN tasks

| Task | Action | What it does |
| --- | --- | --- |
| prepare-payload | run-javascript | Builds titles, severities, sync keys |
| post-silva-incident-http | run-javascript | HTTP POST create INC |
| trigger-pagerduty | run-javascript | HTTP POST PD `event_action=trigger` |

## 4) CLOSE tasks

| Task | Action | What it does |
| --- | --- | --- |
| prepare-close-ids | run-javascript | Same sync keys |
| resolve-silva-incident-http | run-javascript | GET by correlation_id → PATCH state 6 |
| resolve-pagerduty | run-javascript | PD `event_action=resolve` |

---

## 5) Setup checklist (you run)

| Step | What to do |
| --- | --- |
| 1 | Dynatrace → Settings → External requests → allow `silvastg.service-now.com` and `events.pagerduty.com` |
| 2 | In both YAML files replace `__SNOW_PASSWORD__` and `__PD_ROUTING_KEY__` |
| 3 | Turn classic SNOW Problem notification ITSM **OFF** while testing (no duplicate INC) |
| 4 | Workflows → Upload / import both YAML → Activate |
| 5 | Open a **test** Problem → check SILVA INC + PD incident |
| 6 | Close Problem → both sides resolve |

If Sandbox fails but EU STG worked: re-check allowlist on the **Sandbox** tenant (your chat’s conclusion).

---

## 6) Common fails

| Symptom | Likely cause |
| --- | --- |
| fetch / network error to SILVA | Outbound allowlist missing on this tenant |
| 401 / 403 from SILVA | Bad user/password or role |
| INC missing but PD exists | SILVA CMDB skip (retired host) — expected sometimes |
| Duplicate INC | Classic notification ITSM still ON |
| PD never resolves | CLOSE not Active, or dedup_key mismatch |

---

## Data flow map

```
Davis Problem OPEN
  → prepare-payload (correlationId + dedupKey)
  → parallel:
       HTTP POST SILVA /api/now/v2/table/incident
       HTTP POST events.pagerduty.com/v2/enqueue (trigger)

Davis Problem CLOSE
  → prepare-close-ids (same keys)
  → parallel:
       GET INC by correlation_id → PATCH Resolved
       HTTP POST PD enqueue (resolve)
```

---

## Related files

| File | Role |
| --- | --- |
| `1-open-silva-http-and-pagerduty.workflow.yaml` | OPEN workflow |
| `2-close-silva-http-and-pagerduty.workflow.yaml` | CLOSE workflow |
| `2026-09-17/18-snow-notification-via-javascript-rest/` | Earlier JS REST pack |
| `1.sh` | Optional notes (user runs) |

## Commands

See `1.sh`.
