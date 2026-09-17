# ServiceNow Connector Workflow

```
Need Problem → ServiceNow INC + PagerDuty?
  │
  ├─ Use ServiceNow Connector (Connection + snow-* actions) ← this pack
  │
  ├─ Do NOT use classic Problem notification ITSM for INC (set ITSM OFF)
  │
  └─ Do NOT use JS fetch to SNOW (that is the other pack, seq 18)
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What this is | Dynatrace Workflow YAML using the **ServiceNow Connector** |
| How SNOW is called | Official actions: `snow-create-incident`, `snow-comment-on-incident`, `snow-search-incidents`, `snow-resolve-incident` |
| How PD is called | JS task to `events.pagerduty.com` (same `dedup_key` as SNOW `correlation_id`) |
| Sync key | `dt-problem-<problemId>` |
| Avoid duplicate INC | Classic `servicenowstg` **ITSM OFF** while this workflow creates INC |

## Summary

Upload the open and close YAML in this folder. Map your ServiceNow Connection on every snow task. Replace the PagerDuty routing key and assignment sys_ids. Classic Problem notification does not create the INC here — the Connector does.

---

## Investigation

User asked again for the workflow that uses the **ServiceNow connector** (Connection), not classic notification and not the JS-REST mimic.

## Result

| File | Role |
| --- | --- |
| `1-open-snow-connector-and-pd.workflow.yaml` | Problem open → SNOW INC + PD + cross-link comment |
| `2-close-snow-connector-and-pd.workflow.yaml` | Problem close → search/resolve SNOW + resolve PD |
| `problem-to-snow-pagerduty.workflow.json` | Same OPEN logic (JSON upload form) |
| `problem-closed-resolve-snow-pd.workflow.json` | Same CLOSE logic (JSON upload form) |

Path: `Daily Files/2026-09-17/19-snow-connector-workflow-again/`

Same content as the working packs: `13-working-snow-pd-workflow-yaml/` and `17-yaml-with-snow-tasks/`.

---

## OPEN workflow tasks

| Task name | Action | What it means |
| --- | --- | --- |
| prepare-payload | `dynatrace.automations:run-javascript` | Builds title, urgency, assign group, correlation_id |
| create-servicenow-incident | `dynatrace.servicenow:snow-create-incident` | Creates INC via Connection |
| create-pagerduty-incident | `dynatrace.automations:run-javascript` | Opens PD alert (parallel with SNOW) |
| cross-link-snow-pd | `dynatrace.servicenow:snow-comment-on-incident` | Comments PD key on the INC |

## CLOSE workflow tasks

| Task name | Action | What it means |
| --- | --- | --- |
| prepare-close-ids | `dynatrace.automations:run-javascript` | Builds problemId and dedupKey |
| search-snow-incident | `dynatrace.servicenow:snow-search-incidents` | Finds INC by correlation_id |
| resolve-snow-incident | `dynatrace.servicenow:snow-resolve-incident` | Resolves the INC |
| resolve-pagerduty | `dynatrace.automations:run-javascript` | Resolves PD with same dedup_key |

---

## Setup before activate

1. Settings → Connections → ServiceNow → instance `https://silvastg.service-now.com`
2. Classic Problem notification `servicenowstg`: set **ITSM OFF** (this workflow owns INC create). ITOM may stay ON if you still want events.
3. Allowlist: `silvastg.service-now.com` and `events.pagerduty.com`
4. In YAML, replace `__PD_ROUTING_KEY__` and `__SNOW_*_SYS_ID__` / assignMap values
5. Upload both YAML (or JSON) → map Connection on every snow task → Activate → test one Problem

---

## Data flow map

```
Problem OPEN (ACTIVE / CREATED / UPDATED / REOPENED)
  │
  ├─ prepare-payload
  │     correlation_id = dedup_key = dt-problem-<id>
  │
  ├─ create-servicenow-incident  ──►  SNOW INC (Connector)
  │
  ├─ create-pagerduty-incident   ──►  PagerDuty (parallel)
  │
  └─ cross-link-snow-pd          ──►  comment on INC

Problem CLOSE (CLOSED / RESOLVED)
  │
  ├─ prepare-close-ids
  ├─ search-snow-incident        ──►  find by correlation_id
  ├─ resolve-snow-incident       ──►  resolve INC
  └─ resolve-pagerduty           ──►  resolve PD
```

## Related files

| Path | Why |
| --- | --- |
| This folder | Connector-based open/close workflows |
| `../13-working-snow-pd-workflow-yaml/` | Original working Connector pack |
| `../17-yaml-with-snow-tasks/` | Same Connector YAML (alias) |
| `../15-workflow-snow-via-problem-notification/` | PD-only; classic notification owns INC |
| `../18-snow-notification-via-javascript-rest/` | JS REST mimic (not Connector) |
| `19.sh` | Paths / reminders |

## Commands

See `19.sh` in this folder.
