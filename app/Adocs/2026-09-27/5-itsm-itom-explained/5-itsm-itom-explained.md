# ITSM And ITOM Explained

```
Which side is this?
  "A person or team must act, track, approve"        → ITSM (process, tickets)
  "A machine signal, inventory, or automation"       → ITOM (operations data)

Alert arrives from Dynatrace — where should it go?
  Want dedup, correlation, alert noise control in SNOW? → ITOM Event Management (em_event → em_alert → Incident)
  Just want a ticket per problem?                        → ITSM Incident directly (your SILVA path)
  Doing both from Dynatrace classic integration?         → duplicate tickets → pick ONE

Ticket has no server / service linked?
  → CMDB (ITOM) is missing or stale → fix Discovery / CI data
```

## Short takeaway

| Question | Answer |
| --- | --- |
| ITSM in one line | How IT **serves people**: tickets, approvals, process |
| ITOM in one line | How IT **runs machines**: monitoring events, inventory, automation |
| Analogy | ITSM is the hospital front desk and patient records; ITOM is the monitors, sensors, and equipment list |
| Where they meet | ITOM detects and describes; ITSM records and manages the human work |
| Shared heart | CMDB: ITOM fills it, ITSM uses it on every ticket |
| Your setup | Dynatrace (your ITOM tool) → SILVA → ITSM Incident; SILVA uses CMDB (ITOM data) |

## Summary

ITSM is the people-and-process side: someone reports or detects an issue, a ticket is created, the right team works it, and everything is recorded. ITOM is the machine side: find every server and app (Discovery), keep the inventory (CMDB), collect events from monitoring tools, cut noise, and automate fixes. In ServiceNow both run on the same platform, and the CMDB links them. In your setup, Dynatrace does most of the ITOM monitoring, and ServiceNow is used mainly for ITSM plus the CMDB check.

## Investigation

Built on `2026-09-27/1-servicenow-explained/` and `4-snow-all-functions/`, and the SILVA HTTP path from `2026-09-24/1-silva-http-snow-pd-sync-workflows/` (CMDB retired-host skip, no native connector, keep classic ITSM notification off).

## Result

Think "ITOM sees, ITSM acts". Send Dynatrace alerts to one entry point only (ITSM Incident via SILVA today), and keep the CMDB healthy because both sides depend on it.

---

## 1) Plain English

| Term | Stands for | What it means | Why you care |
| --- | --- | --- | --- |
| ITSM | IT Service Management | Processes for delivering IT as a service to people | Every incident, change, and request you touch |
| ITOM | IT Operations Management | Tools for seeing and controlling the infrastructure | Alerts, host inventory, automation |
| ITIL | IT Infrastructure Library | A best-practice guide that ITSM processes follow | Words like "incident", "problem", "change" come from here |
| CMDB | Configuration Management Database | Inventory of servers, apps, and their links | Glue between ITSM and ITOM |

**Analogy (hospital):**

| Hospital | IT |
| --- | --- |
| Heart monitors beeping | ITOM Event Management (Dynatrace signals) |
| Equipment and room list | CMDB |
| Nurse walking the floor to find new equipment | Discovery |
| Patient record and treatment log | ITSM Incident |
| Surgery approval board | ITSM Change / CAB |
| Research into why patients keep getting sick | ITSM Problem |

---

## 2) ITSM in detail

### Main processes

| Process | Question it answers | Record | Example |
| --- | --- | --- | --- |
| Incident Management | Something is broken; how do we restore it fast? | `incident` (INC) | Checkout latency high |
| Major Incident | This is a big outage; who leads and communicates? | Incident flagged major | P1 bridge call |
| Problem Management | Why does it keep happening? | `problem` (PRB) | Connection pool too small |
| Change Management | Is this production change safe and approved? | `change_request` (CHG) | Deploy v2.3 |
| Request Fulfilment | Can I have something? | `sc_request`, `sc_req_item` (RITM) | New AWS account |
| Knowledge Management | How do we fix this next time? | `kb_knowledge` (KB) | Runbook for restart |
| Service Level Management | Are we fast enough? | `task_sla` | P1 fixed in 4 hours |

### Change types

| Type | What it means | Example |
| --- | --- | --- |
| Standard | Pre-approved, low risk, repeatable | Routine patch with a template |
| Normal | Needs review and approval (maybe CAB) | New release |
| Emergency | Urgent fix during an incident; approve fast, review after | Hotfix for a P1 |

### ITSM lifecycle for one outage

```
Incident opened (INC)  → work → Resolved
      │ repeated or big?
      ▼
Problem (PRB) → root cause found → Known Error + KB article
      │ fix needs code or infra change
      ▼
Change (CHG) → approved → deployed → closed
      │
      ▼
Problem closed; incidents stop
```

### Who uses ITSM

| Role | What they do |
| --- | --- |
| End user | Raises requests and incidents in the portal |
| Service desk | First line: log, triage, route |
| Resolver group (you, SRE) | Fix incidents, own problems |
| Change manager | Approves and schedules changes |
| Problem manager | Drives root cause work |
| Management / audit | Reads reports and SLA results |

### ITSM metrics

| Metric | What it means |
| --- | --- |
| MTTA (Mean Time To Acknowledge) | How long until someone picks it up |
| MTTR (Mean Time To Resolve) | How long until it is fixed |
| SLA breach rate | Percentage of tickets that missed the time target |
| Change success rate | Percentage of changes with no incident caused |
| Reopen rate | Percentage of tickets that came back |
| Backlog | Open tickets waiting |

---

## 3) ITOM in detail

### Main capabilities

| Capability | Question it answers | Main tables | Example |
| --- | --- | --- | --- |
| Discovery | What do we actually have? | `cmdb_ci_*`, `discovery_status` | Finds 500 Linux servers |
| CMDB | What is it, who owns it, what depends on it? | `cmdb_ci`, `cmdb_rel_ci` | `host-app-01` runs Checkout |
| Service Mapping | Which pieces make up a business service? | `cmdb_ci_service`, service maps | Checkout = LB + 3 apps + DB |
| Event Management | Which monitoring signals matter? | `em_event`, `em_alert` | 200 events → 1 alert |
| AIOps / Alert grouping | Which alerts are the same issue? | `em_alert`, groups | CPU + latency + errors grouped |
| Health Log / Metric Intelligence | Is anything abnormal? | anomaly tables | Log error spike |
| Orchestration / Automation | Can we fix it automatically? | Flow Designer, IntegrationHub | Restart service |
| Cloud Management | What is in AWS, Azure, GCP? | cloud CI tables | EC2, EKS in CMDB |
| MID Server | How does SNOW reach private networks? | `ecc_agent` | Discovery behind firewall |

### Event Management pipeline

```
Monitoring tool (Dynatrace, Splunk, CloudWatch)
  → em_event          raw event (source, node, type, severity, message_key)
  → Event rules       filter, transform, set CI, drop noise
  → em_alert          one alert per message_key (dedup)
  → Alert correlation group related alerts, find likely root cause CI
  → Alert action      create or update Incident (ITSM), run automation
  → Event "clear"     severity 0 closes alert → can resolve Incident
```

### Key em_event fields

| Field | What it means | Example |
| --- | --- | --- |
| `source` | Tool that sent it | `Dynatrace` |
| `node` | Host or CI name | `host-app-01` |
| `type` | Kind of problem | `CPU` |
| `resource` | Sub-part | `/var` disk |
| `severity` | 1 Critical to 5 Info, 0 Clear | `1` |
| `message_key` | Dedup key; same key updates same alert | `P-12345` |
| `description` | Text | Problem details |
| `additional_info` | JSON extra data | Problem URL |

### CI status that matters to you

| Field | Values | Effect |
| --- | --- | --- |
| `install_status` | Installed, Retired, In maintenance | Retired → SILVA skips the ticket |
| `operational_status` | Operational, Non-operational | Down CIs flag impact |
| `support_group` | Owning team | Auto-assignment of incidents |

### Who uses ITOM

| Role | What they do |
| --- | --- |
| SRE / operations | Tune event rules, check alerts, automation |
| CMDB owner | Keeps inventory accurate |
| Platform / infra team | Runs Discovery and MID Servers |
| Monitoring team | Connects tools (Dynatrace, Splunk) |

### ITOM metrics

| Metric | What it means |
| --- | --- |
| Event-to-alert ratio | How much noise was removed |
| Alert-to-incident ratio | How many alerts needed a human |
| CMDB completeness | Percentage of CIs with owner, class, status |
| CMDB freshness | Percentage of CIs discovered recently |
| Auto-remediation rate | Percentage fixed without a human |

---

## 4) ITSM vs ITOM side by side

| Topic | ITSM | ITOM |
| --- | --- | --- |
| Focus | People and process | Machines and data |
| Starts from | A person or an alert needing action | A signal or a scan |
| Main records | Incident, Problem, Change, Request | Event, Alert, CI, service map |
| Main question | Who fixes it and by when? | What is happening and where? |
| Typical user | Service desk, resolver teams, managers | SRE, operations, CMDB owners |
| Success looks like | Fast, well-recorded fixes | Less noise, accurate inventory, automation |
| Framework | ITIL processes | Monitoring and automation practice |

---

## 5) How they connect

```
          ITOM (sees)                                   ITSM (acts)
 ┌──────────────────────────────┐              ┌──────────────────────────────┐
 │ Discovery → CMDB ◄───────────┼── used by ───┤ Incident / Change / Problem  │
 │ Service Mapping              │              │ (cmdb_ci field on ticket)    │
 │ Event Mgmt: em_event→em_alert├── creates ──►│ Incident                     │
 │ Automation                   │◄── triggers ─┤ Change approved → run job    │
 └──────────────────────────────┘              └──────────────────────────────┘
```

| Link | What happens |
| --- | --- |
| CMDB on every ticket | Incident and Change point at a CI, so you see impact and owner |
| Alert creates Incident | ITOM alert rule opens the ITSM ticket |
| Alert clears | Can auto-resolve the Incident |
| Change on a CI | Event rules can suppress alerts during a change window |
| Incident trend | Feeds Problem, which may lead to new monitoring rules |

---

## 6) Your setup

| Piece | Side | Tool |
| --- | --- | --- |
| Monitoring and problem detection | ITOM role | **Dynatrace** (not SNOW) |
| Paging | Response | **PagerDuty** |
| Gatekeeper | Integration | **SILVA** |
| Inventory check | ITOM data | **SNOW CMDB** |
| Ticket record | ITSM | **SNOW Incident** |

```
Dynatrace (ITOM job: detect)
  → HTTP → SILVA
       → CMDB lookup (ITOM data)
            retired → skip
            active  → Incident (ITSM)
  → PagerDuty page (response)
```

### Dynatrace classic ServiceNow integration toggles

| Toggle | What it does | Your choice |
| --- | --- | --- |
| ITSM | Creates Incidents directly | **Off** (SILVA workflow creates them; avoid duplicates) |
| ITOM | Sends events to `em_event` | Off unless the SNOW team wants Event Management |
| CMDB sync | Pushes Dynatrace entities into CMDB | Only if CMDB owners agree |

### Two valid designs

| Design | Flow | When it fits |
| --- | --- | --- |
| Direct ITSM (today) | Dynatrace → SILVA → Incident | Dynatrace already dedups; SNOW team wants simple tickets |
| Through ITOM | Dynatrace → `em_event` → alert → Incident | SNOW team wants all tools (Splunk, CloudWatch, Dynatrace) correlated in one place |

---

## 7) Common mistakes

| Mistake | What happens | Fix |
| --- | --- | --- |
| Sending to ITSM and ITOM at once | Two incidents per problem | Pick one entry path |
| CMDB not maintained | Tickets without CI, wrong team, skipped alerts | Discovery plus owners per CI class |
| No `message_key` on events | Every event becomes a new alert | Use problem id as key |
| No clear event | Alerts and incidents stay open | Send severity 0 or resolve call on close |
| Treating ITOM as "just monitoring" | CMDB and automation ignored | Plan inventory and remediation too |
| Treating ITSM as "just tickets" | No Problem or Change follow-up | Link incidents to problems and changes |
| Alerting during planned changes | Noise and false P1s | Maintenance windows tied to Change |

---

## Data flow map

```
Servers / apps / cloud
   │  scanned by Discovery (ITOM)        monitored by Dynatrace
   ▼                                        │
 CMDB (CIs, owners, status) ◄───────────────┤
   ▲                                        ▼
   │                                SILVA (HTTP)  ── or ──► em_event → em_alert (ITOM)
   │ lookup                                 │                         │
   └────────────────────────────────────────┤                         │
                                            ▼                         ▼
                                    Incident (ITSM) ◄─────────────────┘
                                            │
                          Problem (ITSM) ◄──┤ repeated
                                            ▼
                          Change (ITSM) → deploy fix → alerts stop
```

## Related files

| File | Role |
| --- | --- |
| `2026-09-27/1-servicenow-explained/` | SNOW overview |
| `2026-09-27/3-snow-apis-in-detail/` | Table API |
| `2026-09-27/4-snow-all-functions/` | Full module list |
| `2026-09-24/1-silva-http-snow-pd-sync-workflows/` | Your ITSM path |
| `5.sh` | Read ITSM and ITOM tables (you run) |

## Commands

See `5.sh`.
