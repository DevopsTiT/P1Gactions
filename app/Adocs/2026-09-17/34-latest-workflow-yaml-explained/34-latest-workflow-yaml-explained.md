# Latest Workflow Yaml Explained

```
Latest YAML pack (seq 22 — example data filled)
  │
  ├─ OPEN:  1-open-with-example-data.workflow.yaml
  │         prepare → SNOW create ‖ PD trigger → comment
  └─ CLOSE: 2-close-with-example-data.workflow.yaml
            prepare → SNOW search → resolve ‖ PD resolve
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| Which files | Seq **22** example-filled OPEN + CLOSE (same logic as seq 19, fakes embedded) |
| What they do | Problem open → INC + page; Problem close → resolve both |
| Fake inside | PD key `R03AMPLE...`, SNOW sys_ids `1111…` / `2222…` |
| Still UI-only | Map ServiceNow Connection (`connectionId: ""`) |

## Summary

These two YAML files are Dynatrace Workflow definitions. OPEN runs when a Davis Problem becomes active; CLOSE runs when it closes. Below: every top-level section and every task, in beginner terms.

Paths:

- `/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-17/22-yaml-with-all-example-data/1-open-with-example-data.workflow.yaml`
- `/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-17/22-yaml-with-all-example-data/2-close-with-example-data.workflow.yaml`

---

## Investigation

User asked to explain the latest workflow YAML in detail. Used seq 22 (example-filled Connector + PD pack), which supersedes placeholders in seq 19 for learning.

## Result

Use the section-by-section and task-by-task tables below. Replace fake keys before production.

---

## 1) What a Workflow YAML is

| Idea | What it means |
| --- | --- |
| Workflow YAML | Uploadable definition of trigger + tasks + wiring |
| Task | One step (JS script or ServiceNow Connector action) |
| Predecessor | “Wait for this task before starting” |
| `result("task-name")` | Read output from an earlier task |
| Connection | SNOW login stored in Dynatrace UI, mapped onto snow tasks |

You upload YAML → map Connection → Activate → Problem events run it.

---

## 2) Shared header (both files)

### Comments at top

| Comment topic | Meaning |
| --- | --- |
| FAKE EXAMPLE DATA | Safe demo values; not production secrets |
| Map Connection in UI | `connectionId: ""` is normal until you pick Connection |
| ITSM OFF | Avoid second INC from classic notification |
| Allowlist | `silvastg.service-now.com` + `events.pagerduty.com` |

### `metadata`

| Field | What it means | In this pack |
| --- | --- | --- |
| `dependencies.apps` | Apps the workflow needs | `dynatrace.automations`, `dynatrace.servicenow` |
| `inputs` type connection | Declares SNOW Connection binding | Targets snow task `connectionId` fields |

### `workflow` common fields

| Field | What it means |
| --- | --- |
| `title` / `description` | Name you see in UI |
| `schemaVersion: 3` | Workflow format version |
| `type: STANDARD` | Normal workflow |
| `hourlyExecutionLimit` | Cap runs per hour (`1000` here) |
| `trigger` | When it starts |
| `tasks` | The graph of steps |

---

## 3) OPEN workflow — when it starts

**File:** `1-open-with-example-data.workflow.yaml`  
**Title:** `AGO - Problem to SNOW+PD (EXAMPLE DATA FILLED)`

### Trigger

| Piece | Value | Meaning |
| --- | --- | --- |
| `event.kind` | `DAVIS_PROBLEM` | Only Davis Problems |
| `event.status` | `ACTIVE` | Problem is open |
| `status_transition` | `CREATED` or `UPDATED` or `REOPENED` | New/changed/reopened |
| categories | error, resource, slowdown, availability | Which Problem types |
| `entityTags: {}` | empty | No extra tag filter on trigger |

**Plain English:** When Dynatrace opens (or updates/reopens) an active Problem in those categories, OPEN runs.

### Task graph

```
prepare-payload (y=1)
       │
       ├──────────────────┐
       ▼                  ▼
create-servicenow     create-pagerduty
-incident (y=2)       -incident (y=2)     ← parallel
       │                  │
       └────────┬─────────┘
                ▼
        cross-link-snow-pd (y=3)
```

---

## 4) OPEN task 1 — `prepare-payload`

| Field | Value |
| --- | --- |
| Action | `dynatrace.automations:run-javascript` |
| Predecessors | none (starts first) |
| Job | Read Problem event → build SNOW/PD fields |

### What the script reads from the Problem event

| Event field tried | Used for |
| --- | --- |
| `event.name` / `problem.title` | Title |
| `display_id` / `problem.id` | Problem id |
| `problem.url` | Link back to Dynatrace |
| `problem.severity` | Maps to impact/urgency/PD severity |
| `entity_tags` | Finds `app:EIP` etc. |

### `assignMap` (example data filled)

| App key | Group | Biz | Runbook |
| --- | --- | --- | --- |
| EIP | EIP-Support (`1111…`) | EIP Checkout (`2222…`) | confluence eip |
| CCI | CCI-Support (`3333…`) | CCI FA Comm Calc (`4444…`) | confluence cci |
| default | Ops-Default (`5555…`) | Unknown (`6666…`) | confluence default |

### Severity mapping

| Severity contains | impact | urgency | pLevel | pdSeverity |
| --- | --- | --- | --- | --- |
| AVAILABILITY or CRITICAL | 2 | 2 | P3 | critical |
| ERROR | 2 | 3 | P3 | error |
| else | 3 | 3 | P4 | warning |

### Important outputs

| Output | Example shape | Used by |
| --- | --- | --- |
| `problemId` | `P-240917001` | SNOW correlationId; search later |
| `dedupKey` | `dt-problem-P-240917001` | PagerDuty |
| `assignmentGroupSysId` | from assignMap | SNOW group |
| `shortDescription` | `[Dynatrace] title — app` | SNOW + PD summary |
| `description` | multi-line with L1/L2/L3/runbook | SNOW |
| `impact` / `urgency` | `"2"` / `"3"` | SNOW |
| `pdSeverity` | `error` | PD payload |
| `callerSysId` | `a1b2c3d4…` (example) | returned (caller string used on create) |

---

## 5) OPEN task 2 — `create-servicenow-incident`

| Field | Value |
| --- | --- |
| Action | `dynatrace.servicenow:snow-create-incident` |
| Waits for | `prepare-payload` OK |
| Position | Left branch (parallel with PD) |

### Inputs (Jinja from prepare)

| Input | Expression | Meaning |
| --- | --- | --- |
| `connectionId` | `""` | Map in UI |
| `correlationId` | `result("prepare-payload").problemId` | Find later on close |
| `caller` | prepare.caller | Reporter string |
| `category` / `subCategory` | Software / Application | Classification |
| `impact` / `urgency` | from prepare | Priority drivers |
| `group.id` / `displayName` | assignMap | Assignment group |
| `shortDescription` / `description` | from prepare | Ticket text |

### Under the hood

`POST /api/now/v2/table/incident` via Connector.

### Output used later

| Output | Used by |
| --- | --- |
| `.number` (e.g. `INC0017788`) | cross-link comment task |

---

## 6) OPEN task 3 — `create-pagerduty-incident`

| Field | Value |
| --- | --- |
| Action | `run-javascript` |
| Waits for | `prepare-payload` OK |
| Parallel with | create-servicenow-incident |

### What the script does

| Step | Detail |
| --- | --- |
| 1 | Load prepare result |
| 2 | Set `routingKey` to example `R03AMPLEFAKEROUTINGKEY00000000000` |
| 3 | Build Events API body: `trigger` + `dedup_key` + payload |
| 4 | `fetch` `POST https://events.pagerduty.com/v2/enqueue` |
| 5 | Throw if HTTP not OK |
| 6 | Return `dedupKey` for cross-link |

### Body fields that matter

| Field | Source |
| --- | --- |
| `event_action` | `trigger` |
| `dedup_key` | `p.dedupKey` |
| `payload.summary` | shortDescription |
| `payload.severity` | pdSeverity |
| `custom_details` | problem id, runbook, L1/L2/L3, … |

---

## 7) OPEN task 4 — `cross-link-snow-pd`

| Field | Value |
| --- | --- |
| Action | `snow-comment-on-incident` |
| Waits for | **both** SNOW create OK **and** PD OK |

### Why both predecessors

So the comment can include a real INC number and a real PD dedup key.

### Inputs

| Input | Meaning |
| --- | --- |
| `number` | INC number from create task |
| `comment` | Text with PD dedup + Problem URL + runbook + Problem id |

### Under the hood

`PUT /api/now/v2/table/incident/{sys_id}` (comment on incident).

---

## 8) CLOSE workflow — when it starts

**File:** `2-close-with-example-data.workflow.yaml`  
**Title:** `AGO - Problem closed resolve SNOW+PD (EXAMPLE DATA FILLED)`

### Trigger

| Piece | Meaning |
| --- | --- |
| status CLOSED **or** transition RESOLVED/CLOSED | Problem ended |
| Same categories | Match OPEN coverage |

### Task graph

```
prepare-close-ids (y=1)
       │
       ├──────────────────┐
       ▼                  ▼
search-snow-incident   resolve-pagerduty (y=3)
       │               (can run without waiting for SNOW)
       ▼
resolve-snow-incident (y=3)
  (SKIP if search empty)
```

---

## 9) CLOSE task 1 — `prepare-close-ids`

| Output | Formula / example |
| --- | --- |
| `problemId` | from event display_id |
| `dedupKey` | `"dt-problem-" + problemId` |
| `closeNotes` | `Resolved automatically: Dynatrace Problem closed (P-…)` |

Must match OPEN’s dedup scheme or PD resolve will not clear the same alert.

---

## 10) CLOSE task 2 — `search-snow-incident`

| Field | Value |
| --- | --- |
| Action | `snow-search-incidents` |
| Query | `correlation_id={{ problemId }}` |
| Limit | `1` |
| Fields | `number,sys_id,correlation_id,state` |

### Under the hood

`GET /api/now/v2/table/incident?sysparm_query=...`

---

## 11) CLOSE task 3 — `resolve-snow-incident`

| Field | Value |
| --- | --- |
| Action | `snow-resolve-incident` |
| Condition | search OK **and** result length > 0 |
| else | `SKIP` (no INC found → do not fail hard) |
| `number` | `search[0].number` |
| `resolutionCode` | `Solved (Permanently)` |
| `resolutionNotes` | from prepare-close-ids |

### Under the hood

`PUT /api/now/v2/table/incident/{sys_id}` with resolve fields.

---

## 12) CLOSE task 4 — `resolve-pagerduty`

| Field | Value |
| --- | --- |
| Action | `run-javascript` |
| Waits for | prepare-close-ids only (parallel with SNOW search/resolve path) |
| Key | Same example PD key as OPEN |
| Body | `event_action: resolve` + same `dedup_key` |

So the page can clear even if SNOW search finds nothing (you still fix SNOW manually).

---

## 13) How OPEN and CLOSE stay in sync

| OPEN writes | CLOSE uses |
| --- | --- |
| SNOW `correlationId` = problemId | Search `correlation_id=problemId` |
| PD `dedup_key` = `dt-problem-` + problemId | Resolve with same `dedup_key` |
| Same PD routing key | Same key in CLOSE JS |

---

## 14) What you must still do after upload

| Step | Why |
| --- | --- |
| Map Connection on every snow task | YAML leaves `connectionId: ""` |
| Allowlist both hosts | Outbound calls |
| Classic ITSM OFF | No duplicate INC |
| Replace fake PD key + sys_ids | Example values will not work in real PD/SNOW |
| Activate both workflows | Triggers are `isActive: true` in file but confirm in UI |
| Test one Problem | Check Executions |

---

## 15) Worked micro-example (one Problem)

| Moment | YAML path |
| --- | --- |
| Problem `P-240917001` CREATED, tag `app:EIP`, severity ERROR | OPEN trigger fires |
| prepare | impact 2, urgency 3, group EIP-Support, dedup `dt-problem-P-240917001` |
| snow-create | INC e.g. `INC0017788` |
| PD trigger | page opens |
| cross-link | comment on INC |
| Problem CLOSED | CLOSE trigger |
| search | finds INC by correlation |
| resolve SNOW + PD | both clear |

---

## Data flow map

```
OPEN YAML
  trigger ACTIVE Problem
  → prepare-payload (JS)
  → snow-create-incident ‖ PD fetch trigger
  → snow-comment-on-incident

CLOSE YAML
  trigger CLOSED Problem
  → prepare-close-ids (JS)
  → snow-search → snow-resolve (skip if empty)
  → PD fetch resolve (parallel from prepare)
```

## Related files

| Path | Why |
| --- | --- |
| `../22-yaml-with-all-example-data/` | These YAML files |
| `../19-snow-connector-workflow-again/` | Same logic with placeholders |
| `../21-workflow-parameter-fake-data/` | Parameter tables |
| `../23-architecture-all-apis-involved/` | APIs behind tasks |
| `34.sh` | Paths |

## Commands

See `34.sh` in this folder.
