# Snow Connector Vs Problem Notification Diff

```
Need SNOW from Dynatrace?
  │
  ├─ Classic Problem notification (Settings)
  │     Good for: simple push, ITOM events / basic ITSM INC
  │
  └─ ServiceNow Connection (Workflow tasks)
        Good for: rich INC fields, search/resolve, PD cross-link
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| Problem notification | Settings integration — Dynatrace pushes Problems to SNOW |
| ServiceNow Connection | Credential used by **Workflow** SNOW actions |
| Not the same object | You cannot set `connectionId = servicenowstg` |
| Your pic | Classic `servicenowstg` (ITSM OFF, ITOM ON) |

## Summary

**Problem notification** and **ServiceNow Connection** are two different Dynatrace features. Notification auto-pushes Problems. Connection lets Workflows create/search/comment/resolve Incidents with fields you control. Below is the full diff and when to use which (or both carefully).

---

## Investigation

Compared your classic UI (`servicenowstg` → silvastg) with Workflow packs that use `snow-create-incident` + Connection (seq 9/13).

## Result

Use the tables below to choose. Common pattern: notification for ITOM **or** Connection for ITSM INC — not both ITSM paths at once.

---

## 1) What each one is

| | Problem notification (Settings) | ServiceNow Connection (Workflow) |
| --- | --- | --- |
| Where in UI | Settings → Integration → Problem notifications | Settings → Connections (or App Connections) + Workflow tasks |
| Your example | `servicenowstg` | e.g. `ServiceNowTest` mapped on tasks |
| What it stores | URL/instance, user/password, message template, ITSM/ITOM toggles, alerting profile | URL + auth (basic or OAuth) for API calls |
| Who uses it | Dynatrace platform (automatic on Problem) | Workflow actions only when a workflow runs |
| File / schema | `builtin:problem.notifications` | Workflow YAML + Connection object |

---

## 2) Total feature diff

| Topic | Problem notification | ServiceNow Connection + Workflow |
| --- | --- | --- |
| Trigger | Problem matches alerting profile | Workflow trigger (Davis Problem filter, schedule, …) |
| Creates ITOM event | Yes if **Send events ITOM = ON** | Not the main job (you call INC APIs) |
| Creates ITSM INC | Yes if **Send incidents ITSM = ON** | Yes via `snow-create-incident` |
| Caller / assignment group / biz service | Limited / platform default mapping | You set in prepare + task inputs (`assignMap`) |
| P3 / P4 logic you define | No (severity from DT message only) | Yes (your JS maps severity → impact/urgency) |
| L1 / L2 / L3 / runbook in ticket | Only if stuffed into description template | Yes — structured in description / fields |
| Dynatrace Problem link | Via placeholders `{ProblemURL}` etc. | Via `problemUrl` in description / PD |
| Search INC later | No workflow search | `snow-search-incidents` (e.g. by correlation_id) |
| Resolve INC on Problem close | Depends on SNOW/DT integration behavior | Explicit `snow-resolve-incident` task |
| Comment / work note | Not a workflow comment task | `snow-comment-on-incident` (PD sync) |
| Parallel with PagerDuty | Separate (notification ≠ PD) | Same workflow: parallel PD + SNOW tasks |
| Sync PD ↔ SNOW | Hard / manual | `correlation_id` + `dedup_key` + cross-link comment |
| Credentials in workflow file | N/A (in Settings) | Connection mapped; password not in YAML |
| Allowlist still needed | Yes (`silvastg.service-now.com`) | Yes (same host) |
| Upload YAML workflow | Not for the notification itself | Yes — workflow template YAML |

---

## 3) Your current notification pic (diff vs Connection)

| Setting on `servicenowstg` | Meaning | Vs Connection workflow |
| --- | --- | --- |
| URL `https://silvastg.service-now.com` | Same instance target | Connection should use same URL |
| User `Tech_DynatraceJP_WS` | Auth for notification push | Connection can use same or OAuth |
| ITSM **OFF** | No classic INC | Workflow can still create INC via Connection |
| ITOM **ON** | Classic **events** still fire | Connection path does not replace ITOM unless you turn ITOM off |
| Message `{State} {ProblemID}: …` | Event/INC text template | Workflow builds richer description in JS |

---

## 4) Side-by-side architecture

### A) Notification only (classic)

```
Problem → servicenowstg → SNOW (ITOM event and/or ITSM INC)
No Workflow SNOW tasks required
```

### B) Connection + Workflow (rich INC + PD)

```
Problem → Workflow
            ├─ snow-create-incident (Connection)
            ├─ PagerDuty
            └─ cross-link comment
```

### C) Both (what you can do safely)

```
Problem
  ├─ servicenowstg ITOM ON  → SNOW event
  └─ Workflow Connection    → SNOW INC + PD
```

**Unsafe:** Classic **ITSM ON** + Workflow **Create Incident** → **duplicate INC**.

---

## 5) Decision guide

| Goal | Use |
| --- | --- |
| Keep simple SNOW notify (events) like your pic | Problem notification only |
| Need assignment, P3/P4, L1–L3, runbook, resolve, PD sync | ServiceNow Connection + Workflow |
| Want events + rich INC + PD | Notification **ITOM ON / ITSM OFF** + Connection workflow (seq 13) |
| Want only PD in workflow; SNOW classic | Notification keep ON + PD-only workflow (seq 12) |

---

## 6) What to configure for each

### Keep / set Problem notification

1. Settings → Problem notifications → `servicenowstg` ON  
2. URL + user + password  
3. ITOM / ITSM toggles as chosen  
4. Alerting profile  
5. Allowlist host  

YAML backup: `../10-classic-snow-notification-pd-workflow/`

### Set ServiceNow Connection + Workflow

1. Settings → Connections → ServiceNow (same silvastg URL)  
2. Upload workflow YAML with SNOW tasks (seq 13)  
3. Map Connection on upload  
4. Fill assignMap / PD key  
5. Classic ITSM OFF if workflow creates INC  
6. Allowlist hosts  

Working files: `../13-working-snow-pd-workflow-yaml/`

---

## 7) One-line diff

| | Notification | Connection |
| --- | --- | --- |
| Job | “Tell SNOW a Problem happened” | “Let Workflows call SNOW APIs my way” |

---

## Data flow map

```
                    ┌─ Problem notification (servicenowstg)
Dynatrace Problem ──┤      → ITOM event / optional classic INC
                    └─ Workflow + Connection
                           → Create/Search/Comment/Resolve INC
                           → optional parallel PagerDuty
```

## Related files

| Path | Why |
| --- | --- |
| `../10-classic-snow-notification-pd-workflow/` | Notification YAML + PD-only |
| `../13-working-snow-pd-workflow-yaml/` | Working SNOW+PD Connection workflows |
| `../11-keep-snow-notification-working/` | How to keep classic notify |
| `14.sh` | Paths |

## Commands

See `14.sh` in this folder.
