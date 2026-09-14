# Explain Problem To Snow PD JSON

```
What is problem-to-snow-pagerduty.workflow.json?
  │
  ├─ Dynatrace Workflow upload file (JSON format)
  ├─ Runs only when a Problem OPENS (onProblemClose: false)
  ├─ 4 JavaScript tasks: prepare → parallel SNOW+PD → cross-link
  └─ Twin of the YAML template (same logic, different format)
       Does NOT resolve on close (that is the other JSON file)
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| File role | **Create** workflow only (Problem open → INC + PD page) |
| Format | Full workflow JSON for Dynatrace Upload |
| Trigger | `davis-problem` with `onProblemClose: false` |
| Tasks | 4 × `run-javascript` |
| Parallelism | SNOW and PD both wait only on `prepare-payload` |
| Before use | Replace every `__SNOW_*__` and `__PD_ROUTING_KEY__` |

## Summary

This JSON file is the Dynatrace Workflow that runs when a Davis Problem opens. It prepares ticket fields from the Problem event, creates a ServiceNow Incident and a PagerDuty alert in parallel, then writes the PagerDuty key into the Incident work notes. It does not handle Problem close — that is `problem-closed-resolve-snow-pd.workflow.json`.

---

## 1. What this file is

| Question | Answer |
| --- | --- |
| What is it? | A Dynatrace **Workflow** definition saved as JSON |
| What do you do with it? | **Upload** it in Workflows (or use API create) |
| What does it automate? | Problem open → ServiceNow INC + PagerDuty page + cross-link |
| Twin file | `ago-problem-to-snow-pagerduty.workflow-template.yaml` (same logic, easier to read) |
| Not this file | Close/resolve workflow |

Path:

`Daily Files/2026-09-13/4-snow-pd-workflow-yaml-and-json/problem-to-snow-pagerduty.workflow.json`

---

## 2. Top-level JSON (the shell)

| Field | Value in file | Plain meaning |
| --- | --- | --- |
| `title` | AGO - Problem to ServiceNow and PagerDuty | Name you see in Workflows UI |
| `description` | On Problem open, create INC + PD… | Human summary |
| `isPrivate` | `true` | Not shared as a public template by default |
| `triggerType` | `Event` | Starts from an event (not cron/manual only) |
| `schemaVersion` | `4` | Workflow schema version Dynatrace expects |
| `type` | `STANDARD` | Normal workflow (not a special subtype) |
| `input` | `{}` | No extra workflow-level inputs |
| `hourlyExecutionLimit` | `1000` | Cap how many times it can run per hour |
| `trigger` | object | When it starts (see next section) |
| `tasks` | object | The four steps |

---

## 3. Trigger (when it runs)

```json
"trigger": {
  "eventTrigger": {
    "isActive": true,
    "triggerConfiguration": {
      "type": "davis-problem",
      "onProblemClose": false,
      ...
    }
  }
}
```

| Setting | Value | Meaning |
| --- | --- | --- |
| `type` | `davis-problem` | Listen to Dynatrace Problems |
| `onProblemClose` | **false** | Fire on **open**, not close |
| `isActive` | `true` | Trigger is enabled in the file |
| `categories` / `entityTags` | empty arrays | No extra filter yet (tune in UI) |
| `maintenanceWindowTriggerBehavior` | `never` | Do not run just because of maintenance window behavior |

**Beginner takeaway:** This file is the **OPEN** half only.

---

## 4. Task graph (how the four steps connect)

```
prepare-payload          (x:0,y:0)  no predecessors
       │
       ├──► create-servicenow-incident   (x:0,y:1)
       │
       └──► create-pagerduty-incident    (x:1,y:1)   ← same row = parallel
                    │
                    ▼
           cross-link-snow-pd            (x:0,y:2)  waits for BOTH
```

| Task ID | Waits for | Runs when |
| --- | --- | --- |
| `prepare-payload` | (nothing) | Workflow starts |
| `create-servicenow-incident` | prepare | prepare state = OK |
| `create-pagerduty-incident` | prepare | prepare state = OK |
| `cross-link-snow-pd` | both creates | both create states = OK |

All four use:

`action: dynatrace.automations:run-javascript`

That means each step is a JavaScript function that can call HTTP APIs with `fetch`.

`position` x/y is only for the visual editor layout.

---

## 5. Task 1 — `prepare-payload` (detailed)

**What it is:** The brain. No ServiceNow or PagerDuty call. Builds one object for later tasks.

### 5.1 Read the Problem event

| Variable | Tries these event fields (in order) |
| --- | --- |
| `title` | `event.name` → `problem.title` → `title` |
| `problemId` | `display_id` → `problem.id` → `event.id` → `pid` |
| `problemUrl` | `problem.url` → `event.url` → `url` |
| `severity` | `problem.severity` → `event.severity` → `severity` (default ERROR) |
| tags | `entity_tags` or `tags` |

### 5.2 Detect app

Looks for tag `app:` or `AGO_GLOBAL_APP:`. Example: `app:EIP` → `app = "EIP"`.

### 5.3 `assignMap` (org lookup table)

Hard-coded map for EIP, CCI, and `default`. Each row has:

| Map field | Used for |
| --- | --- |
| `groupName` / `groupSysId` | Assignment group (name for PD; sys_id for SNOW) |
| `bizName` / `bizSysId` | Business service |
| `l1` / `l2` / `l3` | Support ladder text |
| `runbook` | SOP URL |

**You must replace** `__SNOW_GROUP_SYS_ID_*__` and `__SNOW_BIZ_SYS_ID_*__` with real ServiceNow sys_ids, and fix runbook URLs.

### 5.4 Severity → priority

| If severity contains | impact | urgency | pLevel | pdSeverity |
| --- | --- | --- | --- | --- |
| AVAILABILITY or CRITICAL | 2 | 2 | P3 | critical |
| ERROR | 2 | 3 | P3 | error |
| Otherwise | 3 | 3 | P4 | warning |

### 5.5 What it returns (shared payload)

| Output field | Why it matters |
| --- | --- |
| `problemId` | Becomes SNOW `correlation_id` |
| `dedupKey` | `dt-problem-` + problemId for PagerDuty |
| `callerSysId` | SNOW caller (`__SNOW_CALLER_SYS_ID__`) |
| `assignmentGroupSysId` / `businessServiceSysId` | SNOW assignment fields |
| `impact` / `urgency` | SNOW priority inputs |
| `shortDescription` / `description` | Ticket text (includes L1–L3 + runbook + Problem URL) |
| `pdSeverity` / `app` / names | PagerDuty payload |
| `category` / `subcategory` | Software / Application |

Later tasks call: `await ex.result("prepare-payload")`.

---

## 6. Task 2 — `create-servicenow-incident` (detailed)

**What it is:** Creates one ServiceNow **Incident** (INC ticket).

| Item | In this file |
| --- | --- |
| Predecessor | `prepare-payload` only |
| API | `POST {SNOW}/api/now/v2/table/incident` |
| Auth | Basic auth from `__SNOW_USER__` / `__SNOW_PASSWORD__` |
| Base URL | `__SNOW_INSTANCE_URL__` |

### Body fields sent

| SNOW field | Source |
| --- | --- |
| `correlation_id` | `p.problemId` (critical for close workflow later) |
| `caller_id` | `p.callerSysId` |
| `category` / `subcategory` | from prepare |
| `impact` / `urgency` | from prepare |
| `assignment_group` | `p.assignmentGroupSysId` |
| `business_service` | `p.businessServiceSysId` |
| `short_description` | `p.shortDescription` |
| `description` | `p.description` |

### Returns

| Field | Meaning |
| --- | --- |
| `sysId` | Internal ServiceNow UUID (for PATCH later) |
| `number` | Human INC number, e.g. `INC0012345` |
| `raw` | Full API result |

If HTTP is not OK → throws error → task fails (cross-link will not run).

---

## 7. Task 3 — `create-pagerduty-incident` (detailed)

**What it is:** Pages on-call via PagerDuty Events API v2.

| Item | In this file |
| --- | --- |
| Predecessor | `prepare-payload` only (parallel with SNOW) |
| API | `POST https://events.pagerduty.com/v2/enqueue` |
| Key secret | `__PD_ROUTING_KEY__` |

### Body essentials

| Field | Value |
| --- | --- |
| `routing_key` | PD integration key |
| `event_action` | `trigger` (open/page) |
| `dedup_key` | `p.dedupKey` |
| `client` / `client_url` | Dynatrace + Problem URL |
| `links` | Problem URL + runbook |
| `payload.summary` | short description |
| `payload.severity` | `pdSeverity` |
| `payload.source` / `component` | app |
| `custom_details` | problem_id, biz, group, P-level, L1–L3, runbook, caller |

### Returns

| Field | Meaning |
| --- | --- |
| `status` | PD response status |
| `dedupKey` | Key to use in cross-link / later resolve |
| `message` / `raw` | Response details |

---

## 8. Task 4 — `cross-link-snow-pd` (detailed)

**What it is:** After both creates succeed, update the INC with a work note that shows the PD key.

| Item | In this file |
| --- | --- |
| Predecessors | **both** create tasks |
| Conditions | both must be OK |
| API | `PATCH {SNOW}/api/now/v2/table/incident/{sysId}` |
| Body | `{ work_notes: "PagerDuty sync: dedup_key=… \| Dynatrace Problem=… \| Runbook=…" }` |

### Returns (final snapshot)

| Field | Meaning |
| --- | --- |
| `incidentNumber` | INC###### |
| `incidentSysId` | sys_id |
| `pagerDutyDedupKey` | dt-problem-… |
| `problemId` | Dynatrace Problem ID |

---

## 9. Placeholders you must replace

| Placeholder | Where | Meaning |
| --- | --- | --- |
| `__SNOW_INSTANCE_URL__` | SNOW + cross-link scripts | e.g. `https://company.service-now.com` |
| `__SNOW_USER__` / `__SNOW_PASSWORD__` | SNOW + cross-link | API user (prefer Connection later) |
| `__SNOW_CALLER_SYS_ID__` | prepare return | Caller user |
| `__SNOW_GROUP_SYS_ID_*__` | assignMap | Assignment groups |
| `__SNOW_BIZ_SYS_ID_*__` | assignMap | Business services |
| `__PD_ROUTING_KEY__` | PD script | Events API v2 key |

Also edit EIP/CCI/default names and runbook URLs in `assignMap`.

---

## 10. How this JSON relates to the other files

| File | Relationship |
| --- | --- |
| `ago-problem-to-snow-pagerduty.workflow-template.yaml` | Same create logic, YAML template form |
| `problem-closed-resolve-snow-pd.workflow.json` | **Different** workflow: Problem close → resolve INC + PD |
| This JSON alone | Incomplete lifecycle — upload close JSON too |

---

## 11. Data flow map

```
[Davis Problem OPEN]
        │
        ▼
[This JSON workflow execution]
  prepare-payload
        │
        ├─► POST ServiceNow /incident  → INC (correlation_id=problemId)
        │
        └─► POST PagerDuty /enqueue    → alert (dedup_key=dt-problem-…)
                │
                ▼
         PATCH INC work_notes (cross-link)
```

---

## Related files

| Path | Why |
| --- | --- |
| `../4-snow-pd-workflow-yaml-and-json/problem-to-snow-pagerduty.workflow.json` | This file |
| `../11-explain-four-workflow-files/` | All four files overview |
| `../14-explain-demo-flow-plain-english/` | Story of open/close |
| `../15-what-is-snow-inc/` | What INC means |
| `16.sh` | Inspect reminders |

## Commands

See `16.sh` in this folder.
