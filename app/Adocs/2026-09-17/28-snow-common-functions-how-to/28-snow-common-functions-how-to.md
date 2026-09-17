# Snow Common Functions How To

```
Need to work an outage in ServiceNow?
  │
  ├─ Create INC → Assign → Comment → Resolve
  ├─ Search INC by number or correlation_id
  └─ From Dynatrace: snow-create / search / comment / resolve
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| Most common SRE functions | Create, assign, comment, search, resolve Incident |
| How humans use them | ServiceNow UI (forms and lists) |
| How your automation uses them | Dynatrace Connector `snow-*` actions → Table API |
| Instance example | `https://silvastg.service-now.com` |

## Summary

ServiceNow “functions” for ops are mostly Incident actions: open a ticket, route it to a group, leave notes, find it later, and resolve it. Your Dynatrace workflows already automate create / comment / search / resolve. Below is what each function means and how to use it both ways.

---

## Investigation

User asked for ServiceNow common functions and how to use them, in the context of Dynatrace Connector INC automation and on-call work.

## Result

Use the tables: human UI steps + matching Dynatrace Connector action + API underneath.

---

## 1) Common functions (SRE set)

| Function | What it means | When you use it |
| --- | --- | --- |
| Create Incident | Open a new INC ticket | Outage starts (or Dynatrace Problem opens) |
| Assign / reassign | Put INC on a group or person | Route to EIP-Support, CCI, etc. |
| Set impact / urgency | Drive priority | Match how bad / how urgent |
| Add comment / work note | Write timeline updates | “Paged PD”, “rollback started” |
| Search / filter | Find INCs | By number, group, correlation_id, state |
| Update state | New → In Progress → … | Reflect real work |
| Resolve | Mark fixed with code + notes | Service restored |
| Close | Finalize after resolve (process-dependent) | Often after confirm no reopen |
| Link related records | Attach Problem/Change/CI | Optional deeper ITSM |
| Attach file | Upload screenshot/log snippet | Evidence (optional) |

---

## 2) How to use in ServiceNow UI (human)

### A) Create Incident

| Step | What to do |
| --- | --- |
| 1 | Open instance → **Incident → Create New** (or type `incident.do`) |
| 2 | Fill short description, description, caller |
| 3 | Set category / subcategory, impact, urgency |
| 4 | Set **Assignment group** |
| 5 | **Submit** / Save → get `INC#######` |

Fake example: short description `[Dynatrace] Failure rate increase on checkout API — EIP`.

### B) Assign

| Step | What to do |
| --- | --- |
| 1 | Open the INC |
| 2 | Set **Assignment group** (and Assigned to if needed) |
| 3 | Save |

### C) Comment / work note

| Step | What to do |
| --- | --- |
| 1 | Open INC |
| 2 | Add **Work notes** (internal) or **Additional comments** (often caller-visible — process depends) |
| 3 | Save |

### D) Search

| Step | What to do |
| --- | --- |
| 1 | **Incident → Open** or global search |
| 2 | Filter by Number, Assignment group, State |
| 3 | Or use query builder: `correlation_id=P-240917001` |

### E) Resolve

| Step | What to do |
| --- | --- |
| 1 | Open INC |
| 2 | Set state to **Resolved** (or use Resolve UI action) |
| 3 | Fill **Resolution code** + **Resolution notes** |
| 4 | Save |

Fake resolution notes: `Resolved automatically: Dynatrace Problem closed (P-240917001)`.

---

## 3) How to use from Dynatrace (your pack)

| SNOW function | Dynatrace action | How you use it |
| --- | --- | --- |
| Create INC | `snow-create-incident` | OPEN workflow after `prepare-payload` |
| Comment | `snow-comment-on-incident` | After INC + PD both OK (cross-link) |
| Search | `snow-search-incidents` | CLOSE workflow by `correlation_id` |
| Resolve | `snow-resolve-incident` | CLOSE after search finds a row |

### Setup once

| Step | What to do |
| --- | --- |
| 1 | Dynatrace **Connections** → ServiceNow → URL + user/password (or OAuth) |
| 2 | Allowlist `silvastg.service-now.com` |
| 3 | Map Connection on every snow task |
| 4 | Put real group/biz `sys_id`s in assignMap |
| 5 | Classic Problem notification **ITSM OFF** |

### Create (OPEN) — what to pass

| Input | How to use | Fake example |
| --- | --- | --- |
| correlationId | Dynatrace Problem id | `P-240917001` |
| shortDescription | Title | `[Dynatrace] … — EIP` |
| description | Details + runbook + L1/L2/L3 | multi-line text |
| impact / urgency | From severity map | `2` / `3` |
| group.id | Assignment group sys_id | `11111111111111111111111111111111` |
| category / subCategory | Classification | `Software` / `Application` |

### Search (CLOSE) — what to pass

| Input | How to use | Fake example |
| --- | --- | --- |
| sysparmQuery | Find the INC | `correlation_id=P-240917001` |
| sysparmLimit | Usually `1` | `1` |
| sysparmFields | Fields you need back | `number,sys_id,correlation_id,state` |

### Resolve (CLOSE) — what to pass

| Input | How to use | Fake example |
| --- | --- | --- |
| number | From search result | `INC0017788` |
| resolutionNotes | Why closed | Problem closed auto note |
| resolutionCode | Required close code | `Solved (Permanently)` |

---

## 4) Same functions via Table API (what Connector wraps)

| Function | Method + path |
| --- | --- |
| Create | `POST /api/now/v2/table/incident` |
| Search | `GET /api/now/v2/table/incident?sysparm_query=...` |
| Comment / resolve (update) | `PUT /api/now/v2/table/incident/{sys_id}` |

You normally **do not** hand-write these in YAML when using Connector — the `snow-*` actions do it.

---

## 5) Other common SNOW functions (know, less used in your pack)

| Function | What it means | How to use (high level) |
| --- | --- | --- |
| Create Change (CHG) | Planned change ticket | Change module / Change API — not in current workflow |
| Create Problem (SNOW) | Root-cause problem record | Different from Dynatrace Problem |
| Catalog Request (REQ/RITM) | Service request | Service Catalog — not outage path |
| CMDB CI lookup | Find configuration item | Link CI on INC (optional field) |
| Knowledge article | Runbook page in SNOW | Link from description instead of only Confluence |
| Get Groups | List assignment groups | Connector action `Get Groups` / table `sys_user_group` |

---

## 6) On-call cheat sheet — which function now?

```
New outage, no ticket yet
  → Create INC (or wait for Dynatrace OPEN workflow)

Wrong team on ticket
  → Assign / reassign

Did something (ack, rollback, waiting)
  → Comment / work note

Need the ticket Dynatrace opened
  → Search correlation_id = Problem id  OR  search short_description

Service restored
  → Resolve (automation may do this on Problem close)

Still getting pages but ticket resolved?
  → Check PagerDuty dedup / Dynatrace Problem still OPEN
```

---

## 7) Common mistakes

| Mistake | What goes wrong |
| --- | --- |
| Create INC manually **and** Connector create | Duplicates |
| Classic ITSM ON + Connector | Duplicates |
| Resolve without correlation_id on create | CLOSE search finds nothing |
| Wrong assignment group sys_id | Ticket lands on wrong team |
| Comment in wrong field (customer-visible vs work note) | Process / privacy issues |
| Resolve in UI while CLOSE workflow also resolves | Usually OK; watch race / already-resolved errors |

---

## Data flow map

```
Human path:
  UI Create → Assign → Comment → Resolve

Automation path (your pack):
  Dynatrace Problem
    → snow-create-incident
    → snow-comment-on-incident
    → (later) snow-search-incidents
    → snow-resolve-incident

Both write the same incident table.
```

## Related files

| Path | Why |
| --- | --- |
| `../27-servicenow-explained/` | What SNOW is |
| `../19-snow-connector-workflow-again/` | Working YAML |
| `../21-workflow-parameter-fake-data/` | Field examples |
| `../23-architecture-all-apis-involved/` | API mapping |
| `28.sh` | Paths |

## Commands

See `28.sh` in this folder.
