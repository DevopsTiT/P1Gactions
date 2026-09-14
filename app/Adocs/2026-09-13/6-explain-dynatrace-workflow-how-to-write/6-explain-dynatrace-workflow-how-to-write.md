# Explain Dynatrace Workflow And How To Write

```
What is a workflow?
  → Automation: trigger → tasks → result
How do I write one?
  → UI editor, or upload YAML template / JSON, or Terraform
What must I provide?
  → Trigger rules + task actions + connections/secrets + field maps
```

| Key point | Detail |
| --- | --- |
| What it is | Dynatrace **AutomationEngine** recipe: when X happens, do Y |
| How to write | Workflows app (drag tasks) or import YAML/JSON |
| Must provide | Trigger, tasks, connections, and the business field mapping |
| Your example | Problem → ServiceNow INC + PagerDuty in parallel |

## Summary

A **workflow** is an if-this-then-that automation inside Dynatrace. You define **when it starts** (trigger), **what it does** (tasks in order or parallel), and **which systems it talks to** (connections). To write one well, collect the trigger filters and the ticket/payload fields before you open the editor.

---

## 1. What is a Dynatrace workflow? (plain English)

| Concept | What it means | Analogy |
| --- | --- | --- |
| Workflow | Named automation | A runbook that runs itself |
| Trigger | Event that starts it | “When a Problem opens…” |
| Task | One step | Create SNOW ticket, call PD, run JS |
| Connection | Saved login to another system | ServiceNow URL + user |
| Execution | One run of the workflow | One Problem → one ticket create |
| Template (YAML) | Shareable recipe without secrets | Cookbook without passwords |
| Workflow JSON | Full export | Backup of the finished recipe |

```
Trigger (Problem / event / schedule / manual)
        │
        ▼
   Task 1 → Task 2 → Task 3 …
   (or parallel branches)
        │
        ▼
   Other systems (SNOW, PagerDuty, Slack, HTTP…)
```

Docs: [Workflows](https://docs.dynatrace.com/docs/analyze-explore-automate/workflows) · [Event / Problem triggers](https://docs.dynatrace.com/docs/analyze-explore-automate/workflows/trigger/event-trigger)

---

## 2. Main building blocks

### 2.1 Triggers (when)

| Trigger type | Starts when | Example |
| --- | --- | --- |
| **Problem** | Davis Problem open/close | Create INC on open; resolve on close |
| **Davis event** | Named event (host shutdown, …) | Tag host on maintenance |
| **Schedule (cron)** | Time | Hourly cleanup report |
| **Manual** | You click Run | Test / one-off |

You usually also set **filters**: severity, tags (`env:prod`), management zone, custom DQL.

### 2.2 Tasks (what)

| Task kind | Use for |
| --- | --- |
| **JavaScript** | Map fields, call APIs, custom logic |
| **HTTP request** | Generic REST (PagerDuty Events API) |
| **ServiceNow connector** | Create/search/resolve Incident |
| **DQL query** | Read Grail data mid-flow |
| **Slack / Teams / email** | Notify humans |
| Others | Jira, AWS, etc. if apps installed |

**Order:** `predecessors` = “wait for these tasks”.  
**Parallel:** two tasks share the same predecessor → run together.

### 2.3 Connections (how it authenticates)

| Connection | Holds |
| --- | --- |
| ServiceNow | Instance URL + user/OAuth |
| Others | API tokens as configured |

Never put long-lived passwords in chat/git if you can use **Connections**.

---

## 3. How to write a workflow (three ways)

### Way A — UI (best to learn)

1. Dynatrace → **Workflows** → **Create workflow**
2. Set **title** + **description**
3. Choose **trigger** (Problem / event / cron / manual)
4. Add **tasks** from the action panel
5. Link tasks (who runs after whom; mark parallel)
6. Bind **connections** on connector/HTTP tasks
7. Use expressions / JS `return { ... }` to pass data to the next task
8. **Save** → set **Active**
9. **Run** manually or wait for a real trigger → check **Executions**

### Way B — Upload template / workflow

| File | Upload as |
| --- | --- |
| `.yaml` | **Template** (portable) |
| `.json` | **Workflow** (full) |

Then: map Required apps → Connections → Import → edit → Active.

Your pack: `Daily Files/2026-09-13/4-snow-pd-workflow-yaml-and-json/`

### Way C — As code

Terraform `dynatrace_automation_workflow` or Monaco — for GitOps teams.

---

## 4. What information you must provide (checklist)

Collect this **before** building. Without it, the workflow stalls on empty dropdowns or wrong tickets.

### 4.1 Trigger info

| Info | Example | Why |
| --- | --- | --- |
| Trigger type | Problem / davis-event / cron | Defines start |
| Open vs close | Active only / Closed only | Create vs resolve flows |
| Severity filter | Error and above | Avoid noise |
| Entity filters | `env:prod`, `app:EIP` | Right scope |
| Maintenance behavior | Skip / always | Avoid tickets in MW |

### 4.2 Business / ticket info (your whiteboard)

| # | Info to provide | Example |
| --- | --- | --- |
| 1 | Who is caller | Dynatrace bot user sys_id / name |
| 2 | Business service | CMDB service name/sys_id per app |
| 3 | Assignment group | EIP-Support, CCI-Support, … |
| 4 | Priority rules | Error→P3, Resource→P4 (impact/urgency) |
| 5 | Dynatrace link + app + L1/L2/L3 | From Problem URL + ownership map |
| 6 | Runbook / article URL | Per-app Confluence/SOP link |

### 4.3 Integration info

| System | Provide |
| --- | --- |
| ServiceNow | Instance URL, integration user/password or OAuth, category/subcategory values, field sys_ids |
| PagerDuty | Events API v2 **routing_key**, target service |
| Dynatrace | External request allow-list for those hosts |
| Optional | Slack/Teams webhook or connection |

### 4.4 Mapping tables (write these down)

**App tag → ticket routing**

| `app` tag | Business service | Assignment group | L1 / L2 / L3 | Runbook URL |
| --- | --- | --- | --- | --- |
| EIP | … | EIP-Support | … | https://… |
| CCI | … | CCI-Support | … | https://… |
| default | … | Ops-Default | … | https://… |

**Severity → priority**

| Dynatrace severity | SNOW impact/urgency | P-level | PD severity |
| --- | --- | --- | --- |
| Availability / Critical | 2 / 2 | P3 (or P2) | critical |
| Error | 2 / 3 | P3 | error |
| Resource | 3 / 3 | P4 | warning |

### 4.5 Sync / close behavior

| Decision | Your choice |
| --- | --- |
| Parallel create SNOW + PD? | Yes / No |
| Cross-link how? | Work notes with PD `dedup_key` |
| On Problem close? | Resolve SNOW + PD resolve same `dedup_key` |
| Dedup key format | e.g. `dt-problem-<ProblemID>` |

### 4.6 Permissions (who can build/run)

See seq 5 for full list. Minimum idea:

| Role | Needs |
| --- | --- |
| Workflow author | `automation:workflows:read/write/run`, `app-engine:apps:run`, `app-engine:functions:run`, `app-settings:objects:read/write` |
| Workflows Authorization | Consent + `app-settings:objects:read` for SNOW actions |
| SNOW user | Create/update incident + read groups/choices |
| PD | Routing key owner |

---

## 5. Minimal “hello” workflow (learn the shape)

| Step | Setting |
| --- | --- |
| Trigger | Manual |
| Task 1 | JavaScript `return { msg: "hello", time: new Date().toISOString() };` |
| Task 2 | (optional) HTTP or log the result |
| Run | Executions → see output |

Then upgrade trigger to **Problem** and add SNOW/PD tasks.

---

## 6. Pattern for your SNOW + PD workflow

```
Problem OPEN
  → prepare-payload   (needs: maps in §4.4)
  → parallel:
       create ServiceNow INC   (needs: SNOW connection + fields §4.2)
       create PagerDuty        (needs: routing_key)
  → cross-link comment         (needs: both results)

Problem CLOSED (2nd workflow)
  → find INC by correlation_id
  → resolve SNOW + resolve PD
```

Info you personally must fill in the JS/maps:

- SNOW URL / caller / groups / business services / category  
- PD routing key  
- App→group→runbook→L1/L2/L3 table  
- P3/P4 rules  

---

## 7. Good habits

| Do | Don’t |
| --- | --- |
| One workflow for open, one for close | One mega-graph that is hard to debug |
| Use Connections for secrets | Commit passwords in YAML/JSON |
| Test with manual/non-prod Problem | Activate on all severities day one |
| Put Problem URL in every ticket | Ticket with no link back to Dynatrace |
| Stable `dedup_key` / `correlation_id` | Random IDs that cannot close/sync |

---

## Investigation

Aligned with Dynatrace Workflows concepts, Problem triggers, ServiceNow connector, and your SNOW+PD design (seq 1 + YAML/JSON seq 4 + permissions seq 5).

## Result

A workflow = trigger + tasks + connections. To write one, provide trigger filters, ticket field values, integration credentials, and app/priority/runbook maps—then build in UI or upload YAML/JSON.

## Data flow

```
You provide maps + connections
  → Write workflow (UI or YAML/JSON)
  → Trigger fires
  → Tasks run (parallel OK)
  → SNOW / PD / humans get the info
```

## Related files

| Path | Purpose |
| --- | --- |
| `../1-dynatrace-workflow-snow-pagerduty/` | Full SNOW+PD design |
| `../4-snow-pd-workflow-yaml-and-json/` | YAML + JSON files |
| `../5-setup-snow-pd-workflow-steps-perms/` | Permissions + setup steps |
| `6.sh` | Reminders |

## Commands

See `6.sh`.
