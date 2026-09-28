# SILVA Ticket Fields And Notes V2

```
Requirement (pic 1)
  Ticket fields must clearly show → env, business service, category, subcategory, priority, impact, assignment group
  Customer notes must list         → cause, Dynatrace link, PagerDuty link, which service, which dashboard
Sample data (pic 2)
  Assignment group = one of 19,609 real sys_user_group rows → must match exactly or SNOW drops it

Workflow v2
  enrich-problem            facts, cause evidence, top error, dashboard (tag → app map → zone map)
  cmdb-lookup               CI, support group, business service   (retired → skip)
  resolve-assignment-group  CI group → snow-group tag → zone map → "Dynatrace Support"
                            each checked in sys_user_group (active) → sys_id
  build-and-post-silva      env, business service, offering, category, subcategory, impact, urgency, group, CI
  trigger-pagerduty         Events API (dedup_key dt-problem-<id>)
  get-pagerduty-link        PD REST API → html_url (retry 10 s × 5)
  write-ticket-notes        read back saved values (incl. calculated priority) → one notes block

Field shows "NOT SET" in the note?
  → label did not match a choice or record → fix mapping (seq 1 of 2026-09-28, 1.sh)
PD link is the fallback list URL?
  → REST key missing, api.pagerduty.com not allowlisted, or PD slower than 50 s
```

## Short takeaway

| Requirement | How v2 meets it |
| --- | --- |
| Show environment | `u_environment` from `env` tag (Production, Staging) |
| Show business service | CMDB CI service, then `snow-service` tag, then zone map |
| Show category and subcategory | Title keywords first, then Dynatrace severity |
| Show priority | Calculated by SNOW from impact and urgency; read back and printed in notes |
| Show impact | Calculated from Dynatrace impact level and environment |
| Show assignment group | Verified against `sys_user_group` (active) and sent as sys_id |
| Notes: cause | Problem title, root cause entity, top evidence, top error log |
| Notes: Dynatrace link | Problem URL |
| Notes: PagerDuty link | Real incident `html_url` from the PagerDuty REST API |
| Notes: which service | Business service, Dynatrace service, affected entity, application |
| Notes: which dashboard | `dashboard` tag, then app map, then zone map |

## Summary

Version 2 makes the seven classification fields reliable and adds one readable notes block. The assignment group is no longer a guessed name: the workflow checks it against the real group table (the 19,609-row list in pic 2) and sends the sys_id, so SNOW cannot silently blank it. After the ticket is created and PagerDuty is paged, the workflow asks PagerDuty for the actual incident link, reads the saved ticket back (so the notes show the real priority SNOW calculated), and writes the cause, links, service, and dashboard into the notes.

## Investigation

| Source | What it said |
| --- | --- |
| Pic 1 line 1 | Ticket should clearly show env, business service, category, subcategory, priority, impact, assign group |
| Pic 1 line 2 | Custom notes should list the cause, Dynatrace and PagerDuty link, which service, which dashboard |
| Pic 1 line 3 | Refer to sample data from pic |
| Pic 2 | SILVA STG `sys_user_group` list opened from incident Assignment group lookup; 19,609 groups; URL target value "Dynatrace Support"; groups belong to companies like AXA GROUP OPERATIONS |
| Pic 2 bottom | Tab "Additional comments (Customer visible)" — this is the "customer notes" field (`comments`) |
| Gap in seq 1 | Group sent as a name (could be dropped); no PagerDuty link (Events API does not return it); no dashboard; priority not shown |

## Result

Import `2-silva-ticket-fields-and-notes.workflow.yaml`, fill the three credential IDs, `__PD_SUBDOMAIN__`, dashboard IDs, and confirm field and choice names. Choose `NOTES_FIELD`: `comments` (customer visible, as requested) or `work_notes` (internal only).

---

## 1) Ticket fields — what each shows and where it comes from

| Field on form | Column (confirm) | Source order | Example |
| --- | --- | --- | --- |
| Environment | `u_environment` | `env` tag, then default | Production |
| Business service | `business_service` | CI business service, then `snow-service` tag, then zone map, then default | Policy Administration |
| Category | `category` | Title keyword, then severity | Capacity |
| Subcategory | `subcategory` | Same rule as category | Disk space |
| Impact | `impact` | Impact level and environment | 2 - Medium |
| Urgency | `urgency` | Severity and environment | 3 - Low |
| Priority | `priority` | **Calculated by SNOW** from impact and urgency | 4 - Low |
| Assignment group | `assignment_group` | CI support group, then `snow-group` tag, then zone map, then `Dynatrace Support`; each checked in `sys_user_group` | Dynatrace Support |

Also filled: Caller, Contact type (Monitoring), Company, Service offering, Configuration item, Short description, Summary, External Ticket Number.

### Assignment group check (pic 2)

```
candidates: CMDB support group → snow-group tag → zone map → "Dynatrace Support"
for each:  GET sys_user_group?sysparm_query=name=<candidate>^active=true
  found → use its sys_id (exact, cannot be dropped)
  none  → workflow stops with "No active sys_user_group matched"
```

| Why | Detail |
| --- | --- |
| 19,609 groups exist | Near-duplicate names are common (for example `DSQUAL_Config_Chile`, `DSQUAL_Config_IM`) |
| Names must match exactly | A display value that does not match is stored as empty |
| Inactive groups | Filtered out with `active=true` |
| Sending sys_id | The ticket always shows the intended group |

---

## 2) Notes block — example

See `2-silva-ticket-fields-and-notes-sample-note.txt`.

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
  - Top error (8x in 30 min): Could not allocate space for object in database 'PolicyDB' because the 'PRIMARY' filegroup is full

Links
  Dynatrace problem : https://abc12345.apps.dynatrace.com/ui/apps/dynatrace.davis.problems/problem/-1234567890_1759025740000V2
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

| Section | Where it comes from |
| --- | --- |
| Ticket classification | Read back from the saved ticket (display values), so it matches what the form shows |
| Cause | Problem title and root cause entity, top 3 root-cause evidence items, most frequent error log line |
| Dynatrace link | Problem URL built from the environment URL |
| PagerDuty link | `html_url` from `GET https://api.pagerduty.com/incidents?incident_key=dt-problem-<id>` |
| Which service | SNOW business service, Dynatrace service entity, affected entity and host, application tag |
| Dashboard | `dashboard` tag on the entity, then `DASHBOARD_BY_APP`, then `DASHBOARD_BY_ZONE` |
| Defaults used | Lists anything that fell back to a default, so the team can correct it |

### Customer-visible or internal?

| `NOTES_FIELD` value | Form tab | Who sees it |
| --- | --- | --- |
| `comments` (set by default) | Additional comments (Customer visible) | Caller and users too |
| `work_notes` | Work notes | IT staff only |

Links to Dynatrace and PagerDuty only work for people with access, and customer-visible text can be emailed to the caller. If the caller is only `Dynatrace JP`, `comments` is fine; if real users are callers, consider `work_notes`.

---

## 3) Workflow tasks

| Task | What it does | New in v2 |
| --- | --- | --- |
| `enrich-problem` | Facts, root-cause evidence, top error log, dashboard | Dashboard lookup, Dynatrace service name |
| `cmdb-lookup` | CI, support group, business service; skip retired | Same |
| `resolve-assignment-group` | Verifies group exists and is active; returns sys_id | **New** |
| `build-and-post-silva` | Seven "must show" fields plus mandatory fields, then POST | Group sent as sys_id; env in short description |
| `trigger-pagerduty` | Events API with INC number and dashboard link | Dashboard link added |
| `get-pagerduty-link` | PagerDuty REST lookup by incident key; retries 5 × 10 s | **New** |
| `write-ticket-notes` | Reads saved fields, writes the notes block | **New**; runs even if PD link lookup failed (uses fallback URL) |

### PagerDuty link — why a second call

| Fact | Detail |
| --- | --- |
| Events API reply | Only `status`, `message`, `dedup_key`; no incident URL |
| REST API | `GET /incidents?incident_key=<dedup_key>` returns `html_url` |
| Needs | A read-only REST API key (credential vault) and `api.pagerduty.com` in the allowlist |
| Timing | PagerDuty creates the incident a few seconds later, so the task retries |

---

## 4) Setup checklist

| Item | Where |
| --- | --- |
| Allowlist `silvastg.service-now.com`, `events.pagerduty.com`, `api.pagerduty.com` | Dynatrace External requests |
| `__SNOW_CREDENTIAL_ID__` | Credential vault (Username/Password) |
| `__PD_ROUTING_CREDENTIAL_ID__` | Credential vault (Token, Events integration key) |
| `__PD_API_CREDENTIAL_ID__` | Credential vault (Token, REST read-only key) |
| `__PD_SUBDOMAIN__` | Your PagerDuty account subdomain |
| Dashboard IDs in `DASHBOARD_BY_APP` and `DASHBOARD_BY_ZONE` | Dynatrace Dashboards app URLs |
| `GROUP_BY_ZONE`, `DEFAULT_GROUP` | Real group names from `sys_user_group` |
| Tags `env`, `app`, `snow-group`, `snow-service`, `snow-offering`, `dashboard`, `runbook` | Dynatrace auto-tagging |
| Column names and choice labels | `2026-09-28/1-silva-post-mandatory-fields-enrich/1.sh` |

---

## 5) Common problems

| Symptom | Cause | Fix |
| --- | --- | --- |
| Note shows "NOT SET" for a field | Label did not match a choice or record | Fix the mapping with exact labels |
| Workflow stops at group check | None of the candidate names exist or are active | Put a real group in `DEFAULT_GROUP` |
| PagerDuty link is the generic list URL | REST key, allowlist, or PD delay | Add key and allowlist; raise retry count |
| Dashboard says "None tagged" | No `dashboard` tag and no map entry | Add tag or map entry |
| Priority looks too low | Impact and urgency rules | Tune rules; priority itself is calculated by SNOW |
| Notes emailed to caller | `comments` is customer visible | Switch `NOTES_FIELD` to `work_notes` |

---

## Data flow map

```
Dynatrace Problem
  → enrich-problem ── cause, evidence, top error, dashboard, service
  → cmdb-lookup ───── CI, support group, business service (retired → stop)
  → resolve-assignment-group ── sys_user_group (active, exact) → sys_id
  → build-and-post-silva ── POST incident
        env | business service | category | subcategory | impact | urgency | group sys_id | CI
        → INC number, sys_id
  → trigger-pagerduty ── Events API (dedup_key)
  → get-pagerduty-link ── REST API → html_url
  → write-ticket-notes
        GET incident (display values, priority)
        PATCH comments: classification | cause | DT link | PD link | service | dashboard
```

## Related files

| File | Role |
| --- | --- |
| `2-silva-ticket-fields-and-notes.workflow.yaml` | Workflow v2 to import |
| `2-silva-ticket-fields-and-notes-sample-note.txt` | Example notes block |
| `2026-09-28/1-silva-post-mandatory-fields-enrich/` | v1 and discovery queries |
| `2026-09-24/1-silva-http-snow-pd-sync-workflows/` | CLOSE workflow |
| `2.sh` | Checks (you run) |

## Commands

See `2.sh`. STG only.
