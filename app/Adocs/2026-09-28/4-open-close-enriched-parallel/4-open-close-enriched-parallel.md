# Open And Close Enriched Parallel

```
Based on the Sep 24 pair (same task names, same sync keys)

OPEN
  prepare-payload  ← enrichment added here (Dynatrace facts + CMDB + verified group + classification)
     ├─► post-silva-incident-http   (x:0,y:2)  ┐ same time
     └─► trigger-pagerduty          (x:1,y:2)  ┘
  add-cross-links  (new, waits for both)
     PD REST → real PagerDuty link → notes block on INC → INC number as PagerDuty note

CLOSE
  prepare-close-ids  ← duration, cause, service, dashboard added
     ├─► resolve-silva-incident-http (x:0,y:2)  ┐ same time
     └─► resolve-pagerduty           (x:1,y:2)  ┘
  (SILVA task looks up the PagerDuty link itself, so no extra step)

CI retired in CMDB → OPEN skips BOTH posts (no INC, no page)
INC missing at close → soft result, PagerDuty still resolved
```

## Short takeaway

| Question | Answer |
| --- | --- |
| What stayed from Sep 24 | Task names, positions, parallel branches, sync keys, basic auth style, error messages, soft miss on close |
| Where enrichment lives | `prepare-payload` and `prepare-close-ids` (before the split) |
| Are SNOW and PagerDuty still posted at the same time | Yes, both depend only on the prepare task |
| How the PagerDuty link reaches SNOW | OPEN: new `add-cross-links` after both. CLOSE: SILVA task queries PagerDuty REST itself |
| Ticket fields shown | Environment, business service, category, subcategory, priority, impact, urgency, assignment group |
| Notes show | Cause, Dynatrace link, PagerDuty link, which service, which dashboard |
| Files | `1-open-silva-http-and-pagerduty-enriched.workflow.yaml`, `2-close-silva-http-and-pagerduty-enriched.workflow.yaml` |

## Summary

These two files are the Sep 24 OPEN and CLOSE workflows with the enrichment requirements added, not new designs. All lookups (Dynatrace problem details, CMDB, assignment group check, category and priority rules, dashboard) now happen inside the first task, so the SILVA POST and the PagerDuty trigger still fire together. Because the PagerDuty incident link only exists after PagerDuty creates the incident, OPEN gets one small extra task at the end that writes the full notes block into SNOW and puts the INC number into PagerDuty. CLOSE keeps exactly three tasks.

## Investigation

| Source | Used for |
| --- | --- |
| `2026-09-24/.../1-open-silva-http-and-pagerduty.workflow.yaml` | Base OPEN structure |
| `2026-09-24/.../2-close-silva-http-and-pagerduty.workflow.yaml` | Base CLOSE structure |
| Pic 1 requirement | Fields and notes content |
| Pic 2 group list | Verified assignment group (sys_id) |
| INC30339599 form | Mandatory fields, External Ticket Number, Resolution Type |

## Result

Replace the two Sep 24 workflows with these (or import as new and deactivate the old ones). Fill placeholders, confirm field and choice names, test open and close in STG.

---

## 1) What changed vs Sep 24 — OPEN

| Task | Sep 24 | Now |
| --- | --- | --- |
| `prepare-payload` | Title, id, url, host from event; fixed severity map | Plus Problems API, tags, cause (evidence and top error log), dashboard, CMDB CI, verified group, env, business service, offering, category, subcategory, impact and urgency rules |
| `post-silva-incident-http` | POST title, description, impact, urgency, host | POST all classification fields, group sys_id, CI, External Ticket Number; reads back display values incl. priority |
| `trigger-pagerduty` | Summary, severity, problem link | Plus environment, business service, category, group, cause, dashboard, runbook in details; links to Dynatrace, SNOW search, dashboard |
| `add-cross-links` | Not present | **New**: gets PagerDuty link, writes notes block in SNOW, adds INC number note in PagerDuty |
| Retired CI | SILVA skipped INC; PagerDuty still paged | Both posts skipped |

## 2) What changed vs Sep 24 — CLOSE

| Task | Sep 24 | Now |
| --- | --- | --- |
| `prepare-close-ids` | Id, url, one-line close notes | Plus duration, cause, evidence, service, dashboard, runbook; multi-line close notes |
| `resolve-silva-incident-http` | GET by correlation_id, PATCH state 6 | Plus skip if already resolved, closing notes block, Resolution Type, PagerDuty link lookup, state verification, comment-only mode |
| `resolve-pagerduty` | Resolve by dedup_key | Same, with a resolve summary including duration |

---

## 3) Why one extra task in OPEN

| Fact | Consequence |
| --- | --- |
| SNOW and PagerDuty are posted at the same time | Neither knows the other's ID at post time |
| PagerDuty Events API does not return the incident link | Link must be fetched from PagerDuty REST afterwards |
| Requirement: notes must include the PagerDuty link | A task after both posts is needed |

So OPEN posts both together (fast paging, no waiting), then `add-cross-links` finishes the cross-reference. The PagerDuty event itself already carries a SNOW search link (by problem id) so on-call can jump to the ticket immediately.

---

## 4) Notes block written by `add-cross-links`

```
=== Dynatrace alert summary (P-260915195) ===

Ticket classification
  Environment      : Production
  Business service : Policy Administration
  Category         : Capacity
  Subcategory      : Disk space
  Priority         : 4 - Low
  Impact           : 2 - Medium
  Urgency          : 3 - Low
  Assignment group : Dynatrace Support

Cause
  SQL Server DB file space usage above 90% on SQLPRD01
  - DB file space usage 93% (threshold 90%)
  - Log file growth 4 GB in 1 h
  - Top error (8x in 30 min) Could not allocate space for object in database 'PolicyDB' ...

Links
  Dynatrace problem : https://abc12345.apps.dynatrace.com/ui/apps/dynatrace.davis.problems/problem/...
  PagerDuty incident: https://axa-jp.pagerduty.com/incidents/Q2XYZ789ABC

Which service
  Business service  : Policy Administration
  Dynatrace service : MSSQLSERVER (PolicyDB)
  Affected entity   : SQLPRD01 on host sqlprd01.axa.local
  Application       : policy-db

Dashboard to refer to
  https://abc12345.apps.dynatrace.com/ui/apps/dynatrace.dashboards/dashboard/policy-db-sql-health
  Runbook: https://confluence.example.com/runbooks/sql-file-space
```

PagerDuty incident note added at the same time:

```
SILVA INC30339599 (4 - Low, Dynatrace Support): https://silvastg.service-now.com/nav_to.do?uri=incident.do?sys_id=...
```

CLOSE writes a matching `=== Dynatrace alert closed ===` block with outcome and duration.

---

## 5) Placeholders

| Placeholder | Used in | What it is |
| --- | --- | --- |
| `__SNOW_PASSWORD__` | OPEN and CLOSE | Tech_DynatraceJP_WS password (same as Sep 24) |
| `__PD_ROUTING_KEY__` | OPEN and CLOSE | Events API integration key (same as Sep 24) |
| `__PD_API_KEY__` | OPEN and CLOSE | **New**: PagerDuty REST key (read incidents, add notes) |
| `__PD_FROM_EMAIL__` | OPEN | **New**: PagerDuty user email required to add notes |
| Dashboard IDs | Both prepare tasks | Dynatrace dashboard URLs |
| `GROUP_BY_ZONE`, `SERVICE_BY_ZONE`, `DEFAULT` | OPEN prepare | Real SILVA names |

Better practice: move the password and keys to the Dynatrace credential vault (as in the v2 files) once this works.

## 6) Allowlist

| Host | Why |
| --- | --- |
| `silvastg.service-now.com` | SILVA API (same as before) |
| `events.pagerduty.com` | Trigger and resolve (same as before) |
| `api.pagerduty.com` | **New**: incident link and notes |

---

## 7) Common problems

| Symptom | Cause | Fix |
| --- | --- | --- |
| `prepare-payload` fails on group | No candidate group exists | Put a real group in `DEFAULT.group` |
| Notes show NOT SET | Label did not match a choice | Fix mapping labels |
| PagerDuty link "not found yet" | REST key missing or allowlist missing | Add key and `api.pagerduty.com` |
| No INC number in PagerDuty | `__PD_FROM_EMAIL__` wrong or key lacks write | Use a valid PagerDuty user email |
| CLOSE does not find INC | External Ticket Number is another column | Change the search field in CLOSE |
| INC stays In Progress | SILVA requires more close fields | Check `close_code` and Resolution Type labels |

---

## Data flow map

```
OPEN
Dynatrace Problem (CREATED/REOPENED)
  → prepare-payload
       Problems API, tags, logs, dashboard
       SILVA GET cmdb_ci, GET sys_user_group
       classification + sync keys
       ├──────────────► post-silva-incident-http ──POST──► SILVA INC (fields + group sys_id)
       └──────────────► trigger-pagerduty ─────────POST──► PagerDuty (details + links)
  → add-cross-links
       GET api.pagerduty.com/incidents?incident_key → html_url
       PATCH SILVA comments  (classification, cause, DT link, PD link, service, dashboard)
       POST PagerDuty note   (INC number + link)

CLOSE
Dynatrace Problem (CLOSED)
  → prepare-close-ids (duration, cause, dashboard, sync keys)
       ├──► resolve-silva-incident-http
       │       GET by correlation_id (missing → soft)
       │       GET PagerDuty link
       │       PATCH state 6 + close_code + close_notes + resolution type + closing block
       └──► resolve-pagerduty ──POST resolve──► PagerDuty
```

## Related files

| File | Role |
| --- | --- |
| `1-open-silva-http-and-pagerduty-enriched.workflow.yaml` | OPEN (enriched, parallel) |
| `2-close-silva-http-and-pagerduty-enriched.workflow.yaml` | CLOSE (enriched, parallel) |
| `2026-09-24/1-silva-http-snow-pd-sync-workflows/` | Original pair this is based on |
| `2026-09-28/2-silva-ticket-fields-and-notes-v2/` | Sequential v2 (reference for requirements) |
| `4.sh` | Checks (you run) |

## Commands

See `4.sh`. STG only.
