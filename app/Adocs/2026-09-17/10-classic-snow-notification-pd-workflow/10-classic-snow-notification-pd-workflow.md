# Classic Snow Notification Pd Workflow

```
OK to use pic (classic Problem notification) instead of SNOW Connection?
  │
  ├─ YES for ServiceNow path — if ITOM events are enough
  │     (your pic: ITSM OFF, ITOM ON)
  │
  ├─ Workflow = PagerDuty only (no snow-create-incident)
  │
  └─ NO if you still need rich INC fields
        (caller, assignment group, P3/P4 map, L1-L3, runbook as structured INC)
        → keep Workflow ServiceNow Connection pack (seq 9)
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| Is classic OK? | **Yes** for SNOW via Problem notifications like your pic |
| What your pic does | ITOM **events** to `https://silvastg.service-now.com` (not Workflow Connection INC) |
| Workflow then | Upload **PD-only** open + close YAML |
| Trade-off | You lose rich ITSM INC field control from the Connection workflow |

## Summary

Using **Settings → Problem notifications → servicenowstg** instead of a Workflow ServiceNow Connection is OK. Keep that notification for ServiceNow. Use Workflows only for PagerDuty (and sync keys in PD custom details). YAML for the notification + PD workflows is in this folder.

---

## Investigation

| UI field (pic) | Value |
| --- | --- |
| Display name | `servicenowstg` |
| Type | ServiceNow |
| URL | `https://silvastg.service-now.com` |
| Username | `Tech_DynatraceJP_WS` |
| Send ITSM incidents | **OFF** |
| Send ITOM events | **ON** |
| Message | `{State} {ProblemID}: Problem {ProblemID}: {ProblemTitle}` |

## Result

| Use | File |
| --- | --- |
| Classic notification YAML/JSON | `servicenowstg-problem-notification.*` |
| Workflow OPEN (PD only) | `ago-problem-to-pagerduty-only.workflow-template.yaml` |
| Workflow CLOSE (PD only) | `ago-problem-closed-resolve-pagerduty-only.workflow-template.yaml` |

---

## 1) Is it OK? (plain English)

| Approach | What it is | OK when |
| --- | --- | --- |
| Classic Problem notification (pic) | Dynatrace pushes Problems to SNOW automatically | You want SNOW ITOM events (your toggles) |
| Workflow ServiceNow Connection | Workflow tasks create/search/resolve ITSM INC | You need assignment, caller, P3/P4, L1–L3, runbook on INC |

**Your pic = classic notification.** It is **not** the same object as a Workflow Connection. You cannot set `connectionId: servicenowstg` on a workflow task.

With **ITSM OFF / ITOM ON**, ServiceNow gets **events**, not the rich INC ticket the Connection workflow builds.

---

## 2) Recommended architecture with your pic

```
Dynatrace Problem OPEN/CLOSE
  ├─ classic servicenowstg → ServiceNow ITOM event (Settings)
  └─ Workflow (PD-only) → PagerDuty trigger/resolve
```

Do **not** also run seq-9 `snow-create-incident` for the same Problems (confusion / duplicates if you later turn ITSM ON).

---

## 3) Classic notification YAML (matches pic)

Settings API value shape (`builtin:problem.notifications`):

```json
{
  "enabled": true,
  "type": "SERVICE_NOW",
  "displayName": "servicenowstg",
  "alertingProfile": "__ALERTING_PROFILE_ID__",
  "serviceNowNotification": {
    "url": "https://silvastg.service-now.com",
    "username": "Tech_DynatraceJP_WS",
    "password": "__SNOW_PASSWORD__",
    "message": "{State} {ProblemID}: Problem {ProblemID}: {ProblemTitle}",
    "sendIncidents": false,
    "sendEvents": true,
    "formatProblemDetailsAsText": false
  }
}
```

Monaco stub: `servicenowstg-problem-notification.monaco.yaml`  
Full JSON: `servicenowstg-problem-notification.settings.json`

You already have this in the UI — export/apply is optional. Keep the UI as source of truth if easier.

**Note:** Pic uses **OnPremise URL** → YAML field `url`. Do not also set `instanceName` (mutually exclusive).

---

## 4) Workflow YAML (PagerDuty only)

| File | Upload |
| --- | --- |
| `ago-problem-to-pagerduty-only.workflow-template.yaml` | Problem OPEN → PD |
| `ago-problem-closed-resolve-pagerduty-only.workflow-template.yaml` | Problem CLOSE → resolve PD |

Before Activate: replace `__PD_ROUTING_KEY__`.  
Allowlist: `events.pagerduty.com` (+ `silvastg.service-now.com` for classic SNOW).

---

## 5) What you give up vs Connection workflow

| Need from your earlier note | Classic notification (pic) | Connection workflow (seq 9) |
| --- | --- | --- |
| Auto notify SNOW on Problem | Yes (ITOM event) | Yes (ITSM INC) |
| Caller / assignment group / biz service sys_ids | Limited / not same control | Yes |
| P3/P4 mapping you define | No (DT default message) | Yes |
| L1/L2/L3 + runbook in INC | Only inside free-text message if you craft it | Yes structured |
| PD parallel + sync comment on INC | PD via workflow; no INC to comment on | Full cross-link |

If those rich INC fields are still required → use seq 9 Connection pack, keep classic ITSM OFF (as now).

---

## Data flow map

```
Problem
  → servicenowstg (classic) → silvastg ITOM event
  → PD-only workflow → PagerDuty (dedup_key=dt-problem-<id>)
```

## Related files

| Path | Why |
| --- | --- |
| YAML/JSON in this folder | Notification + PD workflows |
| `../9-ago-snow-pd-parallel-workflow/` | Rich SNOW Connection alternative |
| `2026-09-14/8-snow-classic-notification-yaml-json/` | Earlier same pattern |
| `10.sh` | Paths |

## Commands

See `10.sh` in this folder.
