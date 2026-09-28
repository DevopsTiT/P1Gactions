# SILVA POST With All Mandatory Fields

```
Real STG ticket INC30339599 — what came in?
  Filled:  Caller, On Behalf Of, Company, Service Offering, Short description, Summary,
           Impact/Urgency 3, External Ticket Number P-260915195, Vendor Kyndryl
  EMPTY *: Environment, Business service, Category, Subcategory, Assignment group
  Empty:   Configuration item
  Wrong:   Contact type = Phone (should be Monitoring / Event)

Why can a "*" field be empty?
  "*" mandatory = form (UI Policy) rule → only enforced in the browser
  API POST skips it unless a Data Policy exists → ticket saved with blanks

Fix → workflow fills every "*" field before POST:
  each field has a chain:  CMDB → Dynatrace tag → management-zone map → DEFAULT
  DEFAULT used?            → write "Enrichment gaps" in work notes
  still empty?             → stop (throw) — never send a ticket with a blank mandatory field
  after POST               → read back; value SNOW rejected? → work note lists it
```

## Short takeaway

| Question | Answer |
| --- | --- |
| Mandatory fields on the SILVA form | Caller, Environment, Business service, Service Offering, Category, Subcategory, Short description, Summary, Assignment group |
| Why they came in blank | Form mandatory rules do not apply to API calls |
| How we fill them | Each field tries CMDB, then Dynatrace tag, then zone map, then a safe default |
| How we send names instead of sys_ids | `?sysparm_input_display_value=true` |
| Safety net 1 | Throw before POST if any mandatory field is still empty |
| Safety net 2 | Read the ticket back; list any value SNOW rejected in a work note |
| Workflow | `1-silva-post-mandatory-fields.workflow.yaml` |
| Example body | `1-silva-post-mandatory-fields-sample-payload.json` |

## Summary

Your STG ticket shows the gap: the red-star fields Environment, Business service, Category, Subcategory, and Assignment group are empty, and the CI is missing. The star only forces people using the form; our HTTP POST bypasses it. The new workflow computes a value for every star field from the CMDB, Dynatrace tags, and small mapping tables, uses a safe default only as a last resort (and says so in work notes), refuses to post if something is still blank, and checks the saved ticket afterwards because SNOW silently drops names it cannot match.

## Investigation

Read from the screenshot of `INC30339599` (Staging):

| Form label | Mandatory (*) | Value in screenshot | Status |
| --- | --- | --- | --- |
| Caller | Yes | Dynatrace JP | OK |
| On Behalf Of | No | Dynatrace JP | OK |
| Contact type | No | Phone | Wrong for an automated alert |
| Company | No | AXA GROUP OPERATIONS | OK |
| Location | No | empty | Optional |
| Environment | Yes | -- None -- | **Missing** |
| Business service | Yes | empty | **Missing** |
| Service Offering | Yes | AXA GROUP OPERATIONS - Production | OK |
| SO Display Name | No | Standard - Production | Derived from offering |
| Configuration item | No | empty | **Should fill** |
| Category | Yes | -- None -- | **Missing** |
| Subcategory | Yes | -- None -- | **Missing** |
| Short description | Yes | [Dynatrace] SQL Server DB file space usage above 90% | OK but no entity name |
| Summary | Yes | [OPEN] P-260915195\| Problem SQL Server DB file space usage above 90% | OK but thin |
| Impact / Urgency / Priority | No | 3 / 3 / 3 - Medium | Fixed, not calculated |
| Assignment group | Yes | empty | **Missing** |
| Vendor / Interface | No | Kyndryl | Set by SILVA |
| External Ticket Number | No | P-260915195 | Our sync key lives here |

Note: the Dynatrace problem id sits in **External Ticket Number**. Check whether that column is `correlation_id` or a custom field (query in `1.sh`). The CLOSE workflow must search the same column.

## Result

Import the workflow, run the `1.sh` queries to confirm column names and choice values, edit the `FIELD`, `ENVIRONMENT`, `CATEGORY`, `GROUP_BY_ZONE`, `SERVICE_BY_ZONE`, and `DEFAULT` blocks, add the Dynatrace tags, and test in STG.

---

## 1) Every mandatory field and how it is filled

| Form label | Column (confirm) | Source chain (first non-empty wins) | Default if nothing found |
| --- | --- | --- | --- |
| Caller | `caller_id` | Fixed | `Dynatrace JP` |
| Environment | `u_environment` | `env` tag mapped: prod → Production, stg → Staging | `Production` + gap note |
| Business service | `business_service` | CI business service → `snow-service` tag → management zone map | `AXA GROUP OPERATIONS - Monitoring` + gap note |
| Service Offering | `service_offering` | `snow-offering` tag → env map | `AXA GROUP OPERATIONS - Production` + gap note |
| Category | `category` | Title keyword (disk, memory, cpu, sql) → Dynatrace severity map | `Monitoring` + gap note |
| Subcategory | `subcategory` | Same as category | `Custom alert` + gap note |
| Short description | `short_description` | `[Dynatrace] <title> - <entity>` | Always built |
| Summary | `description` (confirm) | `[OPEN] <problem id> \| Problem <title>` + facts block | Always built |
| Assignment group | `assignment_group` | CI support group → `snow-group` tag → management zone map | `JP Monitoring Triage` + gap note |

### Recommended extra fields

| Form label | Column (confirm) | Value |
| --- | --- | --- |
| Contact type | `contact_type` | `Monitoring` (instead of Phone) |
| Company | `company` | `AXA GROUP OPERATIONS` |
| On Behalf Of | `u_on_behalf_of` | `Dynatrace JP` |
| Configuration item | `cmdb_ci` | sys_id from CMDB lookup |
| Impact / Urgency | `impact`, `urgency` | Calculated (see below), so Priority is meaningful |
| External Ticket Number | `correlation_id` (confirm) | Problem id `P-260915195` |
| Work notes | `work_notes` | Top error logs, deploys, enrichment gaps |

### Category mapping (edit to match SILVA choice list)

| Dynatrace signal | Category | Subcategory |
| --- | --- | --- |
| Title contains disk, file space, storage, volume | Capacity | Disk space |
| Title contains memory, heap, oom | Capacity | Memory |
| Title contains cpu | Capacity | CPU |
| Title contains sql, database | Database | Database |
| Severity AVAILABILITY | Availability | Outage |
| Severity ERROR | Application | Error |
| Severity PERFORMANCE | Performance | Slow response |
| Severity RESOURCE_CONTENTION | Capacity | Resource usage |
| Anything else | Monitoring | Custom alert |

Keyword rules are checked first, so "SQL Server DB file space usage above 90%" becomes **Capacity / Disk space**.

### Impact and urgency

| Rule | impact | urgency |
| --- | --- | --- |
| Impact level APPLICATION | 1 | |
| Impact level SERVICES | 2 | |
| Impact level INFRASTRUCTURE in prod | 2 | |
| Impact level INFRASTRUCTURE not prod | 3 | |
| Prod and AVAILABILITY | | 1 |
| Prod and ERROR or PERFORMANCE | | 2 |
| Prod and anything else | | 3 |
| Not prod | | 3 |

The SQL file-space example is INFRASTRUCTURE in prod with RESOURCE_CONTENTION: impact 2, urgency 3, so P4 by default matrix. Change if your team wants P3 for this.

---

## 2) Example body for the real ticket

See `1-silva-post-mandatory-fields-sample-payload.json`.

```json
{
  "caller_id": "Dynatrace JP",
  "u_on_behalf_of": "Dynatrace JP",
  "contact_type": "Monitoring",
  "company": "AXA GROUP OPERATIONS",
  "u_environment": "Production",
  "business_service": "AXA GROUP OPERATIONS - Monitoring",
  "service_offering": "AXA GROUP OPERATIONS - Production",
  "cmdb_ci": "a1b2c3d4e5f60718293a4b5c6d7e8f90",
  "category": "Capacity",
  "subcategory": "Disk space",
  "short_description": "[Dynatrace] SQL Server DB file space usage above 90% - SQLPRD01",
  "description": "[OPEN] P-260915195 | Problem SQL Server DB file space usage above 90%\n\nSeverity: RESOURCE_CONTENTION   Impact level: INFRASTRUCTURE ...\nRoot cause entity: SQLPRD01 (HOST)\nApp: policy-db   Env: prod   Owner: jp-dba\n...\nEvidence:\n- DB file space usage 93% (threshold 90%)\n- Log file growth 4 GB in 1 h\n\nRunbook: https://confluence.example.com/runbooks/sql-file-space",
  "assignment_group": "JP DBA",
  "impact": "2",
  "urgency": "3",
  "correlation_id": "P-260915195",
  "work_notes": "Top error logs (last 30 min):\n- [8x] Could not allocate space for object in database 'PolicyDB' because the 'PRIMARY' filegroup is full\n\nDeployments (last 2 h):\n- none found\n\nEnrichment gaps (please correct):\n- Business service defaulted to \"AXA GROUP OPERATIONS - Monitoring\""
}
```

POST URL:

```
POST https://silvastg.service-now.com/api/now/v2/table/incident?sysparm_input_display_value=true
```

`sysparm_input_display_value=true` lets you send "JP DBA" or "Production" instead of sys_ids and choice codes. If the name does not match exactly, SNOW stores **empty** without an error. That is why the workflow reads the ticket back.

---

## 3) The workflow tasks

| Task | What it does |
| --- | --- |
| `enrich-problem` | Problem details, tags (env, app, owner, runbook, snow-group, snow-service, snow-offering), top error logs, deploys |
| `cmdb-lookup` | Finds the CI by full name, short name, or fqdn; returns support group and business service; retired CI means skip |
| `build-silva-payload` | Fills every mandatory field with the source chain; lists defaults as gaps; throws if anything mandatory is still empty |
| `post-silva-incident` | POST with `sysparm_input_display_value=true` |
| `verify-mandatory` | GET the ticket with display values; any mandatory value that did not stick is written to work notes |
| `trigger-pagerduty` | Pages with INC number, group, service, and gap list |

### Where to edit

| Block in `build-silva-payload` | What to put |
| --- | --- |
| `FIELD` | Real column names from `sys_dictionary` |
| `CONST` | Caller, company, contact type display values |
| `ENVIRONMENT` | Real Environment choice labels |
| `OFFERING_BY_ENV` | Real service offering names |
| `CATEGORY`, `SUBCATEGORY_BY_KEYWORD` | Real category and subcategory choice labels |
| `GROUP_BY_ZONE`, `SERVICE_BY_ZONE` | Your management zones and SNOW groups and services |
| `DEFAULT` | Safe fallback values agreed with SILVA owners |

### Dynatrace tags to add

| Tag | Example | Fills |
| --- | --- | --- |
| `env` | `env:prod` | Environment, service offering, urgency |
| `snow-group` | `snow-group:JP DBA` | Assignment group (when CI has none) |
| `snow-service` | `snow-service:Policy Administration` | Business service (when CI has none) |
| `snow-offering` | `snow-offering:AXA GROUP OPERATIONS - Production` | Service offering |
| `owner` | `owner:jp-dba` | Summary text |
| `runbook` | `runbook:https://...` | Summary text |

---

## 4) Common problems

| Symptom | Cause | Fix |
| --- | --- | --- |
| Field still blank after POST | Display value did not match exactly | Use the exact label from `1.sh`, or send sys_id |
| `verify-mandatory` note lists Category | Category choice label differs | Copy labels from `sys_choice` |
| Subcategory blank | Subcategory depends on Category and the pair is invalid | Use a valid pair from `sys_choice` (`dependent_value`) |
| Service offering blank | Offering not linked to the business service | Pick an offering that belongs to that service |
| Workflow throws "Mandatory still empty" | A mapping and its default are both empty | Fill the `DEFAULT` block |
| Many "defaulted" gaps | Tags or CMDB data missing | Add Dynatrace tags; fix CI support group |
| CLOSE cannot find the ticket | External Ticket Number is not `correlation_id` | Point CLOSE at the real column |
| Contact type stays Phone | SILVA business rule overrides it | Ask SILVA owners |

---

## Data flow map

```
Dynatrace Problem (CREATED / REOPENED)
  → enrich-problem      facts, tags, logs, deploys
  → cmdb-lookup         CI, support group, business service   (retired → skip)
  → build-silva-payload
        Environment      ← env tag        ← DEFAULT
        Business service ← CI ← tag ← zone ← DEFAULT
        Service offering ← tag ← env map  ← DEFAULT
        Category/Sub     ← keyword ← severity ← DEFAULT
        Assignment group ← CI ← tag ← zone ← DEFAULT
        Short desc / Summary / CI / impact / urgency / External Ticket Number
        any mandatory empty → STOP
  → post-silva-incident   POST ?sysparm_input_display_value=true → INC number
  → verify-mandatory      GET back → rejected values → work note
  → trigger-pagerduty     INC number + gaps
```

## Related files

| File | Role |
| --- | --- |
| `1-silva-post-mandatory-fields.workflow.yaml` | Workflow to import |
| `1-silva-post-mandatory-fields-sample-payload.json` | Example body for INC30339599 case |
| `2026-09-27/6-enriched-inc-post-to-silva/` | Earlier enrichment (context only) |
| `2026-09-27/8-enrich-existing-silva-inc-from-workflow/` | Enrich after SILVA creates |
| `2026-09-24/1-silva-http-snow-pd-sync-workflows/` | CLOSE workflow (check search column) |
| `1.sh` | Discover column names and choice values (you run) |

## Commands

See `1.sh`. STG only.
