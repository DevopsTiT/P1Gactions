# Workflow Flow And APIs Explained

## Decision tree

```
Davis problem CREATED (or Run with no event → SAMPLE_EVENT)
  Task 1 extract-event-tags
    reads event + Dynatrace Problems API v2 (entity tags)
    → group candidates, environment, maintenance, app code, host, names
  Task 2 resolve-snow-values (SILVA GET only)
    group:    GROUP_MAP → group tags → sys_user_group (exact name, active)
    service:  SERVICE_MAP or service tag → host/entity CI → scored search → first answer → DEFAULT_BUSINESS_SERVICE
    offering: offerings of the service matching environment → fallbacks
    final group by GROUP_ORDER: tag → service group → service support group → CI support group → DEFAULT_GROUP
  Task 3 build-payload (no network)
    SILVA body (16 keys) + PagerDuty body + decision
    decision = create only if nothing missing AND maintenance off
  Task 4 (parallel)
    PREVIEW: 4a field check + duplicate GET    | 4b PagerDuty body check
    OPEN:    4a POST /api/now/v2/table/incident | 4b POST events.pagerduty.com/v2/enqueue
```

## Short takeaway

| Question | Answer |
|---|---|
| How many tasks? | Five: 1, 2, 3, then 4a and 4b in parallel. |
| Which APIs does PREVIEW call? | Dynatrace Problems API v2 (read) and the SILVA Table API with GET only. |
| Which extra APIs does OPEN call? | SILVA Table API POST to create the incident, and PagerDuty Events API v2 to trigger a page. |
| How do tasks share data? | Each task reads earlier results with `ex.result("<task name>")`. |
| When is nothing sent in OPEN? | Maintenance on, a required field missing, a sample run, or an open duplicate exists. |

## Summary

Task 1 turns the Dynatrace problem into clean inputs. Task 2 asks SILVA which group, business service, offering and host CI match those inputs. Task 3 assembles the SILVA incident body and the PagerDuty body and decides create or skip. Task 4 either previews those bodies (PREVIEW) or sends them in parallel (OPEN).

## APIs used

| API | Who calls it | Method | Purpose |
|---|---|---|---|
| Workflow execution (`execution(executionId)`) | Every task | SDK call | Read the trigger event and earlier task results. |
| Dynatrace Problems API v2 (`problemsClient.getProblem`) | Task 1 | GET | Get entity tags, root cause entity and evidence for the problem. |
| Dynatrace environment URL (`getEnvironmentUrl`) | Task 1 | SDK call | Build the problem link and environment ID. |
| SILVA Table API `/api/now/v2/table/<table>` | Task 2, PREVIEW 4a, OPEN 4a | GET | Look up groups, services, offerings, CIs, relationships and duplicates. |
| SILVA Table API `/api/now/v2/table/incident` | OPEN 4a only | POST | Create the incident. |
| PagerDuty Events API v2 `https://events.pagerduty.com/v2/enqueue` | OPEN 4b only | POST | Trigger the page. |

SILVA calls use Basic auth (`Tech_DynatraceJP_WS`) and these query options:

| Option | What it does |
|---|---|
| `sysparm_query` | The filter, e.g. `name=Database_AXAJP^active=true`. `^` means AND, `^OR` means OR. |
| `sysparm_fields` | Only return these columns. |
| `sysparm_display_value=all` | Return both the stored value (sys_id) and the readable name. |
| `sysparm_exclude_reference_link=true` | Do not return extra link objects for reference fields. |
| `sysparm_limit` | Maximum rows. |

## Trigger

| Item | Value | What it means |
|---|---|---|
| Event filter | `event.kind == "DAVIS_PROBLEM" AND event.status == "ACTIVE" AND event.status_transition == "CREATED"` | Runs once when a new problem opens. |
| Categories | error, resource, slowdown, availability, custom | All problem types. |
| hourlyExecutionLimit | 200 (PREVIEW), 1000 (OPEN) | Safety cap per hour. |
| Run button (no event) | Uses SAMPLE_EVENT P-260916863 | For testing. OPEN never posts for a sample unless ALLOW_SAMPLE_POST is true. |

## Task 1 — extract-event-tags

**Calls:** Problems API v2 (GET). No SILVA.

| Step | What it does | Output field |
|---|---|---|
| 1 | Read the trigger event. If there is none, use SAMPLE_EVENT. | `usedSample` |
| 2 | If USE_PROBLEM_API is true, call `getProblem(event.id)` and add its entity tags. | `problemApi`, `tags.raw` |
| 3 | Split every tag at the first ":" into key and value. Remove prefixes like `[Kubernetes]`. | parsed tags |
| 4 | Build group candidates in order: AGO_AXA_SUPPORTGROUP, then any *_ASSIGNMENT_GROUP or *_SUPPORTGROUP, then AGO_DEFAULT_ASSIGNMENT_GROUP. Same values are kept once. | `snow_inputs.group_candidates` |
| 5 | Find a service tag: snow-service, ago_axa_businessservice, business-service, u_business_service. | `snow_inputs.service_tag` |
| 6 | Environment: AGO_AXAENVIRONMENTNAME, env, other *environment*, k8s namespace, patch environment, then dt.security_context, then default Development. Values like ACCEPTANCE map to SILVA labels like Integration / Test. | `snow_inputs.environment` |
| 7 | App code: dt.cost.product, ago_axaappcode, app_code, or the `[CODE.ENV]` prefix of the service name. | `app_code` |
| 8 | Other tags: ago_db, domain, trigram or company, platform, region, host. | `db_type`, `trigram`, `host` |
| 9 | Maintenance: event field `maintenance.is_under_maintenance`, or tag AGO_Maintenance:True when USE_MAINTENANCE_TAG is true. | `maintenance` |
| 10 | Error rate from problem evidence or the description. Problem link. | `error_rate`, `problem_url` |
| 11 | Names usable for CI search (no Dynatrace IDs, no wildcards, no prefix). | `db_or_entity_names` |

Hyphen and underscore are treated the same in tag keys (v7.1).

**Returns:** `dynatrace_alert` (clean alert facts), `snow_inputs` (what task 2 needs), `tags`, `dt_environment_id`, `event_properties`.

## Task 2 — resolve-snow-values

**Calls:** SILVA Table API, GET only.

### 2.1 Group from map or tags

| Order | Source | SILVA call |
|---|---|---|
| 1 | GROUP_MAP (manual map by app code, trigram or service tag) | `sys_user_group` where `name=<value>^active=true` |
| 2 | Each group candidate from task 1, until one exists | same |
| 3 | No match in SILVA | Keep the first tag name without a sys_id (marked "not verified"). |

### 2.2 Business service (first method that finds one wins)

| Method | What it does | SILVA tables |
|---|---|---|
| A | SERVICE_MAP or service tag, exact name | `cmdb_ci_service` (offerings excluded) |
| B | Find the host CI by name or FQDN (tries domains like jp.intraxa), then entity names and app code. From the CI, get its service from its own field, `svc_ci_assoc`, or `cmdb_rel_ci`. | `cmdb_ci`, `svc_ci_assoc`, `cmdb_rel_ci`, `cmdb_ci_service` |
| C | Searches by app code, group sys_id, db type plus environment, db type plus region, trigram. Results are scored. The best wins only if score is at least 5 and higher than the second. | `cmdb_ci_service` |
| D | First answer by app code, group name, support group name or db type. Prefers a name that contains the environment. | `cmdb_ci_service` |
| E | DEFAULT_BUSINESS_SERVICE "QA Platforms" | `cmdb_ci_service` |

If the record found is actually an offering, the workflow switches to its parent business service.

### 2.3 Environment and offering

| Step | What it does |
|---|---|
| 1 | Default set = no service found AND no group tag. Then environment becomes "PoC / VoA / Demo". |
| 2 | Get all offerings with `parent=<business service>` from `service_offering`. |
| 3 | Pick the one whose u_environment or name matches the environment label. |
| 4 | Fallbacks: the offering found by the search, the default offering set, the first offering of the service, the first offering of the group. |

### 2.4 Final assignment group (GROUP_ORDER)

| Order | Source |
|---|---|
| 1 | tag (from 2.1) |
| 2 | Business service assignment_group |
| 3 | Business service support_group |
| 4 | Host CI support_group |
| 5 | DEFAULT_GROUP "Ops_Middleware_Monitoring_AXAJP" |

### 2.5 Company

Business service company, else host CI company, else group company, else DEFAULT_COMPANY in task 3.

**Returns:** `snow_required` (group, business service, offering, company, host CI, environment), `servicenow_enrichment`, `group_checks`, `offering_candidates`, `service_candidates`, `cis_found`, and `steps` (every SILVA call with table, query, HTTP status and match count).

## Task 3 — build-payload

**Calls:** none. Pure assembly.

### SILVA incident body

| Key | Value comes from |
|---|---|
| caller_id | CALLER_SYS_ID (Dynatrace JP) |
| u_on_behalf_of | ON_BEHALF_OF_SYS_ID (Dynatrace JP) |
| contact_type | event |
| company | Business service company, or found company, or DEFAULT_COMPANY |
| u_environment | Environment label from task 1 |
| u_business_service | Business service sys_id from task 2 |
| cmdb_ci | Service offering sys_id from task 2 |
| u_configuration_item | Host CI sys_id from task 2 |
| category | other |
| subcategory | other |
| impact | 4 |
| urgency | 4 |
| assignment_group | Final group sys_id from task 2 |
| short_description | `[DYNATRACE JAPAN][<host or name>] - <event name>`, max 160 characters |
| description | Event description plus "Additional Information" (problem ID, URL, entity, severity, error rate, environment, app code, hosts, alerting profile, tags) |
| correlation_id | Problem display ID, e.g. P-260916434 |

Empty values are left out of the body.

### Decision

| Condition | Result |
|---|---|
| Any of assignment_group, u_business_service, cmdb_ci, u_environment, short_description is empty | create_incident false, reason "missing: ..." |
| Maintenance is on | create_incident false, reason "maintenance is on" |
| Otherwise | create_incident true, reason "ok" |

### PagerDuty body

| Field | Value |
|---|---|
| routing_key | Placeholder here. OPEN 4b sets the real key. |
| event_action | trigger |
| dedup_key | `dt-problem-<problem id>` so repeats join the same PagerDuty incident |
| client and client_url | Dynatrace and the problem link |
| payload.summary | Same as short_description |
| payload.source | Host FQDN or name |
| payload.severity | error for Infrastructure impact, otherwise warning |
| payload.group | Environment label |
| payload.component | Trigram or service name |
| payload.custom_details | Problem ID, event, service, host, environment, business service, offering, group, db type, trigram, correlation ID |

**Returns:** `decision`, `missing`, `used_sample_event`, `snow_incident_payload`, `pagerduty_payload`, `field_sources` (where each value came from).

## Task 4a — PREVIEW preview-silva-incident

**Calls:** SILVA GET on `incident` only.

| Step | What it does |
|---|---|
| 1 | Check 16 SILVA form fields. MISSING = mandatory and empty. WRONG = reference field that is not a 32-character sys_id. EMPTY = optional and empty. |
| 2 | Duplicate check: `incident` where `correlation_id=<problem id>^active=true`. |
| 3 | open_v7_would: SKIP for decision false, sample event or open duplicate, otherwise CREATE. |

**Returns:** `ready`, `open_v7_would`, `problems`, `field_check`, `duplicate_check`, `snow_incident_payload`.

## Task 4b — PREVIEW preview-pagerduty

**Calls:** none.

| Check | Must be |
|---|---|
| event_action | trigger |
| dedup_key | Starts with dt-problem-P- |
| payload.summary | Present and up to 1024 characters |
| payload.source | Present |
| payload.severity | critical, error, warning or info |

**Returns:** `ready`, `open_v7_would`, `checks`, `pagerduty_payload` (routing key hidden).

## OPEN v7 difference — task 4a post-silva-incident and 4b trigger-pagerduty

| Task | Steps |
|---|---|
| 4a post-silva-incident | Skip if decision false or sample event. GET duplicate by correlation_id. If none, POST the body to `/api/now/v2/table/incident`. Return number, sys_id and URL. DRY_RUN true logs only. |
| 4b trigger-pagerduty | Skip if decision false or sample event. POST the PagerDuty body with the real routing key to `events.pagerduty.com/v2/enqueue`. DRY_RUN true logs only. |

Both start after task 3, so neither waits for the other. Duplicates are prevented by correlation_id in SILVA and dedup_key in PagerDuty.

## Data flow

```
Dynatrace event ──┐
Problems API v2 ──┴→ Task 1: tags, environment, maintenance, host, app code
                        │ snow_inputs
                        ▼
                  Task 2: SILVA GET
                    sys_user_group → group
                    cmdb_ci / svc_ci_assoc / cmdb_rel_ci / cmdb_ci_service → business service
                    service_offering → offering
                        │ snow_required
                        ▼
                  Task 3: SILVA body + PagerDuty body + decision
                        │
            ┌───────────┴────────────┐
            ▼                        ▼
  4a SILVA                    4b PagerDuty
  PREVIEW: check + GET dup    PREVIEW: check only
  OPEN: GET dup + POST        OPEN: POST enqueue
```

## Related files

| File | Purpose |
|---|---|
| `23-preview-v7-1-no-post-first/23-preview-v7-1-no-post-first.workflow.yaml` | PREVIEW v7.1, explained here. |
| `17-open-v7-silva-pagerduty/17-open-v7-silva-pagerduty.workflow.yaml` | OPEN v7, same tasks 1 to 3 plus the sending tasks. |
| `21-silva-verify-checklist/` | How to verify task 2 and 3 values in SILVA. |
| `24.sh` | Commands to replay task 2 calls by hand. |

## Commands

See `24.sh`. Each line reproduces one SILVA call that task 2 or 4a makes, using the P-260916434 values.
