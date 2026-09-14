# How To Open Close Workflow Flow

```
Want this exact flow working?
  │
  ├─ 0 Collect prerequisites (SNOW fields + assignMap + PD key)
  ├─ 1 Upload / create TWO workflows (open + close)
  ├─ 2 Build prepare-payload (maps)
  ├─ 3 Wire parallel SNOW + PD
  ├─ 4 Wire cross-link (waits for both)
  ├─ 5 Build close: find by correlation_id → resolve both
  └─ 6 Test open then close
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What you build | Two Dynatrace workflows matching your diagram |
| Open path | prepare → parallel SNOW+PD → cross-link |
| Close path | find INC by `correlation_id` → resolve SNOW + PD |
| SNOW fields (§4.2) | caller, business service, assignment, P3/P4, description with DT link / L1–L3 / runbook, `correlation_id` |
| Maps (§4.4) | `app` tag → group / biz / L1–L3 / runbook inside `prepare-payload` |
| PD need | Events API v2 `routing_key` + stable `dedup_key` |

## Summary

Do the prerequisites once, then implement the open workflow as four tasks and the close workflow as one resolve task. The shared lock is Dynatrace Problem ID: ServiceNow `correlation_id` and PagerDuty `dedup_key = dt-problem-<ProblemID>`. Use the pack in `../4-snow-pd-workflow-yaml-and-json/` or rebuild the same graph in the UI.

---

## Part 0 — Collect what each step needs

Do this before editing scripts. Put values in a private notes file (not git).

### 0.1 ServiceNow connection + fields (§4.2)

| Need | What to get | Where |
| --- | --- | --- |
| Instance URL | `https://<id>.service-now.com` | SNOW admin |
| Integration user | User that can create/update/search `incident` | SNOW admin |
| Connection in Dynatrace | Settings → Connections → ServiceNow (preferred) | Dynatrace |
| Caller sys_id | User record for “Dynatrace bot” | SNOW `sys_user` |
| Category / subcategory | e.g. Software / Application | SNOW choices |
| Per-app assignment group sys_id | e.g. EIP-Support | `sys_user_group` |
| Per-app business service sys_id | e.g. EIP Checkout | CMDB service table |

Also allow Dynatrace outbound to your SNOW host (External requests / EdgeConnect).

### 0.2 Maps for prepare-payload (§4.4)

Build a table like this (this becomes `assignMap` in JS):

| App tag (`app:` value) | Assignment group | Group sys_id | Business service | Biz sys_id | L1 | L2 | L3 | Runbook URL |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| EIP | EIP-Support | `…` | EIP Checkout | `…` | EIP-L1 | EIP-L2 | EIP-L3 | https://…/eip |
| CCI | CCI-Support | `…` | CCI FA Comm Calc | `…` | CCI-L1 | … | … | https://…/cci |
| (default) | Ops-Default | `…` | Unknown | `…` | Ops-L1 | … | … | https://…/default |

Entities in Dynatrace must carry tag `app:EIP` (or `AGO_GLOBAL_APP:EIP`) so prepare can pick the right row.

### 0.3 PagerDuty

| Need | What to get |
| --- | --- |
| Target service | Demo or real on-call service |
| Integration | **Events API v2** |
| `routing_key` | 32-character integration key |
| Outbound allow | `events.pagerduty.com` in Dynatrace |

### 0.4 Correlation keys (never invent random IDs)

| System | Field | Value |
| --- | --- | --- |
| Dynatrace | Problem ID | e.g. `P-12345` |
| ServiceNow | `correlation_id` | same Problem ID |
| PagerDuty | `dedup_key` | `dt-problem-<ProblemID>` |

---

## Part 1 — Create the two workflows

| Workflow | Trigger | Tasks |
| --- | --- | --- |
| WF-A Create | Davis Problem, **open** (`onProblemClose: false`) | prepare → SNOW + PD → cross-link |
| WF-B Close | Davis Problem, **closed** (`onProblemClose: true`) | resolve-snow-and-pd |

### Fast path (recommended)

1. Open folder `../4-snow-pd-workflow-yaml-and-json/`
2. Replace all `__SNOW_*__` and `__PD_ROUTING_KEY__` (and fill `assignMap` sys_ids / runbooks)
3. Workflows → **Upload** create YAML (or JSON)
4. Upload close YAML (or JSON) separately
5. Set both **Active**

### UI path (same logic without upload)

1. Workflows → Create workflow → name create flow
2. Trigger = Problem / Active
3. Add four **JavaScript** tasks (or SNOW connector + HTTP + JS) matching Part 2–4
4. Create second workflow for close matching Part 5

---

## Part 2 — `prepare-payload` (needs maps §4.4)

**What this is:** First task. No SNOW/PD calls. Reads the Problem event and builds one object every later task reuses.

### 2.1 Wire the task

| Setting | Value |
| --- | --- |
| Action | `dynatrace.automations:run-javascript` |
| Predecessors | none |
| Name | `prepare-payload` |

### 2.2 What the script must do (in order)

1. Read event: title, Problem ID, URL, severity, tags  
2. Detect app from tag `app:` or `AGO_GLOBAL_APP:`  
3. Look up `assignMap[app]` (fallback `default`) — **this is §4.4**  
4. Map severity → impact / urgency / P3|P4 / PD severity  
5. Build short description + long description (DT link, L1–L3, runbook)  
6. Return object including `problemId`, `dedupKey`, SNOW sys_ids, PD fields  

### 2.3 Severity map (keep simple)

| Problem severity contains | impact | urgency | pLevel | pdSeverity |
| --- | --- | --- | --- | --- |
| AVAILABILITY or CRITICAL | 2 | 2 | P3 | critical |
| ERROR | 2 | 3 | P3 | error |
| Else (resource/slow) | 3 | 3 | P4 | warning |

### 2.4 Must-return fields

| Field | Used by |
| --- | --- |
| `problemId` | SNOW `correlation_id`, close search |
| `dedupKey` | PD trigger + resolve (`dt-problem-` + id) |
| `callerSysId` | SNOW caller |
| `assignmentGroupSysId` / `businessServiceSysId` | SNOW fields |
| `impact` / `urgency` | SNOW priority |
| `shortDescription` / `description` | SNOW text |
| `pdSeverity` / `runbookUrl` / L1–L3 / `app` | PD payload + links |

Your uploaded YAML already contains this script under `prepare-payload` — edit `assignMap` and caller sys_id there.

---

## Part 3 — Parallel creates

Both tasks depend **only** on `prepare-payload` = OK. Do **not** chain SNOW → PD.

```
prepare-payload
    ├──► create-servicenow-incident
    └──► create-pagerduty-incident
```

### 3.1 Create ServiceNow INC (needs connection + fields §4.2)

**Option A — Keep JS HTTP (matches current YAML)**

| Setting | Value |
| --- | --- |
| Action | run-javascript |
| Predecessor | `prepare-payload` |
| API | `POST {instance}/api/now/v2/table/incident` |
| Auth | Basic (placeholders) or swap to Connection later |

Body fields to set:

| SNOW field (§4.2) | From prepare |
| --- | --- |
| `correlation_id` | `problemId` (**required for close**) |
| `caller_id` | `callerSysId` |
| `business_service` | `businessServiceSysId` |
| `assignment_group` | `assignmentGroupSysId` |
| `impact` / `urgency` | from severity map |
| `category` / `subcategory` | Software / Application (or your choices) |
| `short_description` | `[Dynatrace] …` |
| `description` | full text with DT link, L1–L3, runbook |

Return: `sysId`, `number`.

**Option B — ServiceNow connector (better for secrets)**

1. After import, replace JS create with **ServiceNow → Create Incident**  
2. Pick your Connection  
3. Map the same fields from `{{ result("prepare-payload").… }}`  
4. Still set `correlation_id` to Problem ID  

### 3.2 Create PagerDuty (needs `routing_key`)

| Setting | Value |
| --- | --- |
| Action | run-javascript (or HTTP request) |
| Predecessor | `prepare-payload` only |
| URL | `https://events.pagerduty.com/v2/enqueue` |
| Method | POST |

Body essentials:

| Field | Value |
| --- | --- |
| `routing_key` | your Events API v2 key |
| `event_action` | `trigger` |
| `dedup_key` | `result("prepare-payload").dedupKey` |
| `payload.summary` | same story as INC short description |
| `payload.severity` | `pdSeverity` |
| `links` | Problem URL + runbook |
| `custom_details` | problem_id, biz, group, P-level, L1–L3 |

Return: `dedupKey` (must equal prepare’s key).

---

## Part 4 — Cross-link comment (needs both results)

```
create-servicenow-incident ──┐
create-pagerduty-incident ───┴──► cross-link-snow-pd
```

| Setting | Value |
| --- | --- |
| Predecessors | **both** create tasks |
| Conditions | both states `OK` |
| Action | PATCH INC (JS or ServiceNow Comment / Update) |

What to write into `work_notes` (example):

```text
PagerDuty sync: dedup_key=dt-problem-P-12345 | Dynatrace Problem=<url> | Runbook=<url>
```

Optional later: also note INC number back into PagerDuty. Not required for close.

---

## Part 5 — Problem CLOSED (2nd workflow)

### 5.1 Trigger

| Setting | Value |
| --- | --- |
| Type | davis-problem / Problem |
| `onProblemClose` | **true** |
| Active | yes |

### 5.2 Single task: `resolve-snow-and-pd`

Do this in order inside one JS task (as in the close YAML):

| Step | How |
| --- | --- |
| 1 | Read `problemId` from closed event (same fallbacks as open) |
| 2 | Build `dedupKey = "dt-problem-" + problemId` |
| 3 | **Find INC:** `GET /api/now/v2/table/incident?sysparm_query=correlation_id=<problemId>&sysparm_limit=1` |
| 4 | **Resolve SNOW:** if found, `PATCH` that `sys_id` with `state=6`, close code, notes “Dynatrace Problem closed (…)” |
| 5 | **Resolve PD:** `POST .../enqueue` with `event_action=resolve`, same `routing_key`, same `dedup_key` |

```
Problem CLOSED
  → find INC by correlation_id
  → resolve SNOW (if found)
  → resolve PD (always attempt with same dedup_key)
```

| Edge case | Behavior in current template |
| --- | --- |
| No INC found | `snow.skipped=true`; still try PD resolve |
| SNOW PATCH fails | Task errors (fix ACL/state) |
| PD resolve fails | Task errors (check key / routing_key) |

---

## Part 6 — How to run it end-to-end

### 6.1 Activate

1. Save both workflows  
2. Set both **Active**  
3. Confirm open trigger is open-only; close trigger is close-only  

### 6.2 Test open

1. Open a controlled Problem in non-prod (entity has `app:` tag)  
2. Executions → create workflow: all 4 tasks OK  
3. SNOW: INC with `correlation_id` = Problem ID  
4. PD: alert with `dedup_key` = `dt-problem-<id>`  
5. Work notes contain that dedup key  

### 6.3 Test close

1. Close the same Problem  
2. Close workflow execution OK  
3. INC Resolved; PD resolved  

Detail monitor steps: `../12-monitor-snow-pd-demo-steps/`

---

## Part 7 — UI wiring checklist (create workflow)

| # | Do this |
| --- | --- |
| 1 | Task `prepare-payload` has no predecessors |
| 2 | SNOW create predecessor = only `prepare-payload` |
| 3 | PD create predecessor = only `prepare-payload` |
| 4 | Positions: SNOW and PD on same row (parallel) |
| 5 | `cross-link` predecessors = **both** creates |
| 6 | Cross-link conditions: both OK |
| 7 | `correlation_id` set on create |
| 8 | `dedup_key` formula identical in open and close |

---

## Data flow map

```
[Problem OPEN]
      │
      ▼
[prepare-payload]  ← assignMap §4.4 + severity → P3/P4
      │
      ├─► [SNOW Create INC]  ← fields §4.2 + correlation_id
      │         │
      └─► [PD trigger]       ← routing_key + dedup_key
                │
                ▼
         [cross-link work_notes]

[Problem CLOSED]  (2nd workflow)
      │
      ▼
[find INC by correlation_id]
      ├─► resolve SNOW
      └─► resolve PD (same dedup_key)
```

---

## Related files

| Path | Why |
| --- | --- |
| `../4-snow-pd-workflow-yaml-and-json/` | Ready YAML/JSON implementing this flow |
| `../1-dynatrace-workflow-snow-pagerduty/` | Field mapping §4 + PD body |
| `../5-setup-snow-pd-workflow-steps-perms/` | Permissions + connections |
| `../12-monitor-snow-pd-demo-steps/` | How to watch a demo |
| `13.sh` | Placeholder/edit reminders |

## Commands

See `13.sh` in this folder.
