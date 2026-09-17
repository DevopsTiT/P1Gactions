# Workflow Snow Via Problem Notification

```
Want create-servicenow-incident via Problem notification (pic)?
  │
  ├─ Keep servicenowstg ON — ITSM ON + ITOM ON
  ├─ REMOVE snow-create-incident Connection task from workflow
  ├─ Workflow = PagerDuty only (open + close YAML below)
  └─ Do NOT run Connection Create INC + notification ITSM together
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| Your ask | Achieve SNOW INC using Problem notification, not Connection |
| New workflow | No `dynatrace.servicenow:snow-create-incident` |
| SNOW create | Classic `servicenowstg` (ITSM ON in your pic) |
| PD | Still in workflow YAML |

## Summary

The Connection task `create-servicenow-incident` cannot call the Problem notification integration. That notification runs by itself when a Problem matches. New YAML removes the SNOW Connection create task and keeps PagerDuty. Keep `servicenowstg` with ITSM ON (and ITOM ON as in your pic).

---

## Investigation

You pasted the Connection-based `create-servicenow-incident` block and asked to use the Problem notification setup instead. Pic: ITSM ON, ITOM ON, URL silvastg, user `Tech_DynatraceJP_WS`, message `{State} {ProblemImpact} Problem {ProblemID}: {ProblemTitle}`.

## Result

| File | Role |
| --- | --- |
| `1-open-pd-snow-via-notification.workflow.yaml` | OPEN — prepare + PD only |
| `2-close-pd-snow-via-notification.workflow.yaml` | CLOSE — PD resolve only |
| `servicenowstg-problem-notification.settings.json` | Backup of notification settings (ITSM+ITOM ON) |

---

## Diff vs old Connection task

| Old (Connection) | New (this pack) |
| --- | --- |
| `action: dynatrace.servicenow:snow-create-incident` | **Removed** |
| `connectionId` / category / group inputs | **N/A** — set in Problem notification UI |
| INC fields from `assignMap` | Limited to notification message + DT/SNOW default mapping |
| Cross-link comment on INC | **Removed** (no INC number from Connection create) |
| PagerDuty task | **Kept** |

---

## What you must keep in UI (pic)

| Field | Value |
| --- | --- |
| Display name | `servicenowstg` |
| URL | `https://silvastg.service-now.com` |
| Username | `Tech_DynatraceJP_WS` |
| Send incidents ITSM | **ON** |
| Send events ITOM | **ON** |
| Description | `{State} {ProblemImpact} Problem {ProblemID}: {ProblemTitle}` |
| Toggle | Notification **ON** |

---

## Upload steps

1. Confirm `servicenowstg` ITSM+ITOM ON → Save.  
2. Workflows → Upload `1-open-pd-snow-via-notification.workflow.yaml`.  
3. Replace `__PD_ROUTING_KEY__` → Activate.  
4. Upload `2-close-pd-snow-via-notification.workflow.yaml` → same key → Activate.  
5. Allowlist `silvastg.service-now.com` + `events.pagerduty.com`.  
6. Test: Problem open → SNOW INC (notification) + PD (workflow).

---

## Trade-off

| You gain | You lose vs Connection create |
| --- | --- |
| SNOW via existing integration | Custom caller / assignment group / P3-P4 map / L1-L3 / runbook as workflow fields |
| No Connection mapping for create | Workflow cross-link comment on INC |
| Matches your notification pic | Fine-grained INC field control |

If you need those rich fields again → use seq 13 Connection YAML and set notification **ITSM OFF**.

---

## Data flow map

```
Problem OPEN
  ├─ servicenowstg (ITSM+ITOM) → SNOW INC + event
  └─ this workflow → PagerDuty trigger

Problem CLOSE
  ├─ servicenowstg → SNOW update
  └─ this workflow → PagerDuty resolve
```

## Related files

| Path | Why |
| --- | --- |
| YAML in this folder | New working workflows |
| `../13-working-snow-pd-workflow-yaml/` | Old Connection create path |
| `../14-snow-connector-vs-problem-notification/` | Full diff |
| `15.sh` | Paths |

## Commands

See `15.sh` in this folder.
