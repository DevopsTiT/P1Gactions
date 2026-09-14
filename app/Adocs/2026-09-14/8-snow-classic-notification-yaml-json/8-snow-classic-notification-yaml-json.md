# Snow Classic Notification Yaml Json

```
Want SNOW via classic Problem notification silvastg?
  │
  ├─ Keep Settings → Problem notifications → silvastg
  │     (instance=silvastg, ITOM ON, ITSM OFF)
  │
  ├─ Do NOT put connectionId = silvastg in Workflow
  │     (different feature — cannot wire that way)
  │
  ├─ Workflow = PagerDuty only (open + close YAML/JSON)
  │
  └─ Need ITSM INC tickets instead of ITOM events?
        Turn Send incidents ON in silvastg
        OR keep Workflow ServiceNow Connection pack
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What you showed | Classic Problem notification named `silvastg` |
| What it is not | A Workflow ServiceNow Connection |
| SNOW result with your toggles | ITOM **events** (not ITSM incidents) |
| Workflow change | Remove SNOW tasks; keep PagerDuty only |
| Files to use | Settings JSON + PD-only open/close workflows |

## Summary

Use the classic `silvastg` Problem notification for ServiceNow. Put that config in Settings API / Monaco JSON. For Automations, upload **PagerDuty-only** workflows. You cannot map `ServiceNowTest` Connection or `connectionId` to this Problem notification.

---

## Investigation

| UI field | Value |
| --- | --- |
| Path | Settings → Integration → Problem notifications |
| Display name | `silvastg` |
| Instance | `silvastg` → `https://silvastg.service-now.com` |
| Username | `Tech_DynatraceINC_WS` (confirm exact string in UI) |
| Send ITSM incidents | OFF |
| Send ITOM events | ON |
| Message | `{State} {ProblemImpact} Problem {ProblemID}: {ProblemTitle}` |
| Timeout | 60 (UI; not always in Settings schema export) |

## Result

| Deliverable | File |
| --- | --- |
| Settings API JSON | `silvastg-problem-notification.settings.json` |
| Monaco YAML + template | `silvastg-problem-notification.monaco.yaml` + `.template.json` |
| Open workflow YAML | `ago-problem-to-pagerduty-only.workflow-template.yaml` |
| Close workflow YAML | `ago-problem-closed-resolve-pagerduty-only.workflow-template.yaml` |
| JSON twins | `problem-to-pagerduty-only.workflow.json` + close twin |

---

## 1) Classic connector JSON (Settings API)

Paste / POST as Settings object value (password + alerting profile placeholders):

```json
{
  "enabled": true,
  "type": "SERVICE_NOW",
  "displayName": "silvastg",
  "alertingProfile": "__ALERTING_PROFILE_ID__",
  "serviceNowNotification": {
    "instanceName": "silvastg",
    "username": "Tech_DynatraceINC_WS",
    "password": "__SNOW_PASSWORD__",
    "message": "{State} {ProblemImpact} Problem {ProblemID}: {ProblemTitle}",
    "sendIncidents": false,
    "sendEvents": true,
    "formatProblemDetailsAsText": false
  }
}
```

Schema: `builtin:problem.notifications`

Replace:

| Placeholder | How to get it |
| --- | --- |
| `__ALERTING_PROFILE_ID__` | Settings API for `builtin:alerting.profile` (Default) |
| `__SNOW_PASSWORD__` | Password for `Tech_DynatraceINC_WS` (secret) |

You already have this in the UI — export/apply is optional. Keeping it in UI is fine.

---

## 2) Workflow YAML / JSON (no Connection)

| Workflow | Role |
| --- | --- |
| Open | prepare → PagerDuty trigger |
| Close | prepare → PagerDuty resolve |
| SNOW | Classic notification `silvastg` only |

Before upload: replace `__PD_ROUTING_KEY__`.  
Allowlist: `events.pagerduty.com` (and `silvastg.service-now.com` for the classic notification path).

Prefer **YAML** upload for workflows. JSON twins are for review/copy.

---

## Important difference (beginner)

| Feature | What it does |
| --- | --- |
| Problem notifications `silvastg` | Dynatrace pushes problem open/close to ServiceNow ITOM events |
| Workflow Connection `ServiceNowTest` | Workflow tasks create/search/resolve ITSM incidents |

Your screenshot has **ITSM OFF / ITOM ON**. So classic path creates **events**, not INC tickets with assignment group / category like the Connection workflow.

If you need ITSM Incidents from classic notification: turn **Send incidents into ServiceNow ITSM** ON in the same `silvastg` form.

Do **not** run both classic ITSM + Workflow Create Incident for the same problems — you will get duplicates.

---

## Data flow map

```
Dynatrace Problem OPEN
  ├─→ classic notification silvastg → ServiceNow ITOM event
  └─→ workflow (PD-only) → PagerDuty trigger (dedup_key=dt-problem-<id>)

Dynatrace Problem CLOSED
  ├─→ classic notification silvastg → ServiceNow ITOM update (RESOLVED)
  └─→ workflow (PD-only) → PagerDuty resolve (same dedup_key)
```

## Related files

| Path | Why |
| --- | --- |
| `../3-snow-pd-workflow-with-connection/` | Old Connection-based INC workflow (do not mix) |
| `../6-fix-snow-host-not-in-allowlist/` | Allowlist still needed for silvastg |
| `8.sh` | Commands |

## Commands

See `8.sh` in this folder.
