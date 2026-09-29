# V6 Entire Logic Flow Explained

## Decision tree

```
Davis problem event (ACTIVE, CREATED)
 │
 ├─ TASK 1 extract-event-tags ─────────────────────────────── (no SILVA)
 │    1.1 real event? no → SAMPLE_EVENT
 │    1.2 Problems API → extra tags + evidence (fails without scope → continue)
 │    1.3 split every tag → key / value
 │    1.4 group candidates   (support → specific → default)
 │    1.5 service tag        (4 known keys)
 │    1.6 environment        (real env tag → patch env tag → security context → default)
 │    1.7 maintenance        (event field → AGO_Maintenance tag)
 │    1.8 search inputs      (host, DB names, db type, trigram, region, domain)
 │    1.9 dynatrace_alert + event_properties + tenant id
 │
 ├─ TASK 2 resolve-snow-values ────────────────────────────── (SILVA GET only)
 │    2.1 GROUP     GROUP_MAP → tag checked → tag name kept
 │    2.2 SERVICE   A map/tag → B CI link → C scored search → D first answer
 │    2.3 BOTH MISSING? → DEFAULT SET (QA Platforms, Ops_Middleware_Monitoring_AXAJP, PoC / VoA / Demo)
 │    2.4 SERVICE still missing → QA Platforms
 │    2.5 GROUP still missing → service group → CI group → default group
 │    2.6 OFFERING  service+env → service first → group+env → group first → default
 │    2.7 COMPANY   service → CI → group → (task 3 default)
 │
 ├─ TASK 3 display-result ─────────────────────────────────── (no network)
 │    3.1 build short description + Additional Information
 │    3.2 build snow_incident_payload (16 fields)
 │    3.3 snow_form_check → MISSING mandatory? → not ready
 │    3.4 maintenance? → do not create
 │    3.5 build pagerduty_payload
 │
 ├─ TASK 4 post-silva-incident ────────────────────────────── (SILVA GET + POST)
 │    create_incident false → skipped
 │    sample event → skipped
 │    open incident with same correlation_id → exists
 │    DRY_RUN → dry_run
 │    POST → created
 │
 └─ TASK 5 trigger-pagerduty ──────────────────────────────── (PagerDuty POST)
      task 4 skipped → skipped
      incident existed → skipped
      DRY_RUN → dry_run
      POST enqueue → triggered
```

## Short takeaway

| Question | Answer |
|---|---|
| What starts the workflow? | A Davis problem that just became ACTIVE (status_transition CREATED) |
| Where does most data come from? | `entity_tags` on the event |
| Which task talks to SILVA? | Task 2 (read) and task 4 (read + create) |
| Which task talks to PagerDuty? | Task 5 only |
| How are the two key SNOW values found? | Group from tags; business service by a chain of five methods |
| What stops a ticket? | Maintenance, a missing mandatory field, a sample run, or an already open incident |
| What links OPEN to CLOSE? | `correlation_id = display_id` and `dedup_key = dt-problem-<display_id>` |

## Summary

The workflow is a pipeline of five tasks. Task 1 only reads the event. Task 2 only reads SILVA. Task 3 only builds and decides. Tasks 4 and 5 are the only ones that change anything outside Dynatrace, and both stop early when task 3 says no or when a ticket already exists.

---

## Trigger

| Item | Value | Meaning |
|---|---|---|
| Event kind | `DAVIS_PROBLEM` | A Dynatrace problem |
| Status | `ACTIVE` | The problem is open |
| Status transition | `CREATED` | Only the first time, not on every update |
| Categories | error, resource, slowdown, availability, custom | All problem types |

Because of `CREATED`, updates to the same problem do not start the workflow again. Task 4's duplicate check covers the rare case where it does.

---

## TASK 1 — extract-event-tags

**Goal:** turn the raw event into clean, labelled inputs. No SILVA call.

### Step 1.1 — get the event

| Case | What happens |
|---|---|
| Triggered by a real problem | `ex.event()` returns the event |
| You press Run by hand | There is no event, so `SAMPLE_EVENT` (your Oracle input) is used and `usedSample` is true |

### Step 1.2 — Problems API (optional)

| Case | What happens |
|---|---|
| Scope `environment-api:problems:read` added | Adds extra tags, root cause entity, evidence details (for example error rate) |
| Scope missing | Error text saved in `problemApi`, the task continues with the event only |
| Sample event | Skipped |

### Step 1.3 — collect and split tags

All tags come from `entity_tags` (plus Problems API tags if available). Each tag is split at the first `:`.

| Raw tag | Key | Value |
|---|---|---|
| `AGO_ORACLE_ASSIGNMENT_GROUP:Database_AXAJP` | AGO_ORACLE_ASSIGNMENT_GROUP | Database_AXAJP |
| `AGO_DB:ORACLE` | AGO_DB | ORACLE |
| `host:deaa310b` | host | deaa310b |
| `[Kubernetes]app:web` | app (context removed) | web |
| `AGO_Maintenance` (no colon) | AGO_Maintenance | empty |

Tags are also sorted into `tags.ago` (keys starting with AGO_) and `tags.other`.

### Step 1.4 — group candidates

Keys are compared in lower case. All matches are kept, in this order, with duplicates removed.

| Order | Key rule | Your Oracle event |
|---|---|---|
| 1 | `ago_axa_supportgroup` | none |
| 2 | Ends with `assignment_group` or `support_group` (not the default or support tag) | AGO_ORACLE_ASSIGNMENT_GROUP → Database_AXAJP |
| 3 | `ago_default_assignment_group` | same value, removed as duplicate |

### Step 1.5 — business service tag

| Key checked | Your Oracle event |
|---|---|
| `snow-service` | none |
| `ago_axa_businessservice` | none |
| `business-service` | none |
| `u_business_service` | none |

### Step 1.6 — environment

| Order | Source | Your Oracle event |
|---|---|---|
| 1 | Tag `ago_axaenvironmentname` | none |
| 2 | Tag `env` or `environment` | none |
| 3 | Tag key containing `environment` but not `patch` | none |
| 4 | Tag key containing `patch` and `environment` | ACCEPTANCE |
| 5 | Last part of `dt.security.context` | not needed |
| 6 | `DEFAULT_ENVIRONMENT` | not needed |

The tag value is then mapped to a SILVA label with the `ENVIRONMENT` table: `acceptance` → "Integration / Test". The result keeps `tag_value`, `label` and `from`.

### Step 1.7 — maintenance

| Order | Source | Result |
|---|---|---|
| 1 | Event field `maintenance.is_under_maintenance` is true | maintenance true |
| 2 | Tag `AGO_Maintenance:True` | maintenance true |
| 3 | Neither | maintenance false |

### Step 1.8 — search inputs for SILVA

| Field | Rule | Your Oracle event |
|---|---|---|
| host | Tag `host`, else `host.name`, else `dt.entity.host.name` | deaa310b |
| DB or entity names | `affected_entity_names`, the field named in `affected_entity_types`, `root_cause_entity_name`; Dynatrace ids like `CUSTOM_DEVICE-...` removed | DEA10B01 |
| db_type | Tag `ago_db` | ORACLE |
| trigram | Tag key containing `trigram` | ALJ |
| region | Tag key containing `region` | AP-SOUTHEAST-1 |
| platform | Tag key containing `platform` | AWS_IAAS |
| domain | Tag `ago_domain` or key containing `domain` | none |

### Step 1.9 — alert block and extras

| Output | Built from |
|---|---|
| `dynatrace_alert.service_name` | Root cause name, else affected name, else entity field, else host |
| `dynatrace_alert.event_name` | `event.name` |
| `dynatrace_alert.event_description` | `event.description` |
| `dynatrace_alert.severity` | `event.severity`, else `event.category` |
| `dynatrace_alert.problem_id` | `display_id` |
| `dynatrace_alert.problem_url` | Event URL, else built from the tenant URL and `event.id` |
| `dynatrace_alert.entity_id` | First `affected_entity_ids`, else `root_cause_entity_id` |
| `dynatrace_alert.error_rate` | Problems API evidence (empty without scope) |
| `event_properties` | Every event field as key and value (except `entity_tags`), max 300 characters each |
| `dt_environment_id` | First part of the tenant URL |

---

## TASK 2 — resolve-snow-values

**Goal:** get real SILVA records (with sys_ids) for everything the form needs. GET calls only. Every call is recorded in `steps` with table, query, status and match count.

### Step 2.1 — assignment group

| Order | Source | Kept when | `from` |
|---|---|---|---|
| 1 | `GROUP_MAP` by trigram, service tag or entity name | Active in `sys_user_group` | GROUP_MAP |
| 2 | Each group candidate from task 1 | Active in `sys_user_group` | tag AGO_... |
| 3 | First group candidate, even if not found | Always (no sys_id) | tag ... (not verified in SILVA) |

For your Oracle event: Database_AXAJP, sys_id 5223d8c61b8f3c54688064e4604bcb12, from tag AGO_ORACLE_ASSIGNMENT_GROUP.

### Step 2.2 — business service (stops at the first success)

**A. Fixed name**

| Source | Query |
|---|---|
| `SERVICE_MAP` (key = trigram, service tag value or entity name) | `cmdb_ci_service name=<name>` |
| Service tag from step 1.5 | same |

**B. From the CI (host or DB record)**

| Step | Query |
|---|---|
| B1 host | `cmdb_ci` name or fqdn = host, short host, short host + each domain in DOMAINS |
| B1 fallback | name or fqdn starts with `<short host>.` |
| B2 DB | `cmdb_ci name=<DB>`, else `nameLIKE<DB>` |
| B3 | The CI's own `business_service` or `service` field, only if it is a 32-character sys_id |
| B4 | `svc_ci_assoc ci_id=<CI>` → service_id |
| B5 | `cmdb_rel_ci child=<CI>` → parent whose class contains "service" |

**C. Scored search**

| Search | Query | Your values |
|---|---|---|
| 1 | `cmdb_ci_service assignment_group=<group sys_id>^ORsupport_group=<group sys_id>` | Database_AXAJP sys_id |
| 2 | `nameLIKE<db type>^nameLIKE<env tag>` | ORACLE, ACCEPTANCE |
| 3 | `nameLIKE<db type>^nameLIKE<region prefix>` | ORACLE, AP-SOUTHEAST |
| 4 | `nameLIKE<trigram>` | ALJ |
| 5 | Search 2 on `cmdb_ci_service_technical` | ORACLE, ACCEPTANCE |

All results are merged by sys_id and scored:

| Rule | Points |
|---|---|
| Owned by the resolved group | 3 |
| Name contains the DB type | 2 |
| Name contains the environment tag | 2 |
| Name contains the trigram as a whole word | 2 |
| Name contains the region prefix | 1 |
| Operational | 1 |
| Business service class or classification | 1 |
| Each extra search that found it | 1 |

Picked only if the best score is at least 5 and strictly higher than the second. The top 10 go to `service_candidates`.

**D. First answer by known info**

| Order | Query on `cmdb_ci_service` |
|---|---|
| 1 | `assignment_group.nameLIKE<group>` (your query.sh query) |
| 2 | `support_group.nameLIKE<group>` |
| 3 | `nameLIKE<trigram>` |
| 4 | `nameLIKE<db type>` |

The first query with rows wins. From its rows, the first one whose name contains the environment label or tag is taken, else the first row. All rows go to `first_answer_rows`.

### Step 2.3 — default set

Runs only when **no service** was found by A to D **and no group** was found in step 2.1.

| Field | Value |
|---|---|
| Business service | QA Platforms |
| Assignment group | Ops_Middleware_Monitoring_AXAJP (sys_id looked up) |
| Service offering | Name starts with "QA Platforms - AXA GROUP OPERATIONS" (parent QA Platforms first) |
| Environment | PoC / VoA / Demo |
| Flag | `default_set_used = true` |

### Step 2.4 — business service single fallback

If the service is still empty (the group was found), use `DEFAULT_BUSINESS_SERVICE` (QA Platforms).

### Step 2.5 — group fallback

Only when no group came from step 2.1:

| Order | Source |
|---|---|
| 1 | Business service assignment group |
| 2 | Business service support group |
| 3 | CI support group |
| 4 | `DEFAULT_GROUP` |

### Step 2.6 — service offering

| Order | Source |
|---|---|
| 1 | Default set offering (only in the default set) |
| 2 | Offering of the service whose `u_environment` equals the environment label |
| 3 | Offering of the service whose name contains the label |
| 4 | First offering of the service |
| 5 | First offering owned by the group (environment match first) |
| 6 | Default offering |

### Step 2.7 — company

| Order | Source |
|---|---|
| 1 | Business service company |
| 2 | CI company |
| 3 | Assignment group company |
| 4 | Empty, task 3 uses `DEFAULT_COMPANY` (AXA GROUP OPERATIONS) |

### Task 2 output

| Block | Content |
|---|---|
| `snow_required` | default_set_used, assignment_group, business_service, service_offering, company, cmdb_ci, environment (each with `from`) |
| `servicenow_enrichment` | correctoutput.sh layout of the chosen service |
| `group_checks` | Each group candidate and whether SILVA found it |
| `first_answer_rows` | Rows from step D |
| `service_candidates` | Top 10 from step C |
| `cis_found` | Host and DB CIs |
| `steps` | Every SILVA call |

---

## TASK 3 — display-result

**Goal:** turn the lookups into the exact bodies SNOW and PagerDuty need, and decide. No network.

### Step 3.1 — short description

`[DYNATRACE JAPAN][<CI fqdn, else CI name, else host, else service name>] - <event name>`, max 160 characters.

### Step 3.2 — Additional Information (inside Summary)

| Key | Value |
|---|---|
| correlation_id | Dynatrace entity id |
| discovered_name | service_name |
| dynatrace_severity | `event.category`, else severity |
| environmentId | Tenant id |
| environmentName | `DT_ENVIRONMENT_NAME` |
| event_properties | All event fields plus `entity_tags` |
| problem_displayId | display_id |
| u_external_url | Problem link |

### Step 3.3 — SNOW incident body

| Payload field | Value |
|---|---|
| caller_id | Dynatrace JP |
| u_on_behalf_of | Dynatrace JP |
| contact_type | event |
| company | Company sys_id, else AXA GROUP OPERATIONS |
| u_environment | Environment label mapped with ENV_VALUE |
| business_service | sys_id, else name |
| service_offering | sys_id, else name |
| cmdb_ci | CI sys_id (left out if none) |
| category | other |
| subcategory | other |
| impact | 4 |
| urgency | 4 |
| assignment_group | sys_id, else name |
| assigned_to | Only with the default set and if `DEFAULT_SET_ASSIGNED_TO` is set |
| short_description | Step 3.1 |
| description | Event description, then "Additional Information:" and the JSON from step 3.2 |
| correlation_id | display_id |

### Step 3.4 — form check and decision

| Check | Effect |
|---|---|
| No group name | Added to `missing` |
| No service sys_id and no CI sys_id | Added to `missing` |
| Mandatory form field empty (Caller, Environment, Business service, Service Offering, Category, Subcategory, Short description, Summary) | Row MISSING, added to `missing` |
| `missing` empty | `ready_for_snow` true |
| Maintenance on and `SKIP_WHEN_MAINTENANCE` | `create_incident` false |
| `create_incident` | ready_for_snow and not maintenance |

### Step 3.5 — PagerDuty body

| Field | Value |
|---|---|
| event_action | trigger |
| dedup_key | dt-problem-<display_id> |
| summary | Same as short description |
| source | Host, else service name |
| severity | error for Infrastructure impact, else warning |
| group | Environment label |
| component | Trigram, else service name |
| custom_details | Problem id, event, host, environment, business service, group, db type, trigram |

---

## TASK 4 — post-silva-incident

| Step | Check | Result |
|---|---|---|
| 4.1 | `decision.create_incident` false | `skipped` with reason |
| 4.2 | Sample event and `ALLOW_SAMPLE_POST` false | `skipped` |
| 4.3 | GET `incident correlation_id=<display_id>^active=true` finds a row | `exists` with number |
| 4.4 | `DRY_RUN` true | `dry_run` with body |
| 4.5 | POST `/api/now/v2/table/incident` | `created` with number, sys_id, url |
| 4.6 | POST returns an error | Task fails with the SILVA message |

## TASK 5 — trigger-pagerduty

| Step | Check | Result |
|---|---|---|
| 5.1 | Task 4 skipped | `skipped` |
| 5.2 | Task 4 `exists` and `SEND_WHEN_INCIDENT_EXISTS` false | `skipped` |
| 5.3 | Add routing key, SILVA number and link to the body | |
| 5.4 | `DRY_RUN` true or task 4 was dry run | `dry_run`, routing key hidden |
| 5.5 | POST `https://events.pagerduty.com/v2/enqueue` | `triggered` with dedup_key |
| 5.6 | PagerDuty error | Task fails with the message |

---

## Walkthrough with your Oracle event

| Stage | Result |
|---|---|
| Trigger | P-260916434, Oracle DB Instance down |
| Group candidates | Database_AXAJP |
| Environment | ACCEPTANCE → Integration / Test (from the patch tag) |
| Maintenance | AGO_Maintenance:True → maintenance true |
| Search inputs | deaa310b, DEA10B01, ORACLE, ALJ, AP-SOUTHEAST-1 |
| Group | Database_AXAJP, verified, sys_id 5223d8c6... |
| Service | CI link if SILVA has one; else scored search; else first answer by group (likely "Informatica - AXA DIRECT JAPAN - Integration / Test - Gold") |
| Default set | Not used (group found) |
| Decision | create_incident **false** because maintenance is true |
| Task 4 | skipped |
| Task 5 | skipped |

Note: with the current tags, this Oracle event never creates a ticket, because `AGO_Maintenance:True` is set. Set `SKIP_WHEN_MAINTENANCE = false` if these tags are permanent and should not block tickets.

## Data flow

```
Dynatrace event
  │ entity_tags, display_id, event.*, maintenance, affected entities
  ▼
TASK 1  extract
  │ dynatrace_alert, snow_inputs, event_properties, tags, tenant id
  ▼
TASK 2  SILVA GET
  │ sys_user_group, cmdb_ci, svc_ci_assoc, cmdb_rel_ci,
  │ cmdb_ci_service, cmdb_ci_service_technical, service_offering
  │ → snow_required (+ from, default_set_used)
  ▼
TASK 3  build + decide
  │ snow_incident_payload, pagerduty_payload, snow_form_check, decision
  ▼
TASK 4  SILVA
  │ GET incident by correlation_id → exists?  no → POST incident
  ▼
TASK 5  PagerDuty
  │ POST enqueue (dedup_key dt-problem-<display_id>)
  ▼
Later: CLOSE workflow → GET by correlation_id → PATCH Resolved → PagerDuty resolve
```

## Related files

| File | What it is |
|---|---|
| `../9-v6-full-open-silva-pagerduty/9-v6-full-open-silva-pagerduty.workflow.yaml` | The workflow explained here |
| `../8-v5-default-qa-platforms-fallback/` | Default set details |
| `../7-first-answer-fallback-by-group/` | Step D details |
| `../6-snow-payload-match-incident-form/` | Payload field details |
| `10.sh` | One manual check per SILVA step |

## Commands

See `10.sh`.
