# SILVA Close Workflow V2

```
Dynatrace problem CLOSED
  → prepare-close          problem id, duration, cause, service, dashboard
  ├─► resolve-pagerduty    Events API resolve (dedup_key dt-problem-<id>)   ← always runs
  │     → get-pagerduty-link   REST → html_url + status
  └─► find-silva-incident  GET incident by correlation_id
        not found          → soft stop ("SILVA may have skipped it")
  → resolve-silva-incident
        already Resolved / Closed / Canceled → skip
        RESOLVE_MODE = auto         → state 6, close code, close notes, resolution type, closing note
        RESOLVE_MODE = comment-only → closing note only, team resolves by hand
        state did not change        → fail loudly (SILVA rule wants more close fields)
```

## Short takeaway

| Question | Answer |
| --- | --- |
| Pairs with | OPEN v2 `2026-09-28/2-silva-ticket-fields-and-notes-v2/` |
| Finds the INC by | `correlation_id` (External Ticket Number) = problem id |
| Resolves PagerDuty by | `dedup_key = dt-problem-<problem id>` |
| Sets on the INC | State Resolved, close code, close notes, resolution type |
| Closing note lists | Classification, duration, cause, Dynatrace link, PagerDuty link, service, dashboard |
| Missing INC | Not an error (SILVA may skip retired CIs) |
| Safe option | `RESOLVE_MODE = 'comment-only'` if your team must resolve by hand |
| Workflow | `3-silva-close-v2.workflow.yaml` |

## Summary

When Dynatrace closes the problem, this workflow resolves PagerDuty first (it never depends on SNOW), then finds the SILVA ticket by the same problem id. If the ticket is still open, it resolves it with a close code and clear close notes, and adds a closing block in the same notes field as OPEN v2: the classification at close, how long the problem lasted, the cause, links to Dynatrace and PagerDuty, the service, and the dashboard to confirm recovery. It checks that the state really changed, because SILVA rules can refuse a resolve if required close fields are missing.

## Investigation

Built from the Sep 24 CLOSE workflow (GET by correlation_id, soft miss, PATCH state 6) and aligned with OPEN v2: same keys, same notes field, same dashboard logic, PagerDuty REST link. The SILVA form (INC30339599) shows a **Resolution Type** field, so the resolve body includes it (column name to confirm).

## Result

Import `3-silva-close-v2.workflow.yaml` next to OPEN v2, fill the same credentials and `__PD_SUBDOMAIN__`, confirm `close_code` and Resolution Type labels, choose `RESOLVE_MODE`, and test by closing a problem in STG.

---

## 1) Tasks

| Task | What it does | Why |
| --- | --- | --- |
| `prepare-close` | Reads the problem: id, start and end, duration, cause evidence, service, dashboard | Content for close notes |
| `resolve-pagerduty` | Events API `event_action: resolve` with the dedup key | Stops paging even if SNOW has no ticket |
| `get-pagerduty-link` | REST lookup by incident key, any status | Link and status for the note |
| `find-silva-incident` | GET incident by `correlation_id`, with display values of the classification fields | Know state and show fields at close |
| `resolve-silva-incident` | PATCH resolve fields and closing note; verify state | Clean, auditable close |

Tasks `resolve-pagerduty` and `find-silva-incident` run in parallel. `resolve-silva-incident` waits for both branches and runs even if the PagerDuty link lookup failed (`get-pagerduty-link: ANY`).

---

## 2) What the resolve PATCH sends

```json
{
  "state": "6",
  "close_code": "Solved (Permanently)",
  "close_notes": "Dynatrace problem P-260915195 closed automatically at 2026-09-28T03:57:40.000Z.\nDuration: 1 h 42 min ...\nCause: SQL Server DB file space usage above 90% on SQLPRD01.\n...",
  "u_resolution_type": "Automatic",
  "comments": "=== Dynatrace alert closed (P-260915195) === ..."
}
```

URL:

```
PATCH https://silvastg.service-now.com/api/now/v2/table/incident/<sys_id>?sysparm_input_display_value=true
```

| Field | Value | Confirm |
| --- | --- | --- |
| `state` | `6` (Resolved) | Standard |
| `close_code` | Solved (Permanently) | SILVA choice list may differ |
| `close_notes` | Duration, cause, evidence | Usually mandatory to resolve |
| `u_resolution_type` | Automatic | Column name and label (form shows "Resolution Type") |
| `comments` | Closing block | Same `NOTES_FIELD` as OPEN v2 |

---

## 3) Closing note example

See `3-silva-close-v2-sample-note.txt`.

```
=== Dynatrace alert closed (P-260915195) ===

Ticket classification at close
  Environment      : Production
  Business service : Policy Administration
  Category         : Capacity
  Subcategory      : Disk space
  Priority         : 4 - Low
  Impact           : 2 - Medium
  Assignment group : Dynatrace Support

Outcome
  Status   : Resolved automatically
  Duration : 1 h 42 min
  Cause    : SQL Server DB file space usage above 90% on SQLPRD01

Links
  Dynatrace problem : https://abc12345.apps.dynatrace.com/ui/apps/dynatrace.davis.problems/problem/-1234567890_1759025740000V2
  PagerDuty incident: https://axa-jp.pagerduty.com/incidents/Q2XYZ789ABC (resolved)

Which service
  Business service  : Policy Administration
  Dynatrace service : MSSQLSERVER (PolicyDB)
  Affected entity   : SQLPRD01 on host sqlprd01.axa.local

Dashboard to confirm recovery
  https://abc12345.apps.dynatrace.com/ui/apps/dynatrace.dashboards/dashboard/policy-db-sql-health
  Runbook: https://confluence.example.com/runbooks/sql-file-space
```

Close notes (the resolution field):

```
Dynatrace problem P-260915195 closed automatically at 2026-09-28T03:57:40.000Z.
Duration: 1 h 42 min (2026-09-28T02:15:40.000Z to 2026-09-28T03:57:40.000Z).
Cause: SQL Server DB file space usage above 90% on SQLPRD01.
- DB file space usage 93% (threshold 90%)
- Log file growth 4 GB in 1 h
Recovery confirmed by Dynatrace: the problem condition is no longer detected.
If the underlying cause needs a permanent fix, raise a Problem record.
```

---

## 4) Settings you can change

| Setting | Values | Effect |
| --- | --- | --- |
| `RESOLVE_MODE` | `auto` | Workflow sets Resolved |
| `RESOLVE_MODE` | `comment-only` | Only adds the note; team resolves |
| `NOTES_FIELD` | `comments` | Customer visible (matches OPEN v2 default) |
| `NOTES_FIELD` | `work_notes` | Internal only |
| `FIND_FIELD` | `correlation_id` | Change if External Ticket Number is another column |
| `VALUE.closeCode` | Solved (Permanently) | Use a SILVA close code label |
| `VALUE.resolutionType` | Automatic | Use a SILVA resolution type label |

### When to use comment-only

| Situation | Choose |
| --- | --- |
| Alert-only tickets, nobody touched them | `auto` |
| Team policy: humans must resolve P1 and P2 | `comment-only` |
| Flapping problems close and reopen often | `comment-only` |
| Audit requires human confirmation | `comment-only` |

---

## 5) Edge cases

| Case | What happens |
| --- | --- |
| SILVA skipped the INC (retired CI) | `find-silva-incident` returns found false; PagerDuty still resolved |
| INC already resolved by a person | Skipped, no duplicate note |
| INC canceled | Skipped |
| SILVA rule blocks the resolve | Task fails with "did not move to Resolved"; check required close fields |
| PagerDuty incident not found | Note uses the fallback list URL |
| Problem reopens later | OPEN v2 creates a new INC (REOPENED trigger). If you prefer to reopen the old one, change OPEN to search resolved INCs first |

---

## 6) Common problems

| Symptom | Cause | Fix |
| --- | --- | --- |
| INC not found but it exists | External Ticket Number is not `correlation_id` | Change `FIND_FIELD` |
| 403 on PATCH | User cannot resolve incidents | Ask SNOW admin for role |
| State stays In Progress | Missing mandatory close fields or wrong close code label | Check `sys_choice` for `close_code` and Resolution Type |
| PagerDuty still open | Wrong routing key or dedup key differs from OPEN | Use same key format |
| Note shows NOT SET | That field was empty on the ticket | Fix OPEN mapping |

---

## Data flow map

```
Dynatrace Problem CLOSED
  → prepare-close ── id, duration, cause, service, dashboard
       │
       ├─► resolve-pagerduty ──POST enqueue resolve──► PagerDuty
       │      → get-pagerduty-link ──GET /incidents?incident_key──► html_url
       │
       └─► find-silva-incident ──GET incident?correlation_id──► SILVA
              not found → stop (soft)
       │
       ▼
  resolve-silva-incident
       skip if state 6 / 7 / 8
       PATCH state 6 + close_code + close_notes + resolution type + comments block
       verify state == 6
```

## Related files

| File | Role |
| --- | --- |
| `3-silva-close-v2.workflow.yaml` | CLOSE v2 to import |
| `3-silva-close-v2-sample-note.txt` | Example closing note and close notes |
| `2026-09-28/2-silva-ticket-fields-and-notes-v2/` | OPEN v2 (pair) |
| `2026-09-24/1-silva-http-snow-pd-sync-workflows/2-close-silva-http-and-pagerduty.workflow.yaml` | Older CLOSE (v1) |
| `3.sh` | Checks (you run) |

## Commands

See `3.sh`. STG only.
