# Explain Four Workflow Files

```
What are these 4 files?
  │
  ├─ Same logic, two formats × two lifecycle moments
  │
  ├─ Problem OPEN (create INC + page)
  │     → ago-problem-to-snow-pagerduty.workflow-template.yaml
  │     → problem-to-snow-pagerduty.workflow.json
  │
  ├─ Problem CLOSED (resolve both)
  │     → ago-problem-closed-resolve-snow-pd.workflow-template.yaml
  │     → problem-closed-resolve-snow-pd.workflow.json
  │
  └─ Pick ONE format per import
        YAML = template (easier to read/edit)
        JSON = full workflow upload shape
        Do NOT merge open + close into one file
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| How many workflows? | Two (open + close) |
| Why four files? | Each workflow has YAML template + JSON twin |
| Logic same? | Yes — scripts and task graph match |
| Open file does | Prepare → parallel SNOW + PD → cross-link |
| Close file does | Find INC by `correlation_id` → resolve INC + PD |
| Before upload | Replace all `__SNOW_*__` and `__PD_ROUTING_KEY__` |

## Summary

These four files are the upload pack for Dynatrace Workflows that turn a Davis Problem into a ServiceNow Incident and a PagerDuty page, then resolve both when the Problem closes. YAML and JSON are the same automation written two ways. You upload two workflows (open and close), choosing either YAML or JSON for each — not all four into one workflow.

---

## 1. What each file is

| File | Role | When it runs |
| --- | --- | --- |
| `ago-problem-to-snow-pagerduty.workflow-template.yaml` | Create workflow as **template YAML** | Problem open (`onProblemClose: false`) |
| `problem-to-snow-pagerduty.workflow.json` | Same create workflow as **JSON** | Same |
| `ago-problem-closed-resolve-snow-pd.workflow-template.yaml` | Resolve workflow as **template YAML** | Problem close (`onProblemClose: true`) |
| `problem-closed-resolve-snow-pd.workflow.json` | Same resolve workflow as **JSON** | Same |

### YAML vs JSON (same logic)

| Topic | YAML template | JSON workflow |
| --- | --- | --- |
| Wrapper | `version`, `dependencies.apps`, then `workflow:` | Flat workflow object |
| Scripts | Multi-line `|` blocks (readable) | One escaped string with `\n` |
| Extra JSON fields | Usually not present | `isPrivate`, `triggerType` |
| App pin | `dynatrace.automations` `^1.3301.5` | Not in wrapper (runtime uses tenant apps) |
| Best for | Humans editing placeholders | Direct Workflow upload / API shape |

**Rule:** Pick YAML **or** JSON for a given import. Do not upload both for the same workflow unless you intentionally want two copies.

---

## 2. Shared shell (both open and close)

Every file is a Dynatrace **STANDARD** workflow with:

| Setting | Value | What it means |
| --- | --- | --- |
| `schemaVersion` | `4` | Current workflow schema |
| `type` | `STANDARD` | Normal event workflow |
| `hourlyExecutionLimit` | `1000` | Cap runs per hour |
| Trigger type | `davis-problem` | Fires on Davis Problems |
| Task action | `dynatrace.automations:run-javascript` | Each task is JS that can `fetch` APIs |
| Placeholders | `__SNOW_*__`, `__PD_ROUTING_KEY__` | Must replace before real use |

Difference that matters:

| Setting | Open workflow | Close workflow |
| --- | --- | --- |
| `onProblemClose` | `false` | `true` |
| Task count | 4 tasks | 1 task |

```
Davis Problem lifecycle
  OPEN  ──► create workflow (4 tasks)
  CLOSE ──► resolve workflow (1 task)
```

---

## 3. Open workflow — detailed task walkthrough

Files: `ago-problem-to-snow-pagerduty.workflow-template.yaml` and `problem-to-snow-pagerduty.workflow.json`

```
prepare-payload
       │
       ├──► create-servicenow-incident ──┐
       │                                 ├──► cross-link-snow-pd
       └──► create-pagerduty-incident ───┘
```

| Task | Waits for | Purpose |
| --- | --- | --- |
| `prepare-payload` | (start) | Read Problem event; build shared payload |
| `create-servicenow-incident` | prepare OK | POST ServiceNow INC |
| `create-pagerduty-incident` | prepare OK | POST PagerDuty trigger (parallel with SNOW) |
| `cross-link-snow-pd` | both creates OK | Write PD key into INC work notes |

### Task A — `prepare-payload`

**What this is:** The “brain” step. It does not call ServiceNow or PagerDuty yet. It turns the Dynatrace Problem event into one clean object both later tasks reuse.

| Reads from event | Fallback chain |
| --- | --- |
| Title | `event.name` → `problem.title` → `title` |
| Problem ID | `display_id` → `problem.id` → `event.id` → `pid` |
| Problem URL | `problem.url` → `event.url` → `url` |
| Severity | `problem.severity` → `event.severity` → `severity` |
| Tags | `entity_tags` or `tags` |

**App detection:** Looks for tag `app:` or `AGO_GLOBAL_APP:`. Example: `app:EIP` → app = `EIP`.

**`assignMap`:** Local lookup table per app (EIP, CCI, default). For each app it stores:

| Field in map | Used for |
| --- | --- |
| `groupName` / `groupSysId` | Assignment group (name for PD; sys_id for SNOW) |
| `bizName` / `bizSysId` | Business service |
| `l1` / `l2` / `l3` | Support ladder text in description |
| `runbook` | Confluence/SOP URL |

**Priority mapping (simple):**

| Problem severity contains | SNOW impact/urgency | Intent label | PD severity |
| --- | --- | --- | --- |
| AVAILABILITY or CRITICAL | 2 / 2 | P3 | critical |
| ERROR | 2 / 3 | P3 | error |
| Otherwise | 3 / 3 | P4 | warning |

**Returns (important fields):**

| Output field | Example use |
| --- | --- |
| `problemId` | SNOW `correlation_id` |
| `dedupKey` | `dt-problem-<problemId>` for PD |
| `shortDescription` / `description` | INC text |
| `impact` / `urgency` | SNOW priority inputs |
| `assignmentGroupSysId` / `businessServiceSysId` | SNOW reference fields |
| `pdSeverity` / `runbookUrl` / L1–L3 | PD custom details + links |

### Task B — `create-servicenow-incident`

**What this is:** Creates one Incident in ServiceNow using the Table API.

| Item | Value |
| --- | --- |
| API | `POST {SNOW}/api/now/v2/table/incident` |
| Auth | Basic auth from `__SNOW_USER__` / `__SNOW_PASSWORD__` |
| Parallel with | `create-pagerduty-incident` |

| Body field | Source | Why you care |
| --- | --- | --- |
| `correlation_id` | `p.problemId` | Later close finds this INC |
| `caller_id` | `__SNOW_CALLER_SYS_ID__` | Who opened the ticket |
| `assignment_group` | app map sys_id | Who owns it |
| `business_service` | app map sys_id | Which service |
| `impact` / `urgency` | severity map | Priority |
| `short_description` / `description` | prepare text | Human story + runbook |

**Returns:** `sysId`, `number` (e.g. INC0012345) for cross-link and audit.

### Task C — `create-pagerduty-incident`

**What this is:** Pages on-call via PagerDuty Events API v2.

| Item | Value |
| --- | --- |
| API | `POST https://events.pagerduty.com/v2/enqueue` |
| Action | `event_action: trigger` |
| Key | `dedup_key: p.dedupKey` |

| Payload part | Meaning |
| --- | --- |
| `routing_key` | Integration key (`__PD_ROUTING_KEY__`) |
| `summary` | Same short story as INC |
| `severity` | critical / error / warning |
| `links` | Problem URL + runbook |
| `custom_details` | problem_id, biz, group, P-level, L1–L3 |

**Returns:** `dedupKey` (must match prepare) for cross-link and later resolve.

### Task D — `cross-link-snow-pd`

**What this is:** After both creates succeed, PATCH the INC and put the PD key in work notes so a human can see the page identity on the ticket.

| Item | Value |
| --- | --- |
| API | `PATCH .../incident/{sysId}` |
| Body | `work_notes` with `dedup_key` + Problem URL + runbook |
| Condition | Both create tasks must be `OK` |

**Returns:** INC number, sys_id, PD dedup key, Problem ID (final sync snapshot).

---

## 4. Close workflow — detailed task walkthrough

Files: `ago-problem-closed-resolve-snow-pd.workflow-template.yaml` and `problem-closed-resolve-snow-pd.workflow.json`

```
Problem CLOSED (onProblemClose: true)
        │
        ▼
resolve-snow-and-pd
  1) problemId from event
  2) dedupKey = dt-problem- + problemId
  3) GET SNOW incidents where correlation_id = problemId
  4) If found → PATCH state=6 (Resolved) + close notes
  5) Always → PD event_action=resolve with same dedup_key
```

| Step | What happens | If it fails / missing |
| --- | --- | --- |
| Read Problem ID | Same fallback chain as open | Wrong ID → wrong ticket |
| Build `dedupKey` | Must match open’s key | Mismatch → PD stays open |
| Search SNOW | `sysparm_query=correlation_id=<id>` | No INC → `snow.skipped=true`, still try PD |
| Resolve SNOW | `state: "6"`, close code/notes | HTTP error → task throws |
| Resolve PD | `event_action: resolve` | HTTP error → task throws |

**Why one task:** Close is a short linear path (find → resolve → resolve). No parallel create needed.

---

## 5. Placeholders you must replace

| Placeholder | Where | Meaning |
| --- | --- | --- |
| `__SNOW_INSTANCE_URL__` | SNOW tasks | e.g. `https://yourcompany.service-now.com` |
| `__SNOW_USER__` / `__SNOW_PASSWORD__` | SNOW tasks | API user (prefer Connection in UI later) |
| `__SNOW_CALLER_SYS_ID__` | prepare | Caller user sys_id |
| `__SNOW_GROUP_SYS_ID_*__` | prepare map | Assignment group sys_ids |
| `__SNOW_BIZ_SYS_ID_*__` | prepare map | Business service sys_ids |
| `__PD_ROUTING_KEY__` | PD tasks | Events API v2 integration key |

Also edit `assignMap` apps, L1/L2/L3 names, and runbook URLs for your org.

---

## 6. How open and close lock together

```
OPEN prepare:  problemId = P-123
               dedupKey  = dt-problem-P-123
OPEN SNOW:     correlation_id = P-123
OPEN PD:       dedup_key = dt-problem-P-123
OPEN cross:    work_notes mention that dedup_key

CLOSE:         problemId = P-123
               find INC by correlation_id
               PD resolve dedup_key = dt-problem-P-123
```

If either key formula changes between open and close, sync breaks.

---

## 7. Data flow map

```
[Davis Problem OPEN]
        │
        ▼
[prepare-payload] ── builds problemId, dedupKey, fields
        │
        ├─► [ServiceNow POST /incident] ── INC + correlation_id
        │              │
        └─► [PagerDuty POST /enqueue trigger]
                       │
                       ▼
              [cross-link PATCH work_notes]

[Davis Problem CLOSED]
        │
        ▼
[resolve-snow-and-pd]
        ├─► GET INC by correlation_id → PATCH Resolved
        └─► POST PD resolve (same dedup_key)
```

---

## 8. Practical upload choice

| Goal | Do this |
| --- | --- |
| Easiest to read/edit | Start with the two YAML templates |
| Match API/export shape | Use the two JSON files |
| Production | Upload **create** once + **close** once |
| Secrets | Prefer Dynatrace Connection for SNOW after import |

---

## Related files

| Path | Why |
| --- | --- |
| `../4-snow-pd-workflow-yaml-and-json/` | The four source files |
| `../10-snow-pd-keep-in-sync/` | How SNOW/PD stay aligned |
| `../9-one-or-two-workflow-files/` | Why open/close stay separate |
| `../8-dynatrace-snow-pd-detailed-design/` | Full architecture |
| `11.sh` | Inspect one-liners |

## Commands

See `11.sh` in this folder.
