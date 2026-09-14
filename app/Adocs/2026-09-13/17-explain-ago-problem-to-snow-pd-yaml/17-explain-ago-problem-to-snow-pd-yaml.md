# Explain AGO Problem To Snow PD YAML

```
What is ago-problem-to-snow-pagerduty.workflow-template.yaml?
  │
  ├─ Dynatrace Workflow **template** in YAML (easier to read/edit)
  ├─ Same logic as problem-to-snow-pagerduty.workflow.json
  ├─ Runs on Problem OPEN only (onProblemClose: false)
  ├─ 4 JS tasks: prepare → parallel SNOW+PD → cross-link
  └─ Extra wrapper: version + dependencies.apps
       NOT the close workflow YAML
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| File role | **Create** workflow as a **template YAML** |
| vs JSON twin | Same 4 tasks and scripts; YAML is multi-line and has a template wrapper |
| When it runs | Davis Problem **open** |
| Upload as | Template path in Workflows Upload |
| Before import | Replace `__SNOW_*__` and `__PD_ROUTING_KEY__` |

## Summary

This YAML is the human-friendly twin of the create-workflow JSON. It wraps the workflow under `workflow:` and pins the `dynatrace.automations` app. When a Problem opens, it prepares fields, creates a ServiceNow Incident and a PagerDuty alert in parallel, then cross-links them. Use this file if you want to edit scripts in plain multi-line text; use the JSON if you want the flatter upload shape.

---

## 1. What this file is

| Question | Answer |
| --- | --- |
| Full path | `.../4-snow-pd-workflow-yaml-and-json/ago-problem-to-snow-pagerduty.workflow-template.yaml` |
| Kind | Dynatrace Automation **workflow template** |
| Naming | `ago-` prefix matches other AGO templates (e.g. hosts-on-maintenance style) |
| Job | Problem OPEN → INC + PD + cross-link |
| Twin | `problem-to-snow-pagerduty.workflow.json` (same logic) |
| Sibling close file | `ago-problem-closed-resolve-snow-pd.workflow-template.yaml` |

Header comments in the file already say:

1. Schema like `ago-hosts-on-maintenance.workflow-template.yaml`  
2. Flow: prepare → parallel SNOW + PD → cross-link  
3. Replace placeholders before import  

---

## 2. YAML vs JSON (why two files)

| Topic | This YAML | JSON twin |
| --- | --- | --- |
| Outer shape | `version` + `dependencies` + `inputs` + `workflow:` | Flat workflow object |
| Scripts | Multi-line `script: \|` (readable) | One escaped string with `\n` |
| App pin | `dynatrace.automations` `^1.3301.5` | Not in wrapper |
| Extra JSON-only fields | Usually absent | `isPrivate`, `triggerType` |
| Best for | Editing placeholders and `assignMap` | Direct workflow JSON upload |

**Logic is the same.** Pick **one** format to upload for this create workflow (not both unless you want duplicates).

---

## 3. Outer wrapper (template shell)

```yaml
version: "1"
dependencies:
  apps:
    - name: dynatrace.automations
      version: ^1.3301.5
inputs: []
workflow:
  ...
```

| Field | Meaning |
| --- | --- |
| `version` | Template package version (`"1"`) |
| `dependencies.apps` | App the workflow needs; Automations app pinned to `^1.3301.5` |
| `inputs` | Empty — no extra template inputs |
| `workflow` | The real workflow definition starts here |

On upload as a **template**, Dynatrace uses this wrapper to map required apps/connections.

---

## 4. Inside `workflow:` — settings

| Field | Value | Plain meaning |
| --- | --- | --- |
| `title` | AGO - Problem to ServiceNow and PagerDuty | UI name |
| `description` | On Problem open, create INC + PD… | What it does |
| `schemaVersion` | `4` | Workflow schema |
| `type` | `STANDARD` | Normal event workflow |
| `result` | `null` | No special workflow result object |
| `input` | `{}` | No workflow-level inputs |
| `hourlyExecutionLimit` | `1000` | Cap runs per hour |
| `guide` | `null` | No embedded guide |
| `tasks` | 4 task keys | Automation steps |

---

## 5. Trigger (when it runs)

```yaml
trigger:
  eventTrigger:
    isActive: true
    triggerConfiguration:
      type: davis-problem
      value:
        categories: []
        entityTags: []
        customFilter: null
      onProblemClose: false
      entityTagsMatch: any
      maintenanceWindowTriggerBehavior: never
      triggerOn: null
```

| Setting | Value | Meaning |
| --- | --- | --- |
| `type` | `davis-problem` | Listen to Dynatrace Problems |
| `onProblemClose` | **false** | **OPEN** path only |
| `isActive` | `true` | Trigger on |
| `categories` / `entityTags` | empty | No filter yet — tune after import (e.g. `env:prod`) |
| `entityTagsMatch` | `any` | If you add tags later, match any of them |
| `maintenanceWindowTriggerBehavior` | `never` | Do not special-case maintenance as a trigger |

---

## 6. Task graph

```
prepare-payload                 (x:0, y:0)
       │
       ├──► create-servicenow-incident   (x:0, y:1)
       │
       └──► create-pagerduty-incident    (x:1, y:1)  ← parallel
                    │
                    ▼
           cross-link-snow-pd            (x:0, y:2)
```

| Task | Predecessors | Condition |
| --- | --- | --- |
| `prepare-payload` | none | — |
| `create-servicenow-incident` | prepare | prepare = OK |
| `create-pagerduty-incident` | prepare | prepare = OK |
| `cross-link-snow-pd` | both creates | both = OK |

Every task:

| Field | Value |
| --- | --- |
| `action` | `dynatrace.automations:run-javascript` |
| `active` | `true` |
| `input.script` | Multi-line JavaScript under `\|` |

`position` is only for the visual canvas.

---

## 7. Task 1 — `prepare-payload` (detailed)

**What it is:** First step. Reads the Problem event. Builds one shared object. Does **not** call ServiceNow or PagerDuty.

### 7.1 Read event fields

| Variable | Fallback chain |
| --- | --- |
| title | `event.name` → `problem.title` → `title` |
| problemId | `display_id` → `problem.id` → `event.id` → `pid` |
| problemUrl | `problem.url` → `event.url` → `url` |
| severity | `problem.severity` → … → default `ERROR` |
| tags | `entity_tags` or `tags` |

### 7.2 App detection

`tagValue("app")` or `tagValue("AGO_GLOBAL_APP")` → else `unknown-app`.

### 7.3 `assignMap` (edit for your org)

| App key | Holds |
| --- | --- |
| `EIP` | group, biz service, L1/L2/L3, runbook (+ sys_id placeholders) |
| `CCI` | same shape |
| `default` | fallback when app not in map |

Placeholders inside the map:

- `__SNOW_GROUP_SYS_ID_EIP__` (and CCI / DEFAULT)  
- `__SNOW_BIZ_SYS_ID_EIP__` (and CCI / DEFAULT)  

Also replace runbook URLs (`confluence.example/...`).

### 7.4 Severity → priority

| Severity contains | impact | urgency | pLevel | pdSeverity |
| --- | --- | --- | --- | --- |
| AVAILABILITY or CRITICAL | 2 | 2 | P3 | critical |
| ERROR | 2 | 3 | P3 | error |
| Else | 3 | 3 | P4 | warning |

### 7.5 Return object (shared by later tasks)

| Field | Purpose |
| --- | --- |
| `problemId` | SNOW `correlation_id` |
| `dedupKey` | `dt-problem-` + problemId |
| `callerSysId` | `__SNOW_CALLER_SYS_ID__` |
| group / biz sys_ids + names | SNOW + PD |
| `impact` / `urgency` / `pLevel` | Priority |
| `shortDescription` / `description` | Ticket text (DT link, L1–L3, runbook) |
| `pdSeverity` / `runbookUrl` | PD payload |
| `category` / `subcategory` | Software / Application |

In YAML this script is easy to edit because it is a real multi-line block (`script: |`), not one escaped JSON string.

---

## 8. Task 2 — `create-servicenow-incident`

**What it is:** Creates the ServiceNow **Incident** (INC ticket).

| Item | Detail |
| --- | --- |
| Waits for | `prepare-payload` OK |
| API | `POST {instance}/api/now/v2/table/incident` |
| Auth | Basic: `__SNOW_USER__` / `__SNOW_PASSWORD__` |
| Base URL | `__SNOW_INSTANCE_URL__` |

| Body field | From prepare |
| --- | --- |
| `correlation_id` | `problemId` (needed so close WF can find it) |
| `caller_id` | `callerSysId` |
| `assignment_group` / `business_service` | sys_ids from map |
| `impact` / `urgency` | priority map |
| `category` / `subcategory` | Software / Application |
| `short_description` / `description` | prepared text |

**Returns:** `sysId`, `number` (e.g. `INC0012345`), `raw`.

Comment in file: you may later replace this JS with ServiceNow connector **Create Incident** in the UI so the password is not in the script.

---

## 9. Task 3 — `create-pagerduty-incident` (parallel)

**What it is:** Pages on-call via Events API v2.

| Item | Detail |
| --- | --- |
| Waits for | `prepare-payload` OK only (parallel with SNOW) |
| API | `POST https://events.pagerduty.com/v2/enqueue` |
| Secret | `__PD_ROUTING_KEY__` |

| Field | Value |
| --- | --- |
| `event_action` | `trigger` |
| `dedup_key` | from prepare |
| `payload.summary` / `severity` | short description / pdSeverity |
| `links` | Problem URL + runbook |
| `custom_details` | problem_id, biz, group, P-level, L1–L3, runbook, caller |

**Returns:** `status`, `dedupKey`, `message`, `raw`.

---

## 10. Task 4 — `cross-link-snow-pd`

**What it is:** After both creates succeed, PATCH the INC work notes with the PD key.

| Item | Detail |
| --- | --- |
| Waits for | **both** create tasks OK |
| API | `PATCH .../incident/{sysId}` |
| Body | `work_notes` text with `dedup_key` + Problem URL + runbook |

**Returns:** `incidentNumber`, `incidentSysId`, `pagerDutyDedupKey`, `problemId`.

That is the human-visible sync link on the ticket.

---

## 11. Placeholders checklist

| Placeholder | Where |
| --- | --- |
| `__SNOW_INSTANCE_URL__` | SNOW create + cross-link |
| `__SNOW_USER__` / `__SNOW_PASSWORD__` | SNOW create + cross-link |
| `__SNOW_CALLER_SYS_ID__` | prepare |
| `__SNOW_GROUP_SYS_ID_*__` | assignMap |
| `__SNOW_BIZ_SYS_ID_*__` | assignMap |
| `__PD_ROUTING_KEY__` | PD create |

Also edit `assignMap` app names, L1–L3 labels, and runbook URLs.

---

## 12. How to use this YAML

| Step | Action |
| --- | --- |
| 1 | Edit placeholders + `assignMap` in this file |
| 2 | Dynatrace → Workflows → **Upload** |
| 3 | Choose YAML → treated as **template** → map apps/connections → Import |
| 4 | Confirm trigger is Problem open; set workflow **Active** |
| 5 | Also upload/import the **close** YAML for resolve |

Do **not** also upload the create JSON for the same purpose unless you want two create workflows.

---

## 13. Data flow map

```
[Davis Problem OPEN]
        │
        ▼
[This YAML template → create workflow]
  prepare-payload
        │
        ├─► SNOW POST /incident   → INC (correlation_id)
        └─► PD POST /enqueue      → alert (dedup_key)
                │
                ▼
         cross-link PATCH work_notes
```

---

## Related files

| Path | Why |
| --- | --- |
| This YAML | Create template you asked about |
| `problem-to-snow-pagerduty.workflow.json` | Same create logic as JSON |
| `../16-explain-problem-to-snow-pd-json/` | Detailed JSON twin explain |
| `ago-problem-closed-resolve-snow-pd.workflow-template.yaml` | Close twin |
| `17.sh` | Inspect reminders |

## Commands

See `17.sh` in this folder.
