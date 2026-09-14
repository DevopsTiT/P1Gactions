# Monitor SNOW PD Demo Steps

```
Ready to demo Problem → ServiceNow + PagerDuty?
  │
  ├─ Prep done? (workflows Active, placeholders filled)
  │     No → finish seq 5 setup first
  │     Yes ↓
  ├─ Open 3 windows: Dynatrace + ServiceNow + PagerDuty
  ├─ Fire a test Problem (or safe manual run)
  ├─ Watch create workflow Executions (4 tasks OK)
  ├─ Verify INC + PD page + work notes
  ├─ Close the Problem
  ├─ Watch close workflow Execution
  └─ Verify INC Resolved + PD resolved
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What “monitor a demo” means | Watch Dynatrace, ServiceNow, and PagerDuty together while one Problem opens and closes |
| Windows to keep open | Workflows Executions, Problems, ServiceNow INC list, PagerDuty Incidents |
| Pass create | All 4 open tasks OK; one INC; one PD page; work notes show `dedup_key` |
| Pass close | Close workflow OK; INC Resolved; PD resolved with same key |
| Safe rule | Use non-prod / demo service / quiet hours so you do not page real on-call by accident |

## Summary

A demo is successful when one Dynatrace Problem creates matching tickets in ServiceNow and PagerDuty, and closing that Problem resolves both. You monitor by watching Workflow Executions plus the two external tools side by side. Setup must already be done (upload, placeholders, Active workflows).

---

## Before the demo (5 minutes)

Do these once. If any fail, stop and fix setup (`../5-setup-snow-pd-workflow-steps-perms/`).

| Check | Pass when |
| --- | --- |
| Open workflow exists and **Active** | Trigger = Problem open (`onProblemClose` false) |
| Close workflow exists and **Active** | Trigger = Problem close (`onProblemClose` true) |
| Placeholders replaced | No leftover `__SNOW_*__` or `__PD_ROUTING_KEY__` |
| External hosts allowed | SNOW instance + `events.pagerduty.com` |
| Demo PD service | Routing key points to a **demo / low-noise** service if possible |
| App tag ready | Test host/service has `app:EIP` (or a key in your `assignMap`) |

### Open three browser windows

| Window | Where to go |
| --- | --- |
| A — Dynatrace Workflows | Workflows → your create + close workflows → **Executions** |
| B — Dynatrace Problems | Problems (or Problems Classic) filtered to your demo app/env |
| C — ServiceNow | Incident list; filter later by short description `[Dynatrace]` |
| D — PagerDuty | Incidents / Alerts for the demo service |

(Four windows is fine; at least Dynatrace + SNOW + PD.)

---

## Step-by-step: run and monitor the demo

### Step 1 — Announce and note start time

Write down:

| Note | Example |
| --- | --- |
| Start time | 18:50 JST |
| Demo env | non-prod |
| Expected app tag | `app:EIP` |
| Who is watching PD | You (mute phone if needed) |

### Step 2 — Trigger a Problem open

Pick **one** safe method:

| Method | How | When to use |
| --- | --- | --- |
| Real test Problem | Break a demo check or raise a known alert in non-prod so Davis opens a Problem | Best end-to-end demo |
| Existing open Problem | Use a Problem you control that matches your trigger filters | Faster if filters already match |
| Manual workflow run | Workflow editor → Run (only if UI lets you inject a sample Problem event) | Good for task debug; weaker as “full” demo |

Wait until Dynatrace shows a **new Active Problem** with an ID (example shape: `P-…`). Copy that **Problem ID** and **Problem URL** into your notes.

### Step 3 — Monitor the create workflow (Dynatrace)

1. Go to **Workflows →** create workflow → **Executions**
2. Find a run near your start time
3. Open it and check each task

| Task | What “good” looks like |
| --- | --- |
| `prepare-payload` | OK; result has `problemId`, `dedupKey` (`dt-problem-…`), app, impact/urgency |
| `create-servicenow-incident` | OK; result has `number` (INC…) and `sysId` |
| `create-pagerduty-incident` | OK; result has same `dedupKey` |
| `cross-link-snow-pd` | OK; returns INC number + PD key |

**If a task is red:** open the task log, read the HTTP error, fix that system first (auth, host allow list, bad sys_id), then re-test. Do not close the Problem until create is healthy (or you will confuse the demo story).

### Step 4 — Monitor ServiceNow

1. Search incidents: `correlation_id=<ProblemID>` **or** short description contains `[Dynatrace]`
2. Open the INC

| Field / place | Expect |
| --- | --- |
| `correlation_id` | Exact Dynatrace Problem ID |
| Short description | Starts with `[Dynatrace]` + title + app |
| Description | Business service, app, P3/P4, Problem URL, L1/L2/L3, runbook |
| Assignment group / business service | Matches your `assignMap` for that app |
| Work notes | Contains `PagerDuty sync: dedup_key=dt-problem-…` |

Copy the **INC number** next to the Problem ID in your notes.

### Step 5 — Monitor PagerDuty

1. Open the demo service → Incidents / Alerts
2. Find the alert triggered around your start time

| Check | Expect |
| --- | --- |
| Summary | Same story as INC short description |
| Dedup / event key | `dt-problem-<ProblemID>` |
| Links | Dynatrace Problem URL and/or runbook |
| Custom details | problem_id, app, L1–L3 if shown |

Copy confirmation that PD is open/triggered.

### Step 6 — Speak the create success (demo script)

Say (or show slide):

1. Dynatrace Problem `P-…` opened  
2. Workflow Executions: 4/4 OK  
3. ServiceNow `INC…` created with same Problem ID  
4. PagerDuty paged with same `dedup_key`  
5. Work notes link SNOW ↔ PD  

### Step 7 — Trigger Problem close

In Dynatrace, **close / resolve** that same Problem (however your tenant allows: close Problem, fix underlying alert so Davis closes it).

Note close time.

### Step 8 — Monitor the close workflow

1. Workflows → **close** workflow → **Executions**
2. Open the new run

| Check | Expect |
| --- | --- |
| Task `resolve-snow-and-pd` | OK |
| Result `problemId` | Same as open |
| Result `dedupKey` | `dt-problem-<same id>` |
| Result `snow` | `ok: true` with INC number (or `skipped` if INC missing — that is a fail for demo) |

### Step 9 — Confirm SNOW and PD closed

| System | Pass |
| --- | --- |
| ServiceNow | INC **Resolved** (state 6); close notes mention Dynatrace Problem closed |
| PagerDuty | Alert/incident **resolved** (not still triggered) |

### Step 10 — Speak the close success

1. Same Problem closed in Dynatrace  
2. Close workflow ran once  
3. Same INC resolved  
4. Same PD alert resolved via same `dedup_key`  

That is the full demo loop.

---

## Live monitoring checklist (print this)

### Create half

- [ ] Problem ID noted
- [ ] Create execution found
- [ ] `prepare-payload` OK
- [ ] SNOW create OK → INC number noted
- [ ] PD create OK → dedup key noted
- [ ] Cross-link OK → work notes show dedup key
- [ ] INC `correlation_id` matches Problem ID
- [ ] PD key is `dt-problem-<ProblemID>`

### Close half

- [ ] Problem closed
- [ ] Close execution found
- [ ] Resolve task OK
- [ ] INC Resolved
- [ ] PD resolved

---

## If something fails during the demo

```
Create workflow red?
  → prepare failed → event fields / script error
  → SNOW failed → URL, user, ACL, external host, bad sys_id
  → PD failed → routing key, external host, Events API body
  → cross-link failed → INC/PD exist but comment PATCH failed (retry / ACL)

No execution at all?
  → workflow not Active
  → trigger filter too strict (tags/categories)
  → wrong workflow (open vs close)
  → Problem did not match davis-problem trigger

Close did nothing?
  → close workflow not Active / onProblemClose false by mistake
  → correlation_id empty on create
  → dedup_key formula differs between open and close
```

| Symptom | First place to look |
| --- | --- |
| No workflow run | Trigger Active + filters |
| SNOW 401/403 | User password or IP allow list |
| SNOW 400 on sys_id | Wrong caller/group/biz sys_id |
| PD 400/401 | Bad routing key |
| INC stays open after Problem close | Close workflow execution log |
| PD stays open | Same `dedup_key` used on resolve? |

---

## Data flow map (what you are watching)

```
You trigger Problem OPEN
        │
        ▼
[Dynatrace Executions — create WF]
  prepare → SNOW POST → PD trigger → cross-link
        │                │
        ▼                ▼
[ServiceNow INC]   [PagerDuty alert]
  correlation_id      dedup_key
        │
You close Problem
        │
        ▼
[Dynatrace Executions — close WF]
        ├─► resolve INC
        └─► resolve PD
```

---

## Related files

| Path | Why |
| --- | --- |
| `../5-setup-snow-pd-workflow-steps-perms/` | Full setup + permissions before demo |
| `../4-snow-pd-workflow-yaml-and-json/` | Files you uploaded |
| `../10-snow-pd-keep-in-sync/` | Why keys keep SNOW/PD aligned |
| `../11-explain-four-workflow-files/` | What each file does |
| `12.sh` | Optional inspect reminders |

## Commands

See `12.sh` in this folder (notes only; no auto-run required).
