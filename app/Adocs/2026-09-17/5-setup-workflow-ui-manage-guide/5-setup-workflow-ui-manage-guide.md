# Setup Workflow Ui Manage Guide

```
Want a Dynatrace Workflow? (read this file top to bottom)
  │
  ├─ What it is (big picture)
  ├─ Part A — Setup in UI (A0–A8, every click)
  ├─ Part B — Every function explained
  ├─ Part C — How to manage day to day
  └─ Recipes + troubleshooting + data flow
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What a Workflow is | A recipe: **when** (trigger) → **do** (tasks) → optional ticket/page |
| Draft vs Active | Draft is only saved; **Activate** makes it live |
| Two build paths | Blank UI, or Upload YAML then edit in UI |
| Manage | Executions, Deactivate, Share, Connections, External requests |

## Summary

This is the **detailed** guide for Dynatrace Workflows (Automations) in the UI. It explains the idea, every setup step, what each button/field does, and how to run and fix workflows after go-live. Menu labels can differ slightly by tenant version; the ideas stay the same.

---

## Investigation

Scope: **Workflows / Automations** only.  
Not the same as: classic **Problem notifications** (e.g. `silvastg`), and not **DQL log alerts** (Terraform `dynatrace_log_alert`).

## Result

Use Part A to build, Part B as a dictionary, Part C to operate. End with the PagerDuty-only recipe that matches your AGO packs.

---

# Big picture — what a Workflow is

Imagine a kitchen ticket printer:

| Kitchen idea | Workflow idea |
| --- | --- |
| Order comes in | **Trigger** fires (Problem opened, schedule tick, …) |
| Cook follows steps | **Tasks** run in order (or in parallel) |
| Receipt / camera log | **Executions** history |
| Closed for the night | **Deactivate** |

**One sentence:** A Workflow watches for an event (or time), then runs automation steps for you.

**Happy path:**

```
Problem opens in Dynatrace
  → Trigger matches
  → Task1 prepare fields
  → Task2 call PagerDuty / ServiceNow
  → Execution shows OK
  → Humans get a page or ticket
```

---

# Part A — How to set up a workflow in the UI (detailed)

## A0 — Before you start (why each check matters)

Do these first. Skipping them causes most “it doesn’t work” tickets.

### 1) Permission to open Workflows

| What | Detail |
| --- | --- |
| What it is | Your user (or group) must be allowed to use Automations/Workflows |
| What you see if missing | App missing from menu, or read-only / create blocked |
| What to do | Ask Dynatrace admin for Workflows create/edit/activate rights |

### 2) External requests (allowlist)

| What | Detail |
| --- | --- |
| What it is | Dynatrace will **not** call the internet freely. You must list allowed hosts |
| Why it matters | PagerDuty, ServiceNow, webhooks all need outbound HTTPS |
| Where | **Settings → External requests** (wording may be “Allow outbound”) |
| Examples | `events.pagerduty.com`, `silvastg.service-now.com` |
| What failure looks like | Task error: host not in allowlist / blocked request |

**How to add:**

1. Open External requests.  
2. Add hostname (prefer host only: `events.pagerduty.com`).  
3. Save.  
4. If you cannot edit → ask an admin (same issue you hit in Teams).

### 3) Connections (only if ServiceNow tasks are in the workflow)

| What | Detail |
| --- | --- |
| What it is | Saved credentials + URL for ServiceNow (or similar) |
| Where | Settings → Connections (or App Connections) |
| Example name | `ServiceNowTest` |
| Why separate | So passwords/OAuth secrets are not pasted into every workflow |

If ServiceNow is handled only by classic Problem notification `silvastg`, you may **not** need a Workflow Connection for SNOW.

### 4) Secrets ready

| Secret | Where it goes |
| --- | --- |
| PagerDuty routing key | Inside Run JavaScript task (replace `__PD_ROUTING_KEY__`) |
| SNOW user/OAuth | Inside Connection (not in YAML if possible) |

Never Activate while placeholders like `__PD_ROUTING_KEY__` remain.

---

## A1 — Open Workflows (what you should see)

1. Log in to Dynatrace.  
2. Left menu → search **Workflows** or **Automations**.  
3. Open **Workflows**.

**List page usually shows:**

| UI area | Meaning |
| --- | --- |
| Workflow name | Title you gave it |
| State | Draft / Active / Disabled |
| Last run / updated | Freshness |
| Actions | Open, Activate, Delete, Share |

**Buttons you care about:**

| Button | Meaning |
| --- | --- |
| Create | Empty workflow |
| Upload / Import | Load YAML/JSON template |
| Search | Find by name |

---

## A2 — Create blank vs Upload (choose a path)

### Path 1 — Create blank (best for learning)

| Step | What you do | Why |
| --- | --- | --- |
| 1 | Click **Create workflow** | Opens editor |
| 2 | Set **Title** | Shows in list and Executions |
| 3 | Set **Description** | Tell on-call what it does |
| 4 | Save | Becomes **Draft** |

**Title tip:** `AGO - Problem to PagerDuty` is clearer than `test1`.

### Path 2 — Upload YAML (best when you already have a pack)

| Step | What you do | Why |
| --- | --- | --- |
| 1 | Click **Upload** / **Import** | Starts import |
| 2 | Select `.workflow-template.yaml` | Preferred over JSON for editing |
| 3 | Map Connection if asked | Binds SNOW tasks to credentials |
| 4 | Open Draft | Review canvas before Activate |

**After upload, always check:**

- Trigger filter (open vs close)  
- Task scripts (secrets)  
- Connection dropdowns  
- Task order (predecessors)

**Do not** upload the same open workflow twice as two Active copies (duplicate pages/tickets).

---

## A3 — Trigger in detail (when it runs)

Open **Trigger** at the top of the editor.

### Trigger types

| Type | Plain English | Good for |
| --- | --- | --- |
| Davis problem / Problem event | “When a Problem changes…” | Incident automation |
| Schedule | “Every 5 minutes / hourly…” | Periodic jobs |
| Other event | Other Dynatrace events | Advanced |
| Manual (if available) | “Only when I click Run” | Safe testing |

### Problem OPEN trigger (detailed)

Goal: run when a Problem becomes something you care about while it is still active.

| Setting | What to choose | Why |
| --- | --- | --- |
| Kind | Davis / Problem | Ties to Problems app |
| Status | ACTIVE | Still an open issue |
| Transitions | CREATED, UPDATED, REOPENED | New or reopened noise |
| Categories | error, availability, resource, slowdown | Which Problem classes |
| Entity tags | e.g. `env:prod` | Only production entities |
| Trigger active | ON | Armed |

**filterQuery example (if your UI shows it):**

```text
event.kind == "DAVIS_PROBLEM" AND event.status == "ACTIVE" AND
(event.status_transition == "CREATED" OR event.status_transition == "UPDATED" OR
 event.status_transition == "REOPENED")
```

### Problem CLOSED trigger (detailed)

Use a **second workflow**, not the same one.

| Setting | What to choose |
| --- | --- |
| Status / transition | CLOSED or RESOLVED |
| Same categories/tags | Match the open workflow so pairs stay consistent |

**Why two workflows?** Open creates a page/ticket; close resolves it. One workflow trying to do both becomes hard to read and easy to break.

### Schedule trigger (detailed)

| Setting | Meaning |
| --- | --- |
| Cron / interval | How often it runs |
| Timezone | Whose clock |
| Active | Armed |

Example idea: `*/5 * * * *` = every 5 minutes (exact UI field names vary).

---

## A4 — Tasks in detail (what it does)

A **task** is one box on the canvas. Each task has an **action** (function type).

### How to add a task

1. Click **Add task** / **+**.  
2. Choose action (e.g. Run JavaScript).  
3. Set a clear **name** (`prepare-payload`).  
4. Fill **Input**.  
5. Drag position on canvas.  
6. Set predecessors/conditions (Part A5).

### Recommended beginner chain

```
1) prepare-payload          ← read Problem, build fields
2) create-pagerduty-incident OR create-servicenow-incident
3) optional cross-link      ← write PD key onto SNOW ticket
```

### Naming rules (important)

| Do | Do not |
| --- | --- |
| Stable names like `prepare-payload` | Rename often after wiring expressions |
| One job per task | Giant script that does everything with no structure |

Later tasks use names in expressions:

```text
{{ result("prepare-payload").problemId }}
```

If you rename `prepare-payload`, that expression breaks until you update it.

---

## A5 — Wire order and conditions (detailed)

### Predecessors

| Idea | Meaning |
| --- | --- |
| Predecessor | “Wait until this task finishes before I start” |
| Empty predecessors | This task can start when the trigger fires (usually first task) |

### Conditions / states

| Idea | Meaning |
| --- | --- |
| State OK | Previous task succeeded |
| State ERROR | Previous task failed |
| Typical setting | Only continue if predecessor is **OK** |

Without OK conditions, a later task might run even when prepare failed (bad tickets).

### Parallel and join

```
prepare-payload
   ├─ create-snow   (both wait only on prepare)
   └─ create-pd
         └─ cross-link  (waits on BOTH snow and pd = OK)
```

| Pattern | When to use |
| --- | --- |
| Parallel | Independent calls (SNOW + PD) to save time |
| Join | Need both results (cross-link comment) |
| Strict sequence | Second call needs first call’s output only |

---

## A6 — Secrets and Connections (detailed)

### ServiceNow Connection in a task

1. Open SNOW task (Create Incident, etc.).  
2. Find **Connection** dropdown.  
3. Select your Connection (`ServiceNowTest`).  
4. Fill category, assignment group, short description, etc.  
5. Use expressions for Problem fields from prepare.

If Category dropdown fails with “host not in allowlist”, fix External requests first.

### PagerDuty key in JavaScript

Open the JS task and replace:

```text
const routingKey = "__PD_ROUTING_KEY__";
```

with the real Events API v2 routing key for your PD service.

### Classic notification vs Connection (do not confuse)

| Feature | What it is |
| --- | --- |
| Problem notifications `silvastg` | Classic Settings push to SNOW (ITOM/ITSM toggles) |
| Workflow Connection | Credentials for Workflow SNOW **actions** |

You can use classic SNOW + Workflow PD.  
Avoid classic ITSM INC **and** Workflow Create Incident for the **same** Problems (duplicates).

---

## A7 — Save and Activate (detailed)

| State | What it means | Does it run on live Problems? |
| --- | --- | --- |
| Draft | Saved design | No |
| Active | Published/live | Yes, when trigger matches |
| Disabled / Inactive | Kept but paused | No |

**Safe activate checklist:**

1. Save.  
2. Trigger looks correct (open vs close).  
3. Secrets replaced.  
4. Connection selected (if needed).  
5. Allowlist done.  
6. Activate.  
7. Accept actor/permission prompts if shown.

If Activate is blocked: missing permission, missing app dependency, or validation error on a task.

---

## A8 — Test (detailed)

### What “good” looks like

| Check | Where |
| --- | --- |
| Workflow run appears | Workflow → Executions |
| Each task OK | Open the run → task list |
| External effect | PagerDuty alert / SNOW ticket or event |
| Close path | Closing Problem resolves PD (close workflow) |

### How to read a failure

1. Open Executions.  
2. Open the red/failed run.  
3. Click the **first failed task** (not only the workflow summary).  
4. Read error text:

| Error hint | Fix |
| --- | --- |
| host not in allowlist | External requests |
| 401 / 403 | Connection or routing key |
| result(...).undefined | Wrong task name or missing return field |
| timeout | Raise timeout or fix slow API |

### Manual run

If UI offers **Run**, use it for schedule/JS smoke tests. Problem triggers still need a real (or test) Problem that matches filters.

---

# Part B — Every function explained (UI dictionary)

## B1 — Workflow list page functions

| Function | What it does | When you use it | Careful of |
| --- | --- | --- | --- |
| Create | Empty workflow | Learning / small flows | Easy to leave as Draft forever |
| Upload / Import | Load template | Team standard packs | Duplicate Active copies |
| Search / filter | Find workflows | Large environments | Filter by Active when on-call |
| Open | Edit canvas | Any change | Remember to Activate again |
| Activate | Make live | After save/test | Instantly starts matching events |
| Deactivate | Pause | Noise, incident, change window | Does not delete history |
| Delete | Remove | Retired only | Hard to undo |
| Share / Permissions | Access control | Add Davesh / team | Also share Connections |

---

## B2 — Trigger functions (deep)

| Function | Plain English | Example |
| --- | --- | --- |
| Event trigger | Start from platform events | Problem opened |
| Schedule trigger | Start on the clock | Every 5 minutes |
| filterQuery | Extra boolean filter on event fields | Only ACTIVE + CREATED |
| Categories | Problem class switches | availability=true |
| Entity tags | Only tagged entities | `env:prod` |
| isActive | Trigger armed | Off = workflow Active but never fires |

**Management advice:** Change tags/categories before deleting a workflow when noise is high.

---

## B3 — Task actions (deep)

Exact names depend on installed Apps.

| Action | Plain English | Inputs you usually set | Output you care about |
| --- | --- | --- | --- |
| Run JavaScript | Custom code | Script | Returned object fields |
| HTTP request | Call a URL | Method, URL, headers, body | Status code / body |
| snow-create-incident | Open INC | Connection, short desc, group, impact | INC number |
| snow-search-incidents | Find INC | Query (often correlation_id) | sys_id / number |
| snow-resolve-incident | Resolve INC | Connection, number/sys_id | Success |
| snow-comment-on-incident | Work note | Connection, number, comment | Success |
| Email / Slack | Notify people | Destination, message | Sent/failed |

**JavaScript special power:** `fetch()` to PagerDuty or webhooks — still needs allowlist.

---

## B4 — Task settings panel (deep)

| Setting | Plain English | Good practice |
| --- | --- | --- |
| Name | ID used by expressions | Stable kebab or camel names |
| Description | Human note | Link runbook URL |
| Active | Task enabled | Disable one noisy step temporarily |
| Position | Canvas x/y | Upload needs `y >= 1` |
| Predecessors | Wait list | Keep graph simple |
| Conditions | Gates | Prefer OK-only continuation |
| Input | Config/script | Secrets here or in Connection |
| Timeout | Max wait | Increase for slow SNOW |
| Retry | Auto retry | Dangerous for Create Incident (duplicates) |

---

## B5 — Expressions (deep)

| Expression | Meaning |
| --- | --- |
| `{{ result("prepare-payload").problemId }}` | Value `problemId` returned by task `prepare-payload` |
| `{{ result("create-pagerduty-incident").dedupKey }}` | PD key from PD task |

**Rules:**

1. Task must have already run successfully.  
2. Field must be **returned** by the script (`return { problemId: ... }`).  
3. Task name string must match exactly.

---

## B6 — Connections (deep)

| Topic | Detail |
| --- | --- |
| What | Named credential object |
| Auth types | Basic user/password or OAuth client credentials |
| Where created | Settings → Connections |
| Where used | Task Connection dropdown |
| Share | Needed so helpers/runners can use it |
| Not the same as | Classic Problem notification profile |

**Lifecycle:** Create Connection → Share → Select in task → Test Create Incident → Rotate secret in Connection (not in every workflow).

---

## B7 — Executions (deep)

| Piece | Meaning |
| --- | --- |
| Execution | One full run of the workflow |
| Trigger time | When it started |
| Overall status | OK / ERROR / maybe RUNNING |
| Task rows | Each step’s status and duration |
| Task output | JSON returned by JS / action |
| Task error | Message for failures |

**On-call habit:** Workflow red → open execution → open first failed task → fix cause → retest.

---

## B8 — Outside settings that still control workflows

| Setting | If wrong, you see |
| --- | --- |
| External requests | Blocked host errors |
| IAM / policies | Cannot create/activate/share |
| Apps not installed | Missing ServiceNow actions |
| Problem notifications | SNOW events/INC without Workflow (classic path) |
| Hourly execution limit | Runs throttled/skipped under load |

---

# Part C — Manage day to day (detailed)

## C1 — Lifecycle

```
Idea → Draft
  → Activate (live)
  → Monitor Executions
  → Edit (fix / improve)
  → Save → Activate again
  → Deactivate (pause)
  → Delete (retire)
```

| Job | Exact approach |
| --- | --- |
| Pause safely | Deactivate; do not Delete |
| Change mapping | Edit prepare JS → Save → Activate → test one Problem |
| Reduce noise | Narrow categories/tags/filterQuery |
| Rotate PD key | Edit both open and close JS → Activate both → test open+close |
| Rotate SNOW secret | Update Connection → retest one Create Incident |
| Hand off to teammate | Share workflow + Share Connection + send Executions link |

---

## C2 — Ownership checklist (detailed)

| Habit | Why it matters |
| --- | --- |
| Clear titles | On-call finds the right automation fast |
| Open + close pair | Tickets/pages do not stay forever open |
| Same dedup/correlation keys | Close finds the same PD/SNOW item |
| Description has runbook | Night shift knows what “good” looks like |
| No double ITSM paths | Prevents duplicate INC |
| Know Executions | Faster than guessing in SNOW/PD consoles |

**Key patterns:**

| Concern | Pattern |
| --- | --- |
| PD sync | `dedup_key = "dt-problem-" + problemId` on open and close |
| SNOW sync | `correlation_id = problemId` (Connection path) |

---

## C3 — Troubleshooting tree (detailed)

```
A) No execution at all
   → Is workflow Active?
   → Is trigger Active?
   → Did a matching Problem exist (category/tag/status)?
   → Wrong environment/tenant?

B) Execution exists but ERROR
   → Open first failed task
   → Allowlist?
   → Auth (Connection / routing key)?
   → Expression / missing field?
   → Timeout?

C) Execution OK but wrong business result
   → Wrong PD service (routing key)?
   → Wrong SNOW assignment group?
   → Trigger too wide (noise) or too narrow (misses)?
   → Duplicate automations Active?
```

---

## C4 — Recommended architecture for your team

| Channel | Recommended setup |
| --- | --- |
| ServiceNow | Classic notification `silvastg` **or** Workflow Connection — pick one for ITSM INC |
| PagerDuty | Workflow open + close (JS) |
| Build method | Upload YAML → edit secrets in UI → Activate |
| Ops method | Watch Executions first when something breaks |

Related packs:

- UI steps: `2026-09-14/9-set-workflow-ui-step-by-step/`  
- Examples: `2026-09-17/4-dynatrace-workflow-top10-examples/`  
- PD YAML: `2026-09-14/8-snow-classic-notification-yaml-json/`

---

# Quick recipe — PagerDuty only (manual UI)

1. **External requests:** add `events.pagerduty.com` → Save.  
2. **Workflows → Upload** open YAML (`ago-problem-to-pagerduty-only...`).  
3. Open task `create-pagerduty-incident` → set real routing key → Save.  
4. **Activate** open workflow.  
5. Upload close YAML → same routing key → Activate.  
6. Open a test Problem → Executions OK → PD alert with `dt-problem-<id>`.  
7. Close Problem → close workflow resolves the same PD alert.

---

# Data flow map

```
Human in Dynatrace UI
  → Create/Upload workflow
  → Configure Trigger (when)
  → Configure Tasks (what) + Connection/secrets
  → Save Draft
  → Activate
        ↓
Problem / Schedule event
  → Trigger match?
        ↓ yes
  Tasks run (order / parallel)
  → Each task OK/ERROR recorded in Executions
  → External system updated (PD / SNOW / HTTP)
        ↓
On-call uses Executions + PD/SNOW consoles to verify
```

---

## Related files

| Path | Why |
| --- | --- |
| `../4-dynatrace-workflow-top10-examples/` | Syntax + 10 examples |
| `2026-09-14/9-set-workflow-ui-step-by-step/` | Shorter AGO UI steps |
| `2026-09-14/8-snow-classic-notification-yaml-json/` | Uploadable PD workflows |
| `5.sh` | Path reminders |

## Commands

See `5.sh` in this folder.
