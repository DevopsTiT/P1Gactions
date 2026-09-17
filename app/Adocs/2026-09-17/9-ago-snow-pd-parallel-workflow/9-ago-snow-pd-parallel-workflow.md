# Ago Snow Pd Parallel Workflow

```
Dynatrace Problem OPEN
  → prepare (caller, biz service, assign, P3/P4, DT link, app, L1-L3, runbook)
  → parallel: ServiceNow Create INC + PagerDuty trigger
  → comment on INC with PD dedup_key (sync)

Dynatrace Problem CLOSED
  → find INC by correlation_id → resolve SNOW + resolve PD
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| Deliverable | Two workflows: **open** + **close** (YAML preferred) |
| Parallel | SNOW Create Incident and PagerDuty after prepare |
| Sync | `correlation_id` = Problem ID; PD `dedup_key` = `dt-problem-<id>`; work note cross-link |
| Classic UI you showed | `servicenowstg` → silvastg; **turn ITSM OFF** if workflow creates INC (no duplicates) |

## Summary

Upload the open and close workflow YAML. Map a ServiceNow Connection to `https://silvastg.service-now.com`. Fill assignment sys_ids and PagerDuty routing key. Activate both. Do not also keep classic ITSM ON for the same Problems.

---

## Investigation

| Requirement from your note | How the workflow covers it |
| --- | --- |
| Problem/incident triggers auto create | Davis Problem OPEN trigger |
| ServiceNow + PagerDuty in parallel | Two tasks after `prepare-payload` |
| ServiceNow sync with PagerDuty | Same Problem ID keys + INC comment with PD dedup_key |
| 1 Caller | `caller` / description “Caller: …” |
| 2 Business service | `businessServiceName` / sys_id in assignMap |
| 3 Assignment | `assignmentGroupName` / sys_id |
| 4 P3 / P4 | From severity → impact/urgency + `pLevel` |
| 5 Dynatrace link, app, L1–L3 | In description + PD custom_details |
| 6 Runbook / article | `runbook` URL in assignMap |

Classic notification screenshot: display name `servicenowstg`, URL `https://silvastg.service-now.com`, user `Tech_DynatraceJP_WS`, ITSM ON, ITOM ON.

## Result

| File | Role |
| --- | --- |
| `ago-problem-to-snow-pagerduty.workflow-template.yaml` | **Upload** — OPEN |
| `ago-problem-closed-resolve-snow-pd.workflow-template.yaml` | **Upload** — CLOSE |
| `*.workflow.json` | Twins for review |

---

## Flow (pic)

```
OPEN workflow
  prepare-payload
     ├─ create-servicenow-incident  (Connection)
     └─ create-pagerduty-incident   (JS fetch)
           └─ cross-link-snow-pd    (comment PD key on INC)

CLOSE workflow
  prepare-close-ids
     ├─ search-snow-incident → resolve-snow-incident
     └─ resolve-pagerduty
```

---

## Before upload checklist

| Step | Action |
| --- | --- |
| 1 | Settings → Connections → ServiceNow → URL `https://silvastg.service-now.com` (user/OAuth) |
| 2 | Classic `servicenowstg`: **Send incidents ITSM = OFF** (workflow owns INC). ITOM optional |
| 3 | External requests: `silvastg.service-now.com`, `events.pagerduty.com` |
| 4 | Edit YAML `assignMap` sys_ids + `__PD_ROUTING_KEY__` |
| 5 | Upload open YAML → map Connection → Activate |
| 6 | Upload close YAML → map Connection → same PD key → Activate |
| 7 | Test open Problem → INC + PD → comment has dedup_key; close → both resolve |

---

## Ticket field mapping

| Your ask | Where in workflow |
| --- | --- |
| Who is calling | `caller` + description line |
| Business service | `assignMap.*.bizName` / `bizSysId` |
| Assign to whom | `assignMap.*.groupName` / `groupSysId` |
| P3 / P4 | Computed from Problem severity |
| Dynatrace link + app | `problemUrl`, tag `app` |
| L1 L2 L3 | `assignMap` l1/l2/l3 in description |
| Runbook | `assignMap.*.runbook` |

Edit the `assignMap` block inside `prepare-payload` for EIP/CCI/default (or your apps).

---

## Sync design

| System | Key |
| --- | --- |
| ServiceNow | `correlation_id` = Dynatrace Problem ID |
| PagerDuty | `dedup_key` = `dt-problem-<ProblemID>` |
| Cross-link | INC work note contains PD dedup_key + Problem URL |

---

## Important: classic notification vs this workflow

| Path | Creates |
| --- | --- |
| Classic `servicenowstg` ITSM ON | ServiceNow INC (generic DT template) |
| This workflow SNOW task | ServiceNow INC (rich fields you listed) |
| Both ON | **Duplicate INC** for same Problem |

**Recommendation:** Workflow owns ITSM INC → set classic **Send incidents into ServiceNow ITSM = OFF**. Keep ITOM ON only if you still want events.

---

## UI setup (short)

1. Workflows → Upload open YAML → map Connection → set PD key → Save → Activate.  
2. Upload close YAML → same Connection + PD key → Activate.  
3. Raise test Problem → Executions OK → check silvastg INC + PagerDuty.  
4. Close Problem → both resolve.

Detailed UI: `5-setup-workflow-ui-manage-guide/` and `2026-09-14/9-set-workflow-ui-step-by-step/`.

---

## Data flow map

```
Dynatrace Problem
  → OPEN workflow → SNOW INC + PD (parallel) → sync comment
  → CLOSED workflow → resolve SNOW + resolve PD
Classic servicenowstg (optional ITOM only)
```

## Related files

| Path | Why |
| --- | --- |
| YAML/JSON in this folder | Upload these |
| `../5-setup-workflow-ui-manage-guide/` | UI manage |
| `2026-09-14/3-snow-pd-workflow-with-connection/` | Earlier same pattern |
| `9.sh` | Paths |

## Commands

See `9.sh` in this folder.
