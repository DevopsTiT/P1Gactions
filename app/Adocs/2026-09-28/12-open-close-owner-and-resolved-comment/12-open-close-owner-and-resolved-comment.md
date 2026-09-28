# Open Close Owner And Resolved Comment

```
Problem ACTIVE → OPEN
   Short description = [DYNATRACE JAPAN][<host>] - <problem title>
   Assignment group  = Ops_Middleware_Monitoring_AXAJP
   Assigned to       = Shuge KUI
   blank in notFilled?
     assignedTo blank      → name not unique, or not a member of the group
     assignmentGroup blank → group name typo
Problem CLOSED → CLOSE
   state 6 Resolved + close_code + close_notes
   Additional comments (customer visible) = "Resolved"
   Work notes (internal)                  = cause, duration, links, service
   HTTP 403 or resolve blocked?
     → API user needs write on incident; Assigned to must be set
```

## Short takeaway

| Question | Answer |
|---|---|
| Title format | `[DYNATRACE JAPAN][<host>] - <problem title>`, the same as the Dynatrace example tickets. |
| Assignment group | Ops_Middleware_Monitoring_AXAJP |
| Assigned to | Shuge KUI |
| Comment on resolve | "Resolved" in Additional comments. The detailed block moves to Work notes. |
| Base | Seq 11 YAMLs, with the password and routing key already inside. |

## Summary

New tickets now carry the Dynatrace-style title and go straight to Ops_Middleware_Monitoring_AXAJP, assigned to Shuge KUI. When the problem closes, the ticket is resolved with the customer comment "Resolved".

## OPEN changes

| Setting or field | Before (seq 11) | Now (seq 12) |
|---|---|---|
| `FIXED_SHORT_DESCRIPTION` | "Testing-Dynatrace-Pagerduty" | "" (uses the Dynatrace format) |
| Short description sent | Testing-Dynatrace-Pagerduty | [DYNATRACE JAPAN][<host>] - <problem title> |
| PagerDuty summary | Testing-Dynatrace-Pagerduty | Same Dynatrace-style title |
| `TEST_ASSIGNMENT_GROUP` | testing 3122 | Ops_Middleware_Monitoring_AXAJP |
| `ASSIGNED_TO` (new) | Not sent | Shuge KUI |
| POST body | No assigned_to | `assigned_to` added when the setting is not empty |
| `stored` / `notFilled` | No assignee check | Reports `assignedTo` too |
| Customer notes and PagerDuty details | Group only | Group and "Assigned to" |

```javascript
const TEST_ASSIGNMENT_GROUP = "Ops_Middleware_Monitoring_AXAJP";
// Display name must match exactly one active member of the assignment group
const ASSIGNED_TO = "Shuge KUI";
// "" → "[DYNATRACE JAPAN][<host>] - <problem title>"; any text here replaces it for every ticket
const FIXED_SHORT_DESCRIPTION = "";
```

```javascript
if (p.assignedTo) body.assigned_to = p.assignedTo;
```

## CLOSE changes

| Field | Before (seq 11) | Now (seq 12) |
|---|---|---|
| `comments` (Additional comments, customer visible) | Long closing block | "Resolved" |
| `work_notes` (internal) | Not sent | The long closing block (cause, duration, links, service) |
| `close_notes` | Cause and duration | Unchanged |
| Task result | number, sys_id | Also returns the comment sent |

```javascript
const RESOLVE_COMMENT = "Resolved";
```

```javascript
const patchBody = {
  state: "6",
  close_code: "Solved (Permanently)",
  close_notes: p.closeNotes,
  comments: p.resolveComment,
  work_notes: p.customerNotes
};
```

## Things to know

| Point | Why it matters |
|---|---|
| "Shuge KUI" must be unique | SNOW matches Assigned to by display name. If two users share it, or the name differs, the field stays blank and `notFilled` lists it. |
| Shuge KUI must be in Ops_Middleware_Monitoring_AXAJP | Many SNOW setups clear Assigned to when the person is not in the group. |
| Every alert goes to one person | Fine for testing. Before go-live, set `ASSIGNED_TO = ""` and let the group pick it up. |
| Tickets opened before seq 12 | They may have no Assigned to. If SILVA requires it for Resolved, the CLOSE PATCH can fail with an error. Assign them by hand. |
| Password inside the files | Do not commit or push the `app/Adocs` copy. That copy has placeholders only. |

## Data flow map

```
Problem ACTIVE
   │
prepare-payload
   title   → [DYNATRACE JAPAN][host] - problem title
   group   → Ops_Middleware_Monitoring_AXAJP
   person  → Shuge KUI
   ├──► post-silva-incident-http → INC (assigned_to = Shuge KUI)
   └──► trigger-pagerduty        → PD incident (same title)

Problem CLOSED
   │
prepare-close-ids → resolveComment "Resolved", closeNotes, customerNotes
   ├──► resolve-silva-incident-http → PATCH state 6
   │        comments   = "Resolved"   (customer sees it)
   │        work_notes = details      (internal)
   └──► resolve-pagerduty → PD resolved
```

## Related files

| File | Purpose |
|---|---|
| `1-open-silva-http-and-pagerduty.workflow.yaml` | OPEN: Dynatrace title, group, assignee |
| `2-close-silva-http-and-pagerduty.workflow.yaml` | CLOSE: "Resolved" comment |
| `12.sh` | Diffs against seq 11, and user and group checks |

Commands: see `12.sh` in this folder.
