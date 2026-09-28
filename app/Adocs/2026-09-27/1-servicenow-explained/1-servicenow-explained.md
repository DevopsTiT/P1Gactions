# ServiceNow Explained

```
What is SNOW for us?
  → The official ticket system (ITSM) — the "paper trail"
  → PagerDuty wakes people; SNOW records the incident

How does a Dynatrace problem become a SNOW ticket?
  Connector allowed?  YES → dynatrace.servicenow snow-* actions
                      NO  → HTTP POST to SILVA (your case)
  SILVA decides       → checks CMDB → create INC or skip

Ticket missing?
  → allowlist? → auth? → SILVA skipped it (retired host)? → duplicate notification?
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What SNOW is | ServiceNow: a SaaS platform for IT tickets, changes, and asset records |
| Our instance | `https://silvastg.service-now.com` (STG example) |
| Main object | **Incident** (`INC0012345`) in the `incident` table |
| Role vs PagerDuty | PagerDuty pages the human; SNOW keeps the official record and audit trail |
| Your constraint | Native SNOW connector not allowed → send alerts to **SILVA** over HTTP; SILVA creates the INC |

## Summary

ServiceNow (SNOW) is where companies keep the official record of IT work: incidents, changes, requests, and the inventory of servers and apps (CMDB). In your setup, Dynatrace detects the problem, PagerDuty pages on-call, and SNOW holds the ticket that auditors, managers, and other teams read. You are not allowed to create incidents directly with the Dynatrace connector, so Dynatrace sends an HTTP alert to SILVA, and SILVA decides whether to create the incident.

## Investigation

User asked "explain snow". Built on earlier packs (2026-09-17 seq 27 and 28) and the SILVA chat from 2026-09-24 (no native connector, HTTP post, CMDB gatekeeper, outbound allowlist).

## Result

Read sections 1 to 8 below. The practical rule for you: Dynatrace → HTTP → SILVA → SNOW Incident, synced by `correlation_id`.

---

## 1) Plain English

| Concept | What it means | Why you care |
| --- | --- | --- |
| ServiceNow | Cloud platform for IT service management | It is the company's official ticket system |
| ITSM | IT Service Management: incidents, problems, changes, requests | Process rules live here |
| Instance | Your company's own SNOW site | Ours: `silvastg.service-now.com` |
| Table | SNOW stores everything as rows in tables | `incident`, `change_request`, `cmdb_ci` |
| Record | One row, such as one incident | Has a number and a `sys_id` |

**Analogy:** PagerDuty is the fire alarm. ServiceNow is the fire department's logbook: who responded, what happened, when it was fixed, and why.

---

## 2) The main SNOW objects

| Object | Table | What it is | Example |
| --- | --- | --- | --- |
| Incident | `incident` | Something is broken right now | `INC0012345` checkout latency high |
| Problem | `problem` | The root cause behind repeated incidents | `PRB0001234` DB pool too small |
| Change | `change_request` | A planned change to production | `CHG0005678` deploy v2.3 |
| Request | `sc_request` | A user asks for something | New access, new server |
| Configuration item (CI) | `cmdb_ci` and child tables | A server, app, or database in the inventory | `host-app-01` |
| Event | `em_event` | Raw monitoring signal (ITOM) | Dynatrace alert before it becomes an incident |

**CMDB** (Configuration Management Database) is the inventory of all CIs and how they connect. SILVA uses it to decide if an alert matters.

---

## 3) Important fields on an Incident

| Field | What it means | Our usage |
| --- | --- | --- |
| `number` | Human ticket number | `INC0012345` |
| `sys_id` | Internal unique id (32 characters) | Used in API update calls |
| `short_description` | Title | `[Dynatrace] Checkout latency high` |
| `description` | Long text | Problem id and Dynatrace URL |
| `impact` | How many users are affected (1 high, 3 low) | Mapped from Dynatrace severity |
| `urgency` | How fast it must be fixed (1 high, 3 low) | Mapped from Dynatrace severity |
| `priority` | Calculated from impact and urgency | P1 to P4 |
| `state` | Lifecycle state | 1 New, 2 In Progress, 6 Resolved, 7 Closed |
| `assignment_group` | Team that owns the ticket | Often set by SILVA rules |
| `cmdb_ci` | Linked server or app | Links ticket to the inventory |
| `correlation_id` | External reference id | **Dynatrace problem id** — our sync key |

---

## 4) Incident lifecycle

```
New (1)
  → In Progress (2)   team picks it up
  → On Hold (3)       waiting on someone (optional)
  → Resolved (6)      fix applied, close notes written
  → Closed (7)        auto-closes after a few days
```

| Step | Who usually does it |
| --- | --- |
| Create | Automation (SILVA from Dynatrace) or a human |
| Assign | SILVA rules or service desk |
| Work | On-call engineer (after the PagerDuty page) |
| Resolve | Automation on Dynatrace close, or the engineer |
| Close | SNOW automatically |

---

## 5) How Dynatrace can reach SNOW (three paths)

| Path | How it works | Status for you |
| --- | --- | --- |
| A. Native connector | Workflow tasks `dynatrace.servicenow:snow-create-incident` and similar | **Not allowed** in your org |
| B. Classic Problem notification | Settings → Integrations → ServiceNow (ITSM/ITOM toggles) | Keep ITSM **off** to avoid duplicate tickets |
| C. HTTP to SILVA | Workflow `run-javascript` or HTTP action posts the alert; SILVA creates INC | **Your path** |

### Your path in detail

```
Dynatrace Problem
  → Workflow (HTTP POST)
  → SILVA
       → checks CMDB
            host active?   → create Incident in SNOW
            host retired?  → skip (no ticket)
  → SNOW Incident (correlation_id = problem id)
```

Example from the team chat: a host alert goes to SILVA, SILVA sees the host is **retired** in CMDB, and no incident is created. That is expected behavior, not a bug.

---

## 6) SNOW APIs you meet

| Action | Method and URL | Used for |
| --- | --- | --- |
| Create incident | `POST /api/now/v2/table/incident` | Open ticket |
| Find by sync key | `GET /api/now/v2/table/incident?sysparm_query=correlation_id=P-12345` | Find the ticket on close |
| Update / resolve | `PATCH /api/now/v2/table/incident/{sys_id}` | Set `state=6`, close notes |
| Create event | `POST /api/now/v2/table/em_event` | ITOM event (optional) |

**Auth:** usually Basic auth with a technical user such as `Tech_DynatraceJP_WS`, or OAuth.

**Outbound allowlist:** Dynatrace blocks unknown hosts. Add `silvastg.service-now.com` (and `events.pagerduty.com`) under Settings → External requests on **each** tenant. That is why EU STG worked but Sandbox failed.

---

## 7) SNOW vs PagerDuty vs Dynatrace

| Tool | Job | Main object |
| --- | --- | --- |
| Dynatrace | Detect the problem | Problem `P-12345` |
| PagerDuty | Wake the on-call human | Incident with `dedup_key` |
| ServiceNow | Official record, process, audit | Incident `INC0012345` |
| SILVA | Gatekeeper between alerts and SNOW | Rules and CMDB checks |

| Sync key | Where |
| --- | --- |
| `correlation_id = P-12345` | SNOW incident |
| `dedup_key = dt-problem-P-12345` | PagerDuty |

---

## 8) Common problems

| Symptom | Likely cause | What to check |
| --- | --- | --- |
| No ticket, workflow shows network error | Outbound allowlist missing | Settings → External requests on this tenant |
| HTTP 401 or 403 | Wrong user, password, or role | Technical user and roles |
| No ticket, HTTP 200 | SILVA skipped it | CMDB status of the host (retired?) |
| Two tickets for one problem | Classic notification ITSM still on | Turn ITSM off while using the workflow |
| Ticket never resolves | Close workflow inactive or wrong `correlation_id` | Activate CLOSE; check the key |
| Wrong team assigned | SILVA or assignment rules | Ask the SNOW / SILVA owners |

---

## Data flow map

```
Apps / hosts
  → Dynatrace detects Problem P-12345
  → Workflow OPEN
       ├─ HTTP → SILVA → CMDB check → SNOW INC0012345 (correlation_id=P-12345)
       └─ HTTP → PagerDuty trigger (dedup_key=dt-problem-P-12345) → on-call paged
  → Engineer fixes
  → Dynatrace closes Problem
  → Workflow CLOSE
       ├─ SNOW GET by correlation_id → PATCH state=6 (Resolved)
       └─ PagerDuty resolve
```

---

## Related files

| File | Role |
| --- | --- |
| `2026-09-17/27-servicenow-explained/` | Earlier SNOW overview |
| `2026-09-17/28-snow-common-functions-how-to/` | Common SNOW functions |
| `2026-09-24/1-silva-http-snow-pd-sync-workflows/` | OPEN and CLOSE workflow YAML (HTTP to SILVA) |
| `1.sh` | Example API calls (you run) |

## Commands

See `1.sh`. Replace placeholders before running.
