# ServiceNow Explained

```
What is ServiceNow for an SRE?
  │
  ├─ ITSM: Incident tickets (INC) — track and hand off work
  ├─ ITOM: Events / ops noise — “something happened” signals
  └─ In YOUR pack: Dynatrace Connector creates/resolves INC
       (classic notification can still send ITOM events)
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What it is | A platform companies use to run IT work — tickets, changes, CMDB, workflows |
| What you use most as SRE | **Incident (INC)** records: who owns the outage, status, notes, audit trail |
| Why Dynatrace talks to it | Monitoring finds the Problem; ServiceNow is where the **official ticket** lives |
| Your instance (example) | `https://silvastg.service-now.com` |

## Summary

ServiceNow is the ticket desk. Dynatrace says “checkout is broken.” ServiceNow stores `INC0017788`, assigns `EIP-Support`, and keeps the timeline. PagerDuty wakes people; Splunk holds logs; ServiceNow holds the process record.

---

## Investigation

User asked to explain ServiceNow in the context of today’s Dynatrace Connector + PagerDuty architecture.

## Result

Learn INC / ITSM / ITOM / sys_id / assignment group / correlation_id first. Then map them to your `snow-create-incident` / search / resolve tasks.

---

## 1) What ServiceNow is (plain English)

| Idea | What it means | Why you care |
| --- | --- | --- |
| ServiceNow | Cloud (or on-prem) IT platform with many modules | One system of record for ops work |
| Record | A row in a table (like a ticket) | Almost everything is a table row with a `sys_id` |
| Table | Named storage (e.g. `incident`) | APIs and Connector talk to tables |
| Instance | Your company’s SNOW URL | e.g. `silvastg.service-now.com` |

Analogy: Dynatrace is the smoke detector. ServiceNow is the fire department’s case file. PagerDuty is the alarm that wakes the firefighter.

---

## 2) ITSM vs ITOM (do not mix these up)

| Term | What it means | In your design |
| --- | --- | --- |
| ITSM | IT Service Management — Incidents, Problems, Changes, Requests | Connector creates **INC** tickets |
| ITOM | IT Operations Management — events, discovery, health signals | Classic notification can send **events** (`em_event`) with ITSM OFF |
| Incident (INC) | “Something is broken; we need to restore service” | Your main ticket type |
| Problem (SNOW) | Recurring root-cause record (different from Dynatrace Problem) | Optional later; not your current workflow |
| Change (CHG) | Planned work / deploy approval | Not created by your current pack |

| Rule for your pack | What it means |
| --- | --- |
| Classic **ITSM OFF** | Notification does not also create INC |
| Connector creates INC | Workflow `snow-create-incident` owns the ticket |
| Classic **ITOM** optional ON | You can still get SNOW events without a second INC |

---

## 3) Anatomy of an Incident ticket

| Field | What it means | Fake example |
| --- | --- | --- |
| `number` | Human ticket id | `INC0017788` |
| `sys_id` | Internal 32-char id | `abcdef0123456789abcdef0123456789` |
| `short_description` | One-line title | `[Dynatrace] Failure rate increase on checkout API — EIP` |
| `description` | Long details | Problem URL, L1/L2/L3, runbook |
| `state` | New / In Progress / Resolved / Closed … | Changes as people work it |
| `impact` / `urgency` | Drive priority | Your workflow maps Dynatrace severity → these |
| `assignment_group` | Which team owns it | `EIP-Support` |
| `caller` | Who reported it | `Dynatrace Workflow` |
| `category` / `subcategory` | Classification | `Software` / `Application` |
| `correlation_id` | External id to find this ticket later | Problem id `P-240917001` |
| Work notes / comments | Timeline updates | PD dedup_key cross-link |

---

## 4) Important SNOW words for your workflows

| Term | What it means | Why you care |
| --- | --- | --- |
| `sys_id` | Unique id of any record | Groups and biz services in assignMap use sys_ids |
| Assignment group | Team queue for the INC | Routes work to EIP vs CCI vs Ops |
| Business service | CI / service the ticket is about | Shows “what business thing is hurt” |
| Connection (Dynatrace) | Stored SNOW URL + credentials | Connector uses it; password not in YAML |
| Table API | REST under `/api/now/v2/table/...` | What Connector calls for you |
| Resolve | Mark INC solved with notes + close code | CLOSE workflow does this when Problem closes |

---

## 5) How Dynatrace uses ServiceNow in YOUR pack

```
Problem OPEN
  prepare-payload (app tag → group, impact, text)
  → snow-create-incident
       POST /api/now/v2/table/incident
  → (parallel) PagerDuty
  → snow-comment-on-incident
       PUT  /api/now/v2/table/incident/{sys_id}

Problem CLOSE
  → snow-search-incidents
       GET  /api/now/v2/table/incident?sysparm_query=correlation_id=...
  → snow-resolve-incident
       PUT  /api/now/v2/table/incident/{sys_id}
```

| Dynatrace action | ServiceNow effect |
| --- | --- |
| `snow-create-incident` | New INC row |
| `snow-comment-on-incident` | Work note with PD key + Problem URL |
| `snow-search-incidents` | Find INC by `correlation_id` |
| `snow-resolve-incident` | Set resolved + resolution notes |

---

## 6) Two ways Dynatrace can talk to ServiceNow

| Way | What it is | Best for |
| --- | --- | --- |
| **Connector + Workflow** (your pack) | Rich INC fields, search, resolve, PD cross-link | Controlled automation |
| **Classic Problem notification** | Settings push on Problem match | Simple ITOM events and/or basic ITSM |

They are different objects. You cannot set `connectionId = servicenowstg`.

---

## 7) Mini life of one ticket (same EIP story)

| Step | ServiceNow view |
| --- | --- |
| Create | `INC0017788` appears, assigned to `EIP-Support` |
| Comment | Work note: PD dedup + Dynatrace Problem link |
| Human work | State moves In Progress; notes added |
| Dynatrace recovers | CLOSE workflow finds INC by correlation_id |
| Resolve | Resolution code e.g. `Solved (Permanently)` + auto notes |

---

## 8) What beginners should remember

| Do | Do not |
| --- | --- |
| Treat INC as the audit trail | Expect ServiceNow to detect outages by itself |
| Keep correlation_id stable | Create INC from both notification ITSM and Connector |
| Put real group/biz sys_ids in assignMap | Put SNOW password in workflow YAML |
| Allowlist `silvastg.service-now.com` | Confuse SNOW “Problem” with Dynatrace “Problem” |

---

## Data flow map

```
Dynatrace Problem
        │
        ▼
ServiceNow incident table
  number, assignment_group, impact/urgency,
  correlation_id, description, work notes
        │
        ├── humans work the queue
        └── CLOSE: search → resolve
```

## Related files

| Path | Why |
| --- | --- |
| `../20-dynatrace-snow-pd-architecture/` | Full architecture |
| `../14-snow-connector-vs-problem-notification/` | Connector vs classic |
| `../23-architecture-all-apis-involved/` | Table API paths |
| `../21-workflow-parameter-fake-data/` | Fields + fake values |
| `27.sh` | Paths |

## Commands

See `27.sh` in this folder.
