# Dynatrace SNOW PagerDuty Workflow Design

```
Need the full design?
  │
  ├─ Why / goals → §1–2
  ├─ Architecture pictures → §3–4
  ├─ Create + close pipelines → §5–6
  ├─ Data contracts / IDs → §7–8
  ├─ Security + failure → §9–10
  └─ Build artifacts → §11 + related YAML/JSON
```

| Key point | Detail |
| --- | --- |
| System | Dynatrace Workflows + ServiceNow (SNOW) + PagerDuty (PD) |
| Goal | Problem open → INC + PD page in parallel → sync IDs → close both |
| Correlation | `correlation_id` (SNOW) = Problem ID; `dedup_key` (PD) = `dt-problem-<ProblemID>` |
| Artifacts | Seq 1 guide · Seq 4 YAML/JSON · Seq 5 permissions |

## Summary

This design turns a Dynatrace **Davis Problem** into operational work in **two systems at once**: ServiceNow for ITIL tickets/SLA/audit, and PagerDuty for on-call paging. Dynatrace owns open and close. Cross-linking keeps humans from guessing which INC matches which page. Optional native PD↔SNOW sync can move assignees later; it is not required for the core design.

---

## 1. Goals and non-goals

### 1.1 Goals

| Goal | What “good” looks like |
| --- | --- |
| Auto-ticket | Every qualifying Problem creates one SNOW Incident |
| Auto-page | Same Problem triggers one PD incident/alert |
| Parallel | SNOW and PD start together (lower time-to-ticket and time-to-page) |
| Rich context | Ticket has caller, business service, assignment, P3/P4, DT link, app, L1–L3, runbook |
| Sync | Work notes hold PD `dedup_key`; close Problem resolves both |
| Safe scope | Prod filters; no STG ticket storms |

### 1.2 Non-goals (out of scope for v1)

| Non-goal | Note |
| --- | --- |
| Replace CMDB discovery | Business service mapping is tag/table based |
| Full ITIL Problem Management record | Only Incident create/resolve |
| Guaranteed PD↔SNOW assignee sync | Optional product extension |
| 3-week KPI dashboards | Consume SNOW data later; not built in Workflow |

### 1.3 Design principles

| Principle | Meaning |
| --- | --- |
| Dynatrace is source of truth for health | Problem URL stays primary RCA link |
| Stable correlation keys | Same Problem ID everywhere |
| Two workflows | Open create vs close resolve (simpler ops) |
| Secrets in Connections | Not in git YAML/JSON when avoidable |
| Fail visible | Execution history shows which leg failed |

---

## 2. Actors and systems

| Actor / system | Role |
| --- | --- |
| Monitored apps/hosts | Generate metrics/logs/events |
| Dynatrace Davis | Opens/closes **Problems** |
| Dynatrace Workflows | Orchestrates create/resolve |
| ServiceNow (SNOW) | Incident record, SLA, assignment, audit |
| PagerDuty (PD) | Notify on-call, escalate |
| On-call L1/L2/L3 | Work ticket + use runbook + DT link |
| Optional KPI consumer | Reads SNOW for 3-week environment KPIs |

---

## 3. System context architecture

```
┌──────────────┐     detect      ┌─────────────────────┐
│ Apps / Hosts │ ──────────────► │ Dynatrace (Davis)    │
│ OneAgent etc │                 │ Problems + Grail     │
└──────────────┘                 └──────────┬──────────┘
                                            │ Problem OPEN / CLOSED
                                            ▼
                                 ┌─────────────────────┐
                                 │ Dynatrace Workflows │
                                 │  WF-A Create        │
                                 │  WF-B Close         │
                                 └──────────┬──────────┘
                         ┌──────────────────┼──────────────────┐
                         ▼                  ▼                  ▼
              ┌──────────────────┐ ┌─────────────────┐ ┌──────────────┐
              │ ServiceNow       │ │ PagerDuty       │ │ (optional)   │
              │ Incident table   │ │ Events API v2   │ │ Slack/Teams  │
              └────────┬─────────┘ └────────┬────────┘ └──────────────┘
                       │                    │
                       └─────────┬──────────┘
                                 ▼
                        On-call + runbooks
                                 │
                                 ▼
                        (optional) 3-week KPI
```

### Trust / network boundary

```
┌──── Dynatrace SaaS ────┐   HTTPS    ┌──── Customer SaaS ────┐
│ Workflows runtime      │ ─────────► │ ServiceNow instance   │
│ Connections (secrets)  │ ─────────► │ PagerDuty Events API  │
│ External request ACL   │            │                       │
└────────────────────────┘            └───────────────────────┘
         ▲
         │ if SNOW IP-allows only corp egress:
         │ EdgeConnect / fixed IP path
```

---

## 4. Logical component architecture

| Component | Technology | Responsibility |
| --- | --- | --- |
| Trigger A | Problem trigger (Active) | Start create flow |
| Trigger B | Problem trigger (Closed) | Start resolve flow |
| prepare-payload | JS task | Normalize Problem → routing + priority + runbook |
| create-servicenow | SNOW connector or HTTP | POST Incident |
| create-pagerduty | HTTP / JS | POST Events API v2 trigger |
| cross-link | SNOW comment/PATCH | Write PD key into INC work notes |
| resolve-snow | Search + Resolve/PATCH | Close INC by `correlation_id` |
| resolve-pd | HTTP resolve | Close PD with same `dedup_key` |
| assignMap config | JS constants / future settings | app → group / biz / L1–L3 / runbook |

### Task dependency graph (Create = WF-A)

```
[Problem OPEN]
      │
      ▼
[prepare-payload]
      │
      ├──────────────────┐
      ▼                  ▼
[create-servicenow] [create-pagerduty]     ← parallel
      │                  │
      └────────┬─────────┘
               ▼
        [cross-link-snow-pd]
               ▼
            [end]
```

### Task dependency graph (Close = WF-B)

```
[Problem CLOSED]
      │
      ▼
[resolve-snow-and-pd]   (search INC + PATCH + PD resolve)
      ▼
    [end]
```

---

## 5. End-to-end data flow — Create (happy path)

### 5a. Pipeline stage overview

| Stage | Component | Role | Protocol |
| --- | --- | --- | --- |
| 1 Detect | Davis | Open Problem | Internal |
| 2 Trigger | Workflows Problem trigger | Match filters | Event |
| 3 Prepare | JS | Build payload object | In-process |
| 4a Ticket | ServiceNow | Create INC | HTTPS REST |
| 4b Page | PagerDuty | Trigger alert/incident | HTTPS REST |
| 5 Sync | ServiceNow | Work notes with PD key | HTTPS REST |
| 6 Human | On-call | Work INC + DT URL | UI |

### 5b. Stage detail — Detect → Trigger

| Item | Design |
| --- | --- |
| Input | Problem becomes Active (open/re-open) |
| Filters | Severity ≥ Error (tune); optional `env:prod`; exclude lab |
| Skip | Info-only; entities under maintenance (optional) |
| Output to WF | Problem event context (id, title, url, severity, tags, entities) |

### 5c. Stage detail — Prepare

| Input field (from Problem) | Output field (to later tasks) |
| --- | --- |
| title / event.name | `problemTitle`, `shortDescription` |
| display_id / problem id | `problemId`, `dedupKey` |
| problem url | `problemUrl` |
| severity | `impact`, `urgency`, `pLevel`, `pdSeverity` |
| tags `app:` / `AGO_GLOBAL_APP` | `app` + lookup `assignMap` |
| assignMap[app] | group, biz service, L1/L2/L3, runbook |

| Priority rule (default design) | P-level |
| --- | --- |
| Availability / Critical-like | P3 (extend to P2/P1 if ITIL requires) |
| Error | P3 |
| Resource / Slowdown | P4 |
| Info | Do not trigger WF |

### 5d. Stage detail — ServiceNow create

| SNOW field | Source |
| --- | --- |
| `correlation_id` | `problemId` |
| `caller_id` | Dynatrace bot sys_id |
| `category` / `subcategory` | Org constants (e.g. Software / Application) |
| `impact` / `urgency` | From prepare (drives Priority) |
| `assignment_group` | From assignMap |
| `business_service` | From assignMap |
| `short_description` | `[Dynatrace] {title} — {app}` |
| `description` | Caller, biz, P-level, DT URL, L1–L3, runbook |

API: `POST /api/now/v2/table/incident` (or connector Create Incident).

Output kept in execution: `number` (INC…), `sys_id`.

### 5e. Stage detail — PagerDuty trigger

| PD field | Source |
| --- | --- |
| `routing_key` | Events API v2 integration key |
| `event_action` | `trigger` |
| `dedup_key` | `dt-problem-{problemId}` |
| `payload.summary` | Same story as short description |
| `payload.severity` | critical / error / warning |
| `payload.source` | app |
| `links` | Problem URL + runbook |
| `custom_details` | problem_id, biz, group, P-level, L1–L3, caller |

API: `POST https://events.pagerduty.com/v2/enqueue`

### 5f. Stage detail — Cross-link

| Action | Content |
| --- | --- |
| PATCH/comment INC | `PagerDuty dedup_key=dt-problem-…` + Problem URL + runbook |
| Optional | Push INC number into PD note (REST) |

---

## 6. End-to-end data flow — Close

| Stage | What happens |
| --- | --- |
| 1 | Problem moves to Closed |
| 2 | WF-B starts |
| 3 | Search SNOW `correlation_id = problemId` |
| 4 | Resolve INC (state/close_code/notes: “Dynatrace Problem closed”) |
| 5 | PD `event_action=resolve` + **same** `dedup_key` |
| 6 | If INC missing → log skip (do not fail forever blindly; alert owners) |

```
Problem CLOSED
  → find INC by correlation_id
  → Resolve INC
  → PD resolve(dedup_key=dt-problem-<id>)
```

---

## 7. Correlation and identity design

| System | Key | Format | Purpose |
| --- | --- | --- | --- |
| Dynatrace | Problem ID | e.g. `P-…` / display id | Source of truth |
| ServiceNow | `correlation_id` | Same Problem ID | Find/update/resolve |
| PagerDuty | `dedup_key` | `dt-problem-<ProblemID>` | Dedup + resolve |
| ServiceNow | `number` | `INC######` | Human ticket |
| ServiceNow | `sys_id` | UUID | API updates |

```
ProblemID ──► SNOW.correlation_id
     └──────► PD.dedup_key = "dt-problem-" + ProblemID
```

**Rule:** Never invent a new random key per run. Reuse Problem ID family or you cannot close/sync.

---

## 8. Sequence diagram (create)

```
Davis          Workflows         ServiceNow         PagerDuty
  │                │                 │                  │
  │ Problem OPEN   │                 │                  │
  │───────────────►│                 │                  │
  │                │ prepare         │                  │
  │                │──┐              │                  │
  │                │◄─┘              │                  │
  │                │ POST incident   │                  │
  │                │────────────────►│                  │
  │                │ INC + sys_id    │                  │
  │                │◄────────────────│                  │
  │                │ POST enqueue (parallel)            │
  │                │───────────────────────────────────►│
  │                │ dedup_key ack                      │
  │                │◄───────────────────────────────────│
  │                │ PATCH work_notes│                  │
  │                │────────────────►│                  │
  │                │                 │                  │
  │           (on-call works INC + opens Problem URL)   │
```

---

## 9. Security and permissions (design view)

| Layer | Control |
| --- | --- |
| Dynatrace IAM | workflows read/write/run, app-engine run/functions, app-settings read/write |
| Workflows Authorization | Consent including `app-settings:objects:read` |
| SNOW user | Least privilege: incident write + group/choice read |
| PD | Routing key treated as secret |
| Network | External requests allow-list; EdgeConnect if IP-locked |
| Data | No raw customer PII in ticket text; Problem URL + metadata only |

Detail checklist: `../5-setup-snow-pd-workflow-steps-perms/`

---

## 10. Failure modes and operability

### 10a. Common issues

| Failure | Effect | Design response |
| --- | --- | --- |
| SNOW down, PD OK | Page without INC | Retry SNOW; alert platform; still cross-link when SNOW recovers |
| PD down, SNOW OK | INC without page | Retry PD; on-call may miss page — monitor WF failures |
| Both succeed, cross-link fails | Tickets exist unlinked | Retry comment; search by correlation_id |
| Missing `app` tag | Wrong default group | Fix tagging; default group + noisy short_description |
| Duplicate WF runs | Duplicate INC risk | Trigger only Active open; correlation_id unique handling |
| Close without create | Resolve finds nothing | Soft-skip + metric/log |
| IP 403 to SNOW | Create fails | EdgeConnect / allow list |

### 10b. Responsibility matrix

| Concern | Owner |
| --- | --- |
| Workflow code / YAML | Observability / SRE automation |
| assignMap (app→group/runbook) | App owners + SRE |
| SNOW user + groups + priority matrix | ITSM / SNOW admin |
| PD service + routing key | On-call / PD admin |
| Entity tags `app`/`env` | Platform + app teams |
| Execution failure alerts | SRE on-call for automation |

### 10c. Observability of the automation

| Signal | Where |
| --- | --- |
| Workflow execution success/fail | Workflows → Executions |
| INC created rate | SNOW reporting / KPI |
| PD trigger rate | PD analytics |
| Orphan INC (no Problem) | Audit correlation_id prefix |
| Orphan PD (no INC) | Work notes missing / failed cross-link |

---

## 11. Deployment architecture (artifacts)

| Artifact | Role |
| --- | --- |
| WF-A YAML/JSON | Create path |
| WF-B YAML/JSON | Close path |
| Connections | SNOW (preferred over password in script) |
| External requests | Host allow |
| Runbook URLs | Confluence / SOP |

Files:

| Path | Content |
| --- | --- |
| `../4-snow-pd-workflow-yaml-and-json/` | Uploadable YAML + JSON |
| `../1-dynatrace-workflow-snow-pagerduty/` | Original build guide |
| This file | Detailed design |

```
Git / Daily Files
  → Upload template YAML (or JSON)
  → Map connections
  → Activate WF-A + WF-B
  → Test non-prod Problem
  → Enable prod filters
```

---

## 12. Example instance walkthrough (EIP)

| Time | Event |
| --- | --- |
| T0 | Checkout latency → Davis Problem `P-1001`, severity Error, tag `app:EIP` |
| T0+ | WF-A matches Active + Error |
| T1 | prepare → P3, group EIP-Support, runbook EIP |
| T2 | Parallel: INC0019999 created; PD alert with `dedup_key=dt-problem-P-1001` |
| T3 | INC work notes get PD key + Problem URL |
| T4 | L1 opens INC → clicks Dynatrace link → follows runbook |
| T5 | Fix deployed; Problem closes |
| T6 | WF-B resolves INC0019999; PD resolve same dedup_key |

---

## Investigation

Expanded from seq 1 design, whiteboard requirements (caller, business service, assignment, priority, DT link, L1–L3, runbook, parallel SNOW+PD, close sync), Dynatrace Workflows Problem trigger, ServiceNow Table/connector APIs, and PagerDuty Events API v2.

## Result

Two-workflow architecture with parallel create, correlation via Problem ID, and closed-loop resolve. Implement with seq 4 artifacts; operate with seq 5 permissions.

## Data flow map (compact)

```
Apps → Dynatrace Davis Problem
         │ OPEN
         ▼
      WF-A prepare → {payload}
         ├─► SNOW INC (correlation_id=ProblemID)
         └─► PD trigger (dedup_key=dt-problem-ProblemID)
         ▼
      cross-link work notes
         │
         │ CLOSED
         ▼
      WF-B → Resolve INC + PD resolve
```

## Related files

| File | Purpose |
| --- | --- |
| `8.sh` | Pointers |
| `architecture-overview.txt` | ASCII context diagram only |
| Seq 4 | YAML + JSON |
| Seq 5 | Permissions / setup steps |

## Commands

See `8.sh`.
