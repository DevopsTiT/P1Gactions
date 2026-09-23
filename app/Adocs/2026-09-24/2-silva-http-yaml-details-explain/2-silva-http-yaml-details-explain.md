# Silva Http Snow Pd Yaml Details

```
Two YAML files = two workflows
  OPEN  → Problem starts  → create ticket + page
  CLOSE → Problem ends    → resolve ticket + clear page

Read order for each file:
  1) Header comments (why + sync keys)
  2) metadata / workflow title
  3) trigger (when it runs)
  4) tasks top → bottom (and left/right = parallel)
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| File 1 | `1-open-silva-http-and-pagerduty.workflow.yaml` |
| File 2 | `2-close-silva-http-and-pagerduty.workflow.yaml` |
| Why JS | No `snow-*` connector — HTTP with `run-javascript` |
| Sync | Same Dynatrace `problemId` → SNOW `correlation_id` + PD `dedup_key` |
| Shape | Prepare first, then two HTTP tasks **in parallel** |

## Summary

Both files are Dynatrace Workflow definitions (`schemaVersion: 3`). OPEN fires when a Davis Problem becomes active. CLOSE fires when it closes. Neither uses the ServiceNow connector app. Each uses JavaScript tasks that call SILVA/SNOW and PagerDuty over HTTPS. You must allowlist those hosts and replace password / routing-key placeholders before Activate.

## Investigation

User asked for a detailed explain of the two YAMLs from seq 1 (`1-silva-http-snow-pd-sync-workflows`). Walked header, trigger, every task, sync fields, parallel layout, and failure modes.

## Result

Use the sections below as a line-by-line mental model before importing. Keep both workflows Active as a pair.

---

## 1) What a Dynatrace workflow YAML is

| Piece | What it means | Why you care |
| --- | --- | --- |
| `metadata` | App dependency (Automations) | Workflow needs `dynatrace.automations` |
| `workflow.title` | Name in the UI | Easy to find OPEN vs CLOSE |
| `trigger` | Event that starts a run | Davis Problem open vs close |
| `tasks` | Steps in the run | Each task is one box on the canvas |
| `action: run-javascript` | Runs JS with `fetch` | Your HTTP to SILVA and PD |
| `predecessors` | What must finish first | Builds the graph |
| `position x/y` | Canvas layout | Same `y`, different `x` = parallel |

**Analogy:** YAML is the recipe. Dynatrace cooks it when a Problem event matches the filter.

---

## 2) Shared design (both files)

| Design choice | Meaning |
| --- | --- |
| No `dynatrace.servicenow:snow-*` | Matches “cannot build snow connector” |
| SILVA base URL | `https://silvastg.service-now.com` |
| PD API | `https://events.pagerduty.com/v2/enqueue` |
| Sync from `problemId` | One Dynatrace id ties ticket and page together |
| Placeholders | `__SNOW_PASSWORD__`, `__PD_ROUTING_KEY__` — replace before Activate |
| Allowlist | Both hosts in External requests on **this** tenant |

### Sync keys (memorize these)

| System | Field | Formula | Example |
| --- | --- | --- | --- |
| Dynatrace | Problem display id | from event | `P-12345` |
| SILVA / SNOW | `correlation_id` | `= problemId` | `P-12345` |
| PagerDuty | `dedup_key` | `dt-problem-` + problemId | `dt-problem-P-12345` |

OPEN writes them. CLOSE must use the **same** formulas or resolve will miss.

---

## 3) OPEN YAML — big picture

```
Davis Problem ACTIVE (CREATED / UPDATED / REOPENED)
        │
        ▼
  prepare-payload          (x=0, y=1)
        │
        ├──────────────────┐
        ▼                  ▼
post-silva-incident-http   trigger-pagerduty
     (x=0, y=2)              (x=1, y=2)
```

| Section | What it does |
| --- | --- |
| Header comments | Human notes: no connector, allowlist, sync keys |
| `title` | `AGO - Problem OPEN to SILVA HTTP and PagerDuty (sync)` |
| `trigger.filterQuery` | Only Davis Problems that are ACTIVE and CREATED/UPDATED/REOPENED |
| `triggerConfiguration.type` | `davis-problem` with error/resource/slowdown/availability on |
| `hourlyExecutionLimit` | Cap 1000 runs/hour (safety) |

### When OPEN runs (beginner)

| Situation | Runs? |
| --- | --- |
| New Problem opens | Yes |
| Problem updates while still active | Yes (filter includes UPDATED) |
| Problem reopened | Yes |
| Problem closed | No — that is CLOSE |

---

## 4) OPEN task 1 — `prepare-payload`

| Field | Value |
| --- | --- |
| Action | `dynatrace.automations:run-javascript` |
| Predecessors | none (first step) |
| Job | Read the Problem event; build shared fields for both HTTP calls |

**What the script reads from the event** (with fallbacks):

| Output field | Source idea |
| --- | --- |
| `problemTitle` | event name / problem title |
| `problemId` | display_id / problem.id (this is the sync root) |
| `problemUrl` | problem URL for deep-link |
| `hostName` | host name if present (SILVA/CMDB context) |
| `severity` | problem severity string |
| `pdSeverity` | mapped for PagerDuty (`critical` / `error` / `warning`) |
| `snowImpact` / `snowUrgency` | mapped 1–3 for SNOW |
| `notificationDescription` | `[OPEN] P-…: Problem … URL` |
| `shortDescription` | `[Dynatrace] <title>` |
| `correlationId` | same as `problemId` |
| `dedupKey` | `dt-problem-` + `problemId` |
| `silvaBaseUrl` / `silvaUsername` | STG instance + tech user |

**Severity mapping (simple):**

| Dynatrace severity contains | PD severity | SNOW impact/urgency |
| --- | --- | --- |
| AVAILABILITY or CRITICAL | critical | 1 / 1 |
| ERROR | error | 2 / 2 |
| else | warning | 3 / 3 |

Later tasks call `ex.result("prepare-payload")` to reuse this object. That is how both sides stay consistent in one run.

---

## 5) OPEN task 2 — `post-silva-incident-http`

| Field | Value |
| --- | --- |
| Action | run-javascript |
| Predecessor | `prepare-payload` OK |
| Position | left branch (`x=0, y=2`) |
| Job | HTTP create Incident on SILVA/SNOW |

**HTTP call:**

| Piece | Value |
| --- | --- |
| Method | `POST` |
| URL | `{silvaBaseUrl}/api/now/v2/table/incident` |
| Auth | Basic (`Tech_DynatraceJP_WS` + `__SNOW_PASSWORD__`) |
| Important body field | `correlation_id: p.correlationId` |

**Also sent:** short_description, description, impact, urgency, caller_id, optional `u_host`, work_notes with sync hint + problem URL.

**Returns:** `incidentNumber`, `incidentSysId`, sync keys, raw JSON.

**If HTTP fails:** throws error mentioning allowlist — matches Sandbox “outbound white listing” from your chat.

**SILVA gatekeeper note:** If CMDB says retired host, create may fail or never produce an INC. That is business logic outside Dynatrace. CLOSE is written to tolerate “no INC found.”

---

## 6) OPEN task 3 — `trigger-pagerduty`

| Field | Value |
| --- | --- |
| Action | run-javascript |
| Predecessor | `prepare-payload` OK |
| Position | right branch (`x=1, y=2`) — **parallel** with SILVA |
| Job | Page on-call via Events API |

**HTTP call:**

| Piece | Value |
| --- | --- |
| Method | `POST` |
| URL | `https://events.pagerduty.com/v2/enqueue` |
| `event_action` | `trigger` |
| `dedup_key` | from prepare (`dt-problem-…`) |
| `routing_key` | `__PD_ROUTING_KEY__` |

**`custom_details` includes:** problem_id, problem_url, host_name, snow_correlation_id, note that path is HTTP (no connector). That helps humans and later SRE Agent deep-link.

**Why parallel with SILVA:** Ticket and page should both start quickly. One side failing does not block the other from being *attempted* (each task fails on its own error).

---

## 7) CLOSE YAML — big picture

```
Davis Problem CLOSED / RESOLVED
        │
        ▼
  prepare-close-ids        (x=0, y=1)
        │
        ├──────────────────┐
        ▼                  ▼
resolve-silva-incident-http  resolve-pagerduty
     (x=0, y=2)                (x=1, y=2)
```

| Section | What it does |
| --- | --- |
| Header | Same secrets and allowlist as OPEN |
| `title` | `AGO - Problem CLOSE resolve SILVA HTTP and PagerDuty (sync)` |
| `filterQuery` | CLOSED status or RESOLVED/CLOSED transition |

### When CLOSE runs

| Situation | Runs? |
| --- | --- |
| Problem closed / resolved | Yes |
| Problem still open | No |

You need **both** OPEN and CLOSE Active. OPEN alone leaves tickets/pages open forever after Dynatrace recovers.

---

## 8) CLOSE task 1 — `prepare-close-ids`

| Job | Rebuild the **same** sync keys from the close event |
| --- | --- |
| `correlationId` | `problemId` |
| `dedupKey` | `dt-problem-` + `problemId` |
| `closeNotes` | `[RESOLVED] …` text for SNOW |
| URLs / user | same SILVA base + username |

No severity mapping here — close only needs IDs and a close note.

---

## 9) CLOSE task 2 — `resolve-silva-incident-http`

**Step A — find the ticket**

| Piece | Value |
| --- | --- |
| Method | `GET` |
| Query | `correlation_id=<problemId>` |
| Limit | 1 row |

**Step B — if found, resolve**

| Piece | Value |
| --- | --- |
| Method | `PATCH` |
| URL | `/api/now/v2/table/incident/{sys_id}` |
| Body | `state: "6"` (Resolved), close_code, close_notes |

**Step C — if not found**

Returns `{ found: false, note: "…" }` **without throwing**. Reason: OPEN may have skipped create (retired host). Still allow PD resolve to run on the other branch.

---

## 10) CLOSE task 3 — `resolve-pagerduty`

| Piece | Value |
| --- | --- |
| Method | `POST` `/v2/enqueue` |
| `event_action` | `resolve` |
| `dedup_key` | same as OPEN |
| `routing_key` | same placeholder as OPEN |

PagerDuty matches the open alert by `dedup_key` and clears the page. Wrong key = “resolve does nothing.”

---

## 11) Side-by-side cheat sheet

| Topic | OPEN | CLOSE |
| --- | --- | --- |
| Trigger | ACTIVE + CREATED/UPDATED/REOPENED | CLOSED / RESOLVED |
| Prepare task | `prepare-payload` | `prepare-close-ids` |
| SILVA HTTP | POST create INC | GET by correlation_id → PATCH |
| PD HTTP | `trigger` | `resolve` |
| Sync write | Sets correlation_id + dedup_key | Reuses same formulas |
| Soft miss | Create failure throws | Missing INC = soft return |

---

## 12) Placeholders and secrets

| Placeholder | Where | Replace with |
| --- | --- | --- |
| `__SNOW_PASSWORD__` | Both SILVA JS tasks | Password for `Tech_DynatraceJP_WS` (or your user) |
| `__PD_ROUTING_KEY__` | Both PD JS tasks | Events API routing key for the **test** Service |

Use the **same** values in OPEN and CLOSE. Mismatch = create works, resolve fails (or the reverse).

---

## 13) Common fails mapped to YAML

| Symptom | Which part | Fix |
| --- | --- | --- |
| Network / fetch error | SILVA or PD task | External requests allowlist on this tenant |
| 401 on SILVA | Auth in SILVA task | User/password/roles |
| INC created, PD never pages | `trigger-pagerduty` | Routing key / allowlist `events.pagerduty.com` |
| PD pages, no INC | SILVA create or CMDB skip | Check SILVA policy; not always a YAML bug |
| Close does not clear PD | CLOSE inactive or wrong `dedupKey` | Activate CLOSE; verify formula |
| Duplicate INC | Classic notification still ON | Turn ITSM notification OFF while testing |
| UPDATED storms | OPEN filter includes UPDATED | Narrow filter if too noisy |

---

## Data flow map

```
OPEN YAML
  Problem event
    → prepare-payload
         → correlationId = problemId
         → dedupKey = dt-problem-<problemId>
    → parallel HTTP
         → SILVA POST incident (correlation_id)
         → PD trigger (dedup_key + problem_url in custom_details)

CLOSE YAML
  Problem closed event
    → prepare-close-ids (same keys)
    → parallel HTTP
         → SILVA GET+PATCH Resolved
         → PD resolve
```

---

## Related files

| File | Role |
| --- | --- |
| `../1-silva-http-snow-pd-sync-workflows/*.workflow.yaml` | The two YAML sources |
| `../1-silva-http-snow-pd-sync-workflows/1-silva-http-snow-pd-sync-workflows.md` | Pack overview |
| `2.sh` | Optional open helpers (user runs) |

## Commands

See `2.sh`.
