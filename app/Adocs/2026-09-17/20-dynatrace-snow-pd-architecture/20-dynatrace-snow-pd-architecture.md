# Dynatrace Snow Pd Architecture

```
What runs when a Dynatrace Problem opens?
  │
  ├─ Monitoring detects issue → Davis creates Problem
  │
  ├─ Workflow OPEN fires (Connector path)
  │     prepare → SNOW INC + PagerDuty in parallel → cross-link comment
  │
  ├─ Optional: classic notification ITOM event only (ITSM OFF)
  │
  └─ When Problem closes → Workflow CLOSE
        search INC by correlation_id → resolve SNOW + resolve PD
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| Goal | One Dynatrace Problem becomes one ServiceNow Incident and one PagerDuty alert that stay in sync |
| Brain | Dynatrace Workflows (two workflows: open and close) |
| Ticket system | ServiceNow via **Connector** (Connection + `snow-*` actions) |
| Page system | PagerDuty Events API v2 from a JS task |
| Glue | Shared key `dt-problem-<problemId>` |
| Classic notification | Keep for ITOM events if you want; turn **ITSM OFF** so you do not get two INCs |

## Summary

This architecture watches Dynatrace Problems. When a Problem opens, a workflow creates a rich ServiceNow Incident and pages PagerDuty at the same time, then writes a cross-link comment. When the Problem closes, a second workflow finds that Incident and resolves both ServiceNow and PagerDuty. Credentials live in a Connection object, not in the YAML password fields.

---

## Investigation

User asked for the whole architecture again in detail for the ServiceNow Connector + PagerDuty design (seq 13 / 17 / 19 packs), including how classic notification fits beside it.

## Result

Use the sections below as the full mental model: layers, open path, close path, sync key, what not to double-enable, and ownership of each piece.

---

## 1) What this architecture is (plain English)

Think of three tools with three jobs:

| Tool | Job in this design | Analogy |
| --- | --- | --- |
| Dynatrace | Sees the outage and opens/closes a **Problem** | Smoke detector |
| ServiceNow | Holds the **Incident ticket** for tracking and handoff | Ticket desk |
| PagerDuty | **Pages** the on-call person | Phone that rings |

The Dynatrace **Workflow** is the automation glue. It listens for Problem events and talks to ServiceNow and PagerDuty for you.

---

## 2) Big-picture layers

```
[ Apps / hosts / services ]
           │
           ▼
[ Dynatrace OneAgent / Synthetic / logs / metrics ]
           │
           ▼
[ Davis AI → Problem object (OPEN or CLOSED) ]
           │
           ├──────────────────────────────┐
           ▼                              ▼
[ Workflow OPEN / CLOSE ]     [ Optional classic Problem notification ]
           │                   (servicenowstg — ITOM only recommended)
           │
     ┌─────┴─────┐
     ▼           ▼
[ ServiceNow ] [ PagerDuty ]
  INC ticket    page / alert
  (Connector)   (Events API)
```

| Layer | What it means | Why you care |
| --- | --- | --- |
| Detect | Dynatrace collects signals and Davis groups them into a Problem | Source of truth for “something is wrong” |
| Automate | Workflows react to Problem open/close | You control fields, parallel PD, resolve on close |
| Ticket | ServiceNow INC via Connector | Ops process, assignment groups, audit trail |
| Page | PagerDuty trigger/resolve | Human gets woken up |
| Optional classic | Problem notification to same SNOW instance | Can still send ITOM **events** without creating a second INC |

---

## 3) Two Dynatrace objects people mix up

| Object | Where you configure it | What it does here |
| --- | --- | --- |
| ServiceNow **Connection** | Settings → Connections (app `dynatrace.servicenow`) | Stores URL + credentials. Workflow `snow-*` tasks use it. |
| Classic **Problem notification** (`servicenowstg`) | Settings → Problem notifications | Platform auto-push of Problems to SNOW (ITSM and/or ITOM). **Not** a workflow task. |

| Rule | What it means |
| --- | --- |
| Connection owns INC create/resolve in this design | Workflow calls `snow-create-incident` and later `snow-resolve-incident` |
| Classic ITSM should be OFF | If ITSM stays ON and the workflow also creates INC, you get **two tickets** for one Problem |
| Classic ITOM can stay ON | You can still get SNOW **events** from notification while INC comes from the Connector |

You cannot set `connectionId = servicenowstg`. Those are different objects.

---

## 4) Components inside the Workflow pack

### OPEN workflow title (example)

`AGO - Problem to ServiceNow (Connection) and PagerDuty`

| Task | Type | What it does |
| --- | --- | --- |
| prepare-payload | JavaScript | Reads Problem event. Maps app tag → assignment group, business service, L1/L2/L3, runbook. Sets impact/urgency and builds description. |
| create-servicenow-incident | Connector action `snow-create-incident` | Creates the INC using the Connection (no SNOW password in the script). |
| create-pagerduty-incident | JavaScript + `fetch` | POSTs to PagerDuty Events API v2 with `event_action: trigger`. |
| cross-link-snow-pd | Connector action `snow-comment-on-incident` | After both succeed, comments the PD `dedup_key` and Problem URL on the INC. |

OPEN trigger (idea): Davis Problem is ACTIVE, and status transition is CREATED, UPDATED, or REOPENED.

### CLOSE workflow title (example)

`AGO - Problem closed resolve ServiceNow (Connection) and PagerDuty`

| Task | Type | What it does |
| --- | --- | --- |
| prepare-close-ids | JavaScript | Builds `problemId` and `dedupKey = dt-problem-<id>`. |
| search-snow-incident | Connector action `snow-search-incidents` | Finds INC where `correlation_id` matches. |
| resolve-snow-incident | Connector action `snow-resolve-incident` | Resolves that INC if search found a row. |
| resolve-pagerduty | JavaScript + `fetch` | POSTs `event_action: resolve` with the same `dedup_key`. |

CLOSE trigger (idea): Problem status CLOSED, or transition RESOLVED / CLOSED.

---

## 5) Happy path — Problem opens

```
1. Something breaks in production
2. Dynatrace Davis opens Problem P-12345
3. OPEN workflow starts
4. prepare-payload
      - read title, severity, tags (e.g. app:EIP)
      - pick assignMap row for EIP (group, biz service, L1/L2/L3, runbook)
      - map severity → impact/urgency → P3 or P4 intent
      - set dedupKey = dt-problem-P-12345
5. In parallel:
      A) snow-create-incident → INC0012345 in silvastg
         correlation_id / correlation field tied to Problem id
      B) PagerDuty trigger → on-call alert with same dedup_key
6. cross-link-snow-pd → work note on INC with PD key + Problem URL
7. Human works the ticket and/or the page
```

### What lands on the ServiceNow Incident

| Field / content | Source |
| --- | --- |
| Short description | `[Dynatrace] <title> — <app>` |
| Description | Caller, business service, Problem URL, L1/L2/L3, runbook |
| Impact / urgency | From severity mapping in prepare-payload |
| Assignment group | From `assignMap` using app tag |
| Correlation | Problem id / `dt-problem-<id>` so CLOSE can find it |
| Later comment | PagerDuty dedup_key + links |

### What lands on PagerDuty

| Field | Source |
| --- | --- |
| routing_key | Your integration key (`__PD_ROUTING_KEY__`) |
| dedup_key | Same `dt-problem-<id>` |
| summary / severity | From prepare-payload |
| custom_details | Problem id, URL, groups, runbook |

---

## 6) Happy path — Problem closes

```
1. Issue is fixed (or Davis auto-closes)
2. Problem P-12345 goes CLOSED
3. CLOSE workflow starts
4. prepare-close-ids → problemId, dedupKey
5. search-snow-incident → find INC by correlation_id
6. If found → snow-resolve-incident (resolution notes mention Dynatrace close)
7. In parallel path from prepare → resolve-pagerduty with same dedup_key
8. Ticket resolved + page cleared (when PD accepts resolve)
```

If search finds nothing, resolve-snow is skipped (custom condition). PagerDuty resolve can still run from the close-ids step so the page does not stick forever.

---

## 7) The sync key (why tickets and pages stay tied)

| System | Field | Value example |
| --- | --- | --- |
| Dynatrace | Problem display id | `P-12345` |
| ServiceNow | correlation_id (search query) | problem id / same family as open |
| PagerDuty | dedup_key | `dt-problem-P-12345` |
| Cross-link comment | Text on INC | Includes the PD dedup_key |

| Concept | What it means | Why you care |
| --- | --- | --- |
| Same key on open | Both sides store the same Problem-based id | CLOSE can find the right INC and resolve the right PD alert |
| Parallel create | SNOW and PD do not wait on each other after prepare | Faster; one slow API does not block the other start |
| Cross-link comment | Human reading INC sees PD key and Problem URL | Bridge when tools do not share a native link |

---

## 8) Credentials, allowlist, and safety

| Piece | What it means | Why you care |
| --- | --- | --- |
| ServiceNow Connection | URL `https://silvastg.service-now.com` + user/OAuth stored in Dynatrace | Workflow snow tasks use `connectionId`; password not pasted into YAML |
| PagerDuty routing key | Integration key in JS placeholder `__PD_ROUTING_KEY__` | Required for Events API trigger/resolve |
| External requests allowlist | Dynatrace must allow outbound to SNOW and PD hosts | Without allowlist, Connector or `fetch` fails |
| assignMap placeholders | `__SNOW_GROUP_SYS_ID_EIP__` etc. | Real sys_ids from your SNOW CMDB / groups |
| Classic ITSM OFF | Notification does not also create INC | Prevents duplicate tickets |

Outbound hosts to allow:

| Host | Used by |
| --- | --- |
| `silvastg.service-now.com` | Connector snow actions (and classic notification if kept) |
| `events.pagerduty.com` | JS PagerDuty trigger and resolve |

---

## 9) Severity and routing logic (inside prepare-payload)

| Dynatrace signal | Impact | Urgency | Priority intent | PD severity |
| --- | --- | --- | --- | --- |
| AVAILABILITY or CRITICAL | 2 | 2 | P3 | critical |
| ERROR | 2 | 3 | P3 | error |
| Else (default) | 3 | 3 | P4 | warning |

| App tag example | Assignment idea |
| --- | --- |
| `app:EIP` | EIP support group + EIP business service + EIP L1/L2/L3 + EIP runbook |
| `app:CCI` | CCI mapping |
| Missing / unknown | Default Ops mapping |

Replace placeholder sys_ids with real ServiceNow values before production.

---

## 10) What is intentionally NOT in this architecture

| Approach | Role vs this design |
| --- | --- |
| Classic ITSM ON for INC create | Avoid while Connector creates INC |
| Workflow task that “runs” Problem notification | Does not exist in Dynatrace |
| JS `fetch` to SNOW REST for INC create (seq 18 style) | Alternate mimic; this architecture uses official Connector actions instead |
| PD-only workflow with notification owning INC (seq 15) | Different split of ownership |

---

## 11) Failure modes (on-call view)

| Symptom | Likely cause | What to check |
| --- | --- | --- |
| No INC created | Workflow inactive, Connection wrong, or snow task failed | Workflow execution log; Connection URL/auth |
| Two INCs for one Problem | Classic ITSM still ON **and** Connector create | Turn ITSM OFF on `servicenowstg` |
| INC created, no page | PD key wrong or allowlist missing PD | `__PD_ROUTING_KEY__`, allowlist `events.pagerduty.com` |
| Page created, no INC | Connection / snow action failure | SNOW allowlist, Connection map on task |
| Close does not resolve INC | correlation_id mismatch or search empty | Compare open correlation vs close query |
| Close does not clear PD | Wrong dedup_key or resolve failed | Same `dt-problem-<id>` as open trigger |
| Upload / schema errors | Trigger categories or positions | Use the working YAML from seq 19 |

---

## 12) Responsibility matrix

| Piece | Who owns it | Notes |
| --- | --- | --- |
| Problem detection / severity | Dynatrace / app owners (tagging) | Tags like `app` drive assignMap |
| OPEN / CLOSE workflows | Platform / SRE automation | Upload, activate, monitor executions |
| ServiceNow Connection | Platform + SNOW admin | Credentials, roles on integration user |
| INC process fields | SNOW process owners | Groups, biz services, resolution codes |
| PagerDuty service / routing key | On-call owners | Escalation policy behind the key |
| Classic notification ITOM | Optional platform choice | Keep aligned with same instance URL |
| Allowlist | Dynatrace admin | Both SNOW and PD hosts |
| Runbooks linked in ticket | App / SRE authors | URLs in assignMap |

---

## Data flow map

```
                    ┌─────────────────────┐
                    │  Dynatrace Problem  │
                    └──────────┬──────────┘
                               │
              OPEN             │             CLOSE
               │               │               │
               ▼               │               ▼
        prepare-payload        │        prepare-close-ids
               │               │               │
       ┌───────┴───────┐       │       ┌───────┴────────┐
       ▼               ▼       │       ▼                ▼
 snow-create      PD trigger   │  snow-search      PD resolve
  incident                     │   incidents
       │               │       │       │
       └───────┬───────┘       │       ▼
               ▼               │  snow-resolve
     snow-comment              │   incident
     (cross-link)              │
                               │
        Optional classic notification (ITOM event only)
                               │
                               ▼
                    silvastg.service-now.com
                    events.pagerduty.com
```

Sync string: `dt-problem-<problemId>`

---

## Related files

| Path | Why |
| --- | --- |
| `../19-snow-connector-workflow-again/` | Current Connector YAML to upload |
| `../13-working-snow-pd-workflow-yaml/` | Original working Connector pack |
| `../14-snow-connector-vs-problem-notification/` | Connector vs classic notification diff |
| `../15-workflow-snow-via-problem-notification/` | Alternate: notification owns INC |
| `../18-snow-notification-via-javascript-rest/` | Alternate: JS REST mimic |
| `20.sh` | Paths only |

## Commands

See `20.sh` in this folder. Review and run yourself; nothing was executed for you.
