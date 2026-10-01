# Workflow Functions And API Traces

## Decision tree

```
I want to trace a run. What do I need?
 Which task called which API?          → section 4 (numbered call traces)
 What does a function do and call?     → section 2 (function inventory) + section 3 (call graphs)
 Which data moved between tasks?       → section 5 (data handoff, field level)
 The REAL calls of one execution?
   Dynatrace side → Workflows → Executions → task → Result / Log
                  → or Automation API: executions → tasks → result / log (51.sh)
   OPEN task 2    → its "steps" array = every SILVA GET with query, HTTP status, matches
   SILVA side     → sys_audit (field changes), sys_journal_field (work notes) for the incident
   PagerDuty side → incident log entries (REST API key, not the routing key)
```

## Short takeaway

| Question | Answer |
|---|---|
| How many functions are there (main included)? | OPEN: 31 (task 1: 9, task 2: 15, 4a: 2, 5a: 2, tasks 3, 4b, 5b: 1 each). CLOSE: 14 (task 1: 4, 2a: 9, 2b: 1). |
| Which functions make network calls? | OPEN: `getProblem`, `getRows` (task 2), the `fetch` calls in 4a, 5a, 5b. CLOSE: `getProblem`, `getRows`, `patch`, the `fetch` in 2b. |
| Which SDK functions are used? | `execution`, `ex.event`, `ex.result`, `problemsClient.getProblem`, `getEnvironmentUrl`. |
| Where is a built-in trace already? | OPEN task 2 returns `steps`: one row per SILVA call. CLOSE 2a returns `attempts`: one row per PATCH. |
| How do I see a real run? | Execution view in Dynatrace, or the Automation API calls in `51.sh`. |

## Summary

Every task is one JavaScript file with a `default` function (called "main" below). Main reads the event or earlier results, calls helper functions, and returns JSON. Only a few helpers touch the network. This doc lists every function, draws who-calls-whom, numbers every API call in run order with its exact URL, and shows how to pull the real traces from Dynatrace, SILVA and PagerDuty.

Line numbers refer to:

- OPEN: `36-standard-flow-preview-then-post/36-standard-flow-preview-then-post.workflow.yaml`
- CLOSE: `45-close-direct-v5-trigger-closed/45-close-direct-v5-trigger-closed.workflow.yaml`

---

## 1. SDK and built-in functions used

| Function | From | What it does | Used in |
|---|---|---|---|
| `execution(executionId)` | `@dynatrace-sdk/automation-utils` | Opens the current workflow run. | Every task |
| `ex.event()` | same | Returns the trigger event (empty object on manual Run). | OPEN 1, CLOSE 1 |
| `ex.result("task")` | same | Returns another task's return value. | Every task after the first |
| `problemsClient.getProblem({ problemId })` | `@dynatrace-sdk/client-classic-environment-v2` | Calls the Problems API v2 (`GET /api/v2/problems/{id}`). | OPEN 1, CLOSE 1 |
| `getEnvironmentUrl()` | `@dynatrace-sdk/app-environment` | Returns your environment URL. | OPEN 1, CLOSE 1 |
| `fetch(url, options)` | JavaScript runtime | Makes HTTP calls to SILVA and PagerDuty. | OPEN 2, 4a, 5a, 5b; CLOSE 2a, 2b |
| `Buffer.from(...).toString("base64")` | runtime | Builds the Basic auth header. | Every SILVA task |
| `encodeURIComponent` | runtime | Makes the SILVA query safe in a URL. | `getRows`, 4a, 5a |
| `JSON.parse`, `JSON.stringify` | runtime | Reads and writes JSON bodies; also deep-copies bodies. | Many |
| `console.log` | runtime | Writes to the task log. | OPEN 3, 4a, 4b, 5a; CLOSE 2a |
| `throw new Error(...)` | runtime | Turns the task red with a message. | OPEN 5a, 5b; CLOSE 2a, 2b |

---

## 2. Function inventory

### OPEN task 1 `extract-event-tags`

| Function | Lines | Input | Output | Network |
|---|---|---|---|---|
| `asList(v)` | 126 to 130 | value, array or comma text | clean list of strings | No |
| `unique(a)` | 131 | list | list without duplicates | No |
| `fmt(v)` | 132 to 134 | any value | printable text | No |
| `parseTag(raw)` | 136 to 141 | tag text like `[Kubernetes]app:x` | `{raw, key, value}` | No |
| `keyMatches(key, test)` | 143 to 146 | tag key and a test | true if key or its `_` form passes | No |
| `findByKey(parsed, test)` | 147 to 150 | parsed tags and a test | first `{key, value}` or null | No |
| `allByKey(parsed, tests)` | 151 to 161 | parsed tags and tests in priority order | list of `{key, value}` | No |
| `envLabel(value)` | 163 to 168 | text like `PRE` or a namespace | SILVA label or "" | No |
| main | 170 to 310 | executionId | `dynatrace_alert`, `snow_inputs`, tags, event fields | Yes: `getProblem` |

### OPEN task 2 `resolve-snow-values`

| Function | Lines | Input | Output | Network |
|---|---|---|---|---|
| `getRows(label, table, query, fields, limit)` | 371 to 388 | label, table, encoded query | `{status, rows, error}`; also pushes to `steps` | Yes: SILVA GET |
| `dv(row, f)` | 390 | row and field | display name | No |
| `val(row, f)` | 391 | row and field | stored value (sys_id) | No |
| `active(rows)` | 392 | rows | first operational row, else first row | No |
| `isSysId(v)` | 393 | text | true if 32 hex chars | No |
| `has(text, word)` | 394 | text and word | true if text contains word (any case) | No |
| `groupByName(label, name)` | 396 to 402 | group name | `{name, sys_id, company}` or null | Yes, via `getRows` on `sys_user_group` |
| `serviceByName(label, name)` | 403 to 406 | service name | service row or null | Yes, `cmdb_ci_service` |
| `serviceById(id)` | 407 to 410 | sys_id | service row or null | Yes, `cmdb_ci_service` |
| `findCis(host, names, domains)` | 411 to 430 | host, names, domains | up to 4 CI rows | Yes, `cmdb_ci` |
| `servicesForCi(ci)` | 432 to 444 | CI row | list of `{id, via}` | Yes, `svc_ci_assoc` and `cmdb_rel_ci` |
| `score(row, t)` | 445 to 458 | service row and search terms | `{score, reasons}` | No |
| `fromMap(map)` | 467 (inside main) | `SERVICE_MAP` or `GROUP_MAP` | mapped name or "" | No |
| `envMatch(rows)` | 641 to 642 (inside main) | offering rows | offering for the environment | No |
| main | 460 to 763 | task 1 result | `snow_required`, enrichment, candidates, `steps` | Yes, through the helpers |

### OPEN task 3 `build-payload`

| Function | Lines | Input | Output | Network |
|---|---|---|---|---|
| main | 800 to 922 | task 1 and task 2 results | `decision`, `snow_incident_payload`, `pagerduty_payload`, `field_sources` | No |

### OPEN task 4a `preview-silva-incident`

| Function | Lines | Input | Output | Network |
|---|---|---|---|---|
| `isSysId(v)` | 951 | value | true if sys_id | No |
| main | 973 to 1031 | task 3 result | `ready`, `problems`, `field_check`, `duplicate_check` | Yes: one SILVA GET |

### OPEN task 4b `preview-pagerduty`

| Function | Lines | Input | Output | Network |
|---|---|---|---|---|
| main | 1050 to 1078 | task 3 result | `ready`, `checks`, masked body | No |

### OPEN task 5a `post-silva-incident`

| Function | Lines | Input | Output | Network |
|---|---|---|---|---|
| `dv(row, f)` | 1110 | row and field | display name | No |
| main | 1112 to 1180 | task 3 and 4a results | `created`, `exists`, `skipped` or `dry_run` | Yes: SILVA GET and POST |

### OPEN task 5b `trigger-pagerduty`

| Function | Lines | Input | Output | Network |
|---|---|---|---|---|
| main | 1208 to 1248 | task 3 and 4b results | `triggered`, `skipped` or `dry_run` | Yes: PagerDuty POST |

### CLOSE task 1 `prepare-close`

| Function | Lines | Input | Output | Network |
|---|---|---|---|---|
| `first(v)` | 87 | value or array | first item | No |
| `toMs(v)` | 88 to 94 | number, nanoseconds or date text | milliseconds | No |
| `duration(ms)` | 95 to 99 | milliseconds | "42 min" or "2 h 5 min" | No |
| main | 101 to 150 | executionId | `is_closed`, `correlation_id`, `dedup_key`, times, cause | Yes: `getProblem` |

### CLOSE task 2a `close-silva-incident`

| Function | Lines | Input | Output | Network |
|---|---|---|---|---|
| `val(row, f)` | 196 | row and field | stored value | No |
| `dv(row, f)` | 197 | row and field | display name | No |
| `getRows(table, query, fields, limit)` | 199 to 210 | table and query | rows; throws on HTTP error | Yes: SILVA GET |
| `choiceValue(element, wanted)` | 212 to 227 | field and wanted label | `{value, check}`; throws if not a choice | Yes, `sys_choice` |
| `softChoice(element, wanted, fallback)` | 229 to 232 | same | `{value, check}`; never throws | Yes, via `choiceValue` |
| `patch(sysId, body)` | 233 to 252 | incident sys_id and body | `{http, ok, state, incident_state ...}` | Yes: SILVA PATCH |
| `stateBody(target)` | 266 to 270 (inside main) | Resolved or In Progress target | `{state, incident_state}` | No |
| `isResolved(s, inc)` | 278 to 279 (inside main) | two state values | true if either is Resolved | No |
| main | 254 to 364 | task 1 result | `resolved`, `skipped`, `dry_run`; throws if any failed | Yes, through the helpers |

### CLOSE task 2b `close-pagerduty`

| Function | Lines | Input | Output | Network |
|---|---|---|---|---|
| main | 390 to 426 | task 1 result | `resolved`, `skipped` or `dry_run` | Yes: PagerDuty POST |

---

## 3. Call graphs (who calls whom)

### OPEN task 1

```
main
 ├─ execution(executionId) → ex.event()
 ├─ getEnvironmentUrl()
 ├─ problemsClient.getProblem()            [API: Dynatrace]
 ├─ parseTag() for every tag
 ├─ allByKey() → keyMatches()              group tags, environment tags
 ├─ findByKey() → keyMatches()             service, app code, db, domain, trigram, region, host, maintenance
 ├─ envLabel()                             environment label
 ├─ asList(), unique()                     event fields
 └─ fmt()                                  event_properties
```

### OPEN task 2

```
main
 ├─ ex.result("extract-event-tags")
 ├─ fromMap(GROUP_MAP) → groupByName() → getRows(sys_user_group)        [API]
 ├─ for each group tag → groupByName() → getRows(sys_user_group)       [API]
 ├─ fromMap(SERVICE_MAP) or tag → serviceByName() → getRows(cmdb_ci_service) → active()   [API]
 ├─ findCis() → getRows(cmdb_ci) x n → active()                        [API]
 ├─ if no service:
 │    servicesForCi() → getRows(svc_ci_assoc), getRows(cmdb_rel_ci)  [API]
 │    serviceById() → getRows(cmdb_ci_service)                       [API]
 ├─ if no service: searches → getRows(cmdb_ci_service) → score() → has()   [API]
 ├─ if no service: first answer → getRows(cmdb_ci_service)            [API]
 ├─ if no service: serviceByName(DEFAULT_BUSINESS_SERVICE)            [API]
 ├─ offering switch → getRows(service_offering) → serviceById()       [API]
 ├─ offering parent → serviceById()                                   [API]
 ├─ GROUP_ORDER → groupByName(DEFAULT_GROUP) only if needed           [API]
 ├─ getRows(service_offering parent=) → envMatch()                    [API]
 ├─ history → getRows(incident) → getRows(service_offering) → serviceById()   [API]
 └─ fallbacks → getRows(service_offering) → envMatch()                [API]
```

### OPEN tasks 3 to 5

```
build-payload main  → ex.result x2 → builds bodies (no API)
preview-silva main  → ex.result → isSysId() → fetch GET incident           [API]
preview-pd main     → ex.result → checks (no API)
post-silva main     → ex.result x2 → fetch GET incident → fetch POST incident → dv()   [API]
trigger-pd main     → ex.result x2 → fetch POST /v2/enqueue                [API]
```

### CLOSE

```
prepare-close main → ex.event() → getEnvironmentUrl() → getProblem() [API] → toMs() → duration() → first()
close-silva main   → ex.result
                   → choiceValue(state), choiceValue(close_code)                 → getRows(sys_choice) [API]
                   → softChoice(state), softChoice(incident_state) x2 → choiceValue → getRows(sys_choice) [API]
                   → getRows(incident by correlation_id)                          [API]
                   → isResolved() filter
                   → per incident: patch(Resolved) [API] → isResolved()
                                   if needed: patch(In Progress) [API] → patch(Resolved) [API]
close-pd main      → ex.result → fetch POST /v2/enqueue                           [API]
```

---

## 4. API call traces in run order

`{SN}` = `https://silvastg.service-now.com/api/now/v2/table`. All SILVA GETs also carry `sysparm_fields`, `sysparm_display_value=all`, `sysparm_exclude_reference_link=true`, `sysparm_limit`.

### OPEN trace

| # | Task | Function | Method and URL | Runs when | Answer used for |
|---|---|---|---|---|---|
| 1 | 1 | `getProblem` | `GET /api/v2/problems/{event.id}` (SDK) | Real event and `USE_PROBLEM_API` | tags, root cause, evidence, severity |
| 2 | 2 | `groupByName` | `GET {SN}/sys_user_group?sysparm_query=name=<GROUP_MAP value>^active=true` | `GROUP_MAP` has the app code | tag group |
| 3 | 2 | `groupByName` | `GET {SN}/sys_user_group?...name=<tag value>^active=true` | once per group tag until one exists | tag group |
| 4 | 2 | `serviceByName` | `GET {SN}/cmdb_ci_service?...name=<svc>^sys_class_name!=service_offering` | `SERVICE_MAP` or service tag set | business service |
| 5 | 2 | `findCis` | `GET {SN}/cmdb_ci?...name=ts12^ORname=ts12.hk.intraxa^ORfqdn=...` | host known | host CI |
| 6 | 2 | `findCis` | `GET {SN}/cmdb_ci?...nameSTARTSWITHts12.^ORfqdnSTARTSWITHts12.` | call 5 found nothing | host CI |
| 7 | 2 | `findCis` | `GET {SN}/cmdb_ci?...name=<n>`, then `nameLIKE<n>` | once per CI name | more CIs |
| 8 | 2 | `servicesForCi` | `GET {SN}/svc_ci_assoc?...ci_id=<ci>` | no service yet; per CI | service ids |
| 9 | 2 | `servicesForCi` | `GET {SN}/cmdb_rel_ci?...child=<ci>` | same | parent service ids |
| 10 | 2 | `serviceById` | `GET {SN}/cmdb_ci_service?...sys_id=<id>` | per linked service until one loads | business service |
| 11 | 2 | `getRows` | `GET {SN}/cmdb_ci_service?...nameLIKE<app>` and other searches | still no service | scored candidates |
| 12 | 2 | `getRows` | `GET {SN}/cmdb_ci_service?...assignment_group.nameLIKE<group>` and others | still no service | first answer |
| 13 | 2 | `serviceByName` | `GET {SN}/cmdb_ci_service?...name=QA Platforms^...` | still no service | default service |
| 14 | 2 | `getRows` | `GET {SN}/service_offering?...parent=<service>` | more than one CI service | does it have offerings? |
| 15 | 2 | `groupByName` | `GET {SN}/sys_user_group?...name=Ops_Middleware_Monitoring_AXAJP` | no earlier group source | default group |
| 16 | 2 | `getRows` | `GET {SN}/service_offering?...parent=<service>` | service found | offering for environment |
| 17 | 2 | `getRows` | `GET {SN}/incident?...u_configuration_item=<ci>^cmdb_ciISNOTEMPTY^ORDERBYDESCsys_created_on` (20) | no offering yet, CI found | most used offering |
| 18 | 2 | `getRows` | `GET {SN}/service_offering?...sys_id=<best>` | call 17 found one | offering record |
| 19 | 2 | `serviceById` | `GET {SN}/cmdb_ci_service?...sys_id=<offering parent>` | parent differs from service | replace business service |
| 20 | 2 | `getRows` | `GET {SN}/service_offering?...nameSTARTSWITHQA Platforms - AXA GROUP OPERATIONS` | default set only | default offering |
| 21 | 2 | `getRows` | `GET {SN}/service_offering?...assignment_group=<g>^ORsupport_group=<g>` | still no offering | offering by group |
| 22 | 4a | main `fetch` | `GET {SN}/incident?sysparm_query=correlation_id=P-261090^active=true&sysparm_fields=number,state,assignment_group&sysparm_display_value=true&sysparm_limit=1` | body has correlation_id | duplicate preview |
| 23 | 5a | main `fetch` | same GET as 22 (with sys_id) | all gates passed | stop if exists |
| 24 | 5a | main `fetch` | `POST {SN}/incident?sysparm_display_value=all&sysparm_exclude_reference_link=true` with JSON body | no duplicate, not DRY_RUN | number, sys_id |
| 25 | 5b | main `fetch` | `POST https://events.pagerduty.com/v2/enqueue` with trigger body | gates passed, not DRY_RUN | status, dedup_key |

Typical server problem like P-261090: 1, then 5, 8, 9, 10, 16, 17, 18, 19 (or some of them), then 22, 23, 24 and 25. Exactly which ran is listed in task 2's `steps` output. The list here is from the code, not a captured log.

### CLOSE trace

| # | Task | Function | Method and URL | Runs when | Answer used for |
|---|---|---|---|---|---|
| 1 | 1 | `getProblem` | `GET /api/v2/problems/{event.id}` (SDK) | real event | status, start, end, title, root cause |
| 2 | 2a | `choiceValue` | `GET {SN}/sys_choice?...name=incident^element=state^inactive=false^language=en` | is_closed | Resolved value |
| 3 | 2a | `choiceValue` | `GET {SN}/sys_choice?...element=close_code...` | always after 2 | close code value |
| 4 | 2a | `softChoice` | `GET {SN}/sys_choice?...element=state...` | always | In Progress value |
| 5 | 2a | `softChoice` | `GET {SN}/sys_choice?...element=incident_state...` | always | incident_state Resolved |
| 6 | 2a | `softChoice` | `GET {SN}/sys_choice?...element=incident_state...` | always | incident_state In Progress |
| 7 | 2a | `getRows` | `GET {SN}/incident?...correlation_id=P-261090^active=true^ORDERBYDESCsys_created_on` (5) | always | incidents to resolve |
| 8 | 2a | `patch` | `PATCH {SN}/incident/{sys_id}?sysparm_display_value=all&sysparm_exclude_reference_link=true` | per open incident, not DRY_RUN | new state |
| 9 | 2a | `patch` | `PATCH ...` In Progress | call 8 did not resolve | |
| 10 | 2a | `patch` | `PATCH ...` Resolved again | after 9 | final state |
| 11 | 2b | main `fetch` | `POST https://events.pagerduty.com/v2/enqueue` with `event_action: resolve` | is_closed, has id, not sample, not DRY_RUN | status |

Tasks 2a and 2b start at the same time, so call 11 can happen before or between calls 2 to 10.

---

## 5. Data handoff between tasks (field level)

### OPEN

```
trigger event
  └─► task 1 main
        reads: event.id, display_id, event.name, event.description, entity_tags,
               root_cause_entity_name, affected_entity_*, dt.security_context,
               maintenance.is_under_maintenance, labels.alerting_profile
        returns:
          usedSample ─────────────────────────────────────────► task 3
          dynatrace_alert {service_name, event_name, problem_id, problem_url,
                           host, hosts, entity_id, severity, impact_level,
                           error_rate, app_code, trigram, db_type, maintenance} ─► task 3
          snow_inputs {group_candidates, service_tag, environment, app_code,
                       db_type, domain, trigram, region, host,
                       db_or_entity_names} ───────────────────► task 2
          tags.raw, dt_environment_id ─────────────────────────► task 3
  └─► task 2 main
        returns:
          snow_required {assignment_group, business_service, service_offering,
                         cmdb_ci, company, environment, default_set_used} ─► task 3
          servicenow_enrichment {sys_id, company_id, match_method ...}  ─► task 3
          steps, candidates, cis_found, offering_history ─► you (debug)
  └─► task 3 main
        returns:
          decision {create_incident, reason} ─► 4a, 4b, 5a, 5b
          used_sample_event ─────────────────► 4a, 4b, 5a, 5b
          snow_incident_payload ─────────────► 4a, 5a
          pagerduty_payload ─────────────────► 4b, 5b
          field_sources ─────────────────────► 4a
  └─► 4a returns ready, problems ─► 5a
  └─► 4b returns ready, checks   ─► 5b
  └─► 5a returns number, sys_id, url
  └─► 5b returns status, dedup_key
```

### CLOSE

```
trigger event
  └─► task 1 main
        reads: event.id, display_id, event.status, event.status_transition,
               event.start, event.end, event.name, root_cause_entity_name
        returns:
          is_closed, closed_check ──────────────► 2a, 2b
          correlation_id, problem_id ───────────► 2a
          dedup_key ────────────────────────────► 2a (in work note), 2b
          title, where, start_time, end_time,
          duration, problem_url ────────────────► 2a (notes)
          used_sample_event ────────────────────► 2a, 2b
  └─► 2a returns incidents[] {number, action, state_after, worked_with, attempts[]}
  └─► 2b returns status, dedup_key
```

---

## 6. How to pull the real traces after a run

| Where | How | What you get |
|---|---|---|
| Dynatrace UI | Workflows, open the workflow, Executions, pick a run, click a task, open Result and Log. | Return JSON and `console.log` output per task. |
| Dynatrace Automation API | `GET /platform/automation/v1/executions?workflow=<id>`, then `.../executions/<id>/tasks`, then `.../tasks/<name>/result` and `.../log` (see `51.sh`). | Same data, scriptable. Needs a platform token with automation read scope. |
| OPEN task 2 `steps` | In task 2's result. | Every SILVA GET: step, table, query, HTTP status, matches, error. |
| CLOSE 2a `attempts` | In 2a's result, per incident. | Each PATCH: step, HTTP status, state after, incident_state after. |
| SILVA audit | `sys_audit` where `tablename=incident^documentkey=<sys_id>`. | Every field change with old and new value and who made it. |
| SILVA notes | `sys_journal_field` where `element_id=<sys_id>`. | Work notes and comments text. |
| SILVA Activities tab | Open the incident. | Human view of the same history. |
| PagerDuty | Incident page, Timeline; or REST `GET https://api.pagerduty.com/incidents/<id>/log_entries`. | Trigger and resolve events. REST needs an API key, not the routing key. |

Exact Automation API paths can differ by version. Check the API explorer in your environment if a path returns 404.

---

## Investigation

| What I checked | Where |
|---|---|
| Every function definition and its line range | Both workflow YAMLs |
| Every `fetch`, `getRows`, `patch`, `getProblem` call | Same |
| Which return fields each later task reads | Every `ex.result(...)` and the fields used after it |

## Result

| You want | Go to |
|---|---|
| Function list | Section 2 |
| Who calls whom | Section 3 |
| Every API call in order | Section 4 |
| Field-level handoff | Section 5 |
| Real run traces | Section 6 and `51.sh` |

## Data flow map

```
Dynatrace event ─► OPEN1 (getProblem) ─► OPEN2 (getRows x N on SILVA) ─► OPEN3 (bodies)
   ─► OPEN4a (GET dup) ─► OPEN5a (GET dup, POST incident) ─► SILVA INC (correlation_id)
   ─► OPEN4b (checks)  ─► OPEN5b (POST enqueue trigger)   ─► PagerDuty (dedup_key)

Dynatrace close ─► CLOSE1 (getProblem)
   ─► CLOSE2a (GET sys_choice x5, GET incident, PATCH x1..3) ─► SILVA INC Resolved
   ─► CLOSE2b (POST enqueue resolve)                          ─► PagerDuty resolved
```

## Related files

| File | What it is |
|---|---|
| `46-open-close-workflows-line-by-line/` | Line-by-line walkthrough |
| `47-open-close-e2e-api-data-flow/` | E2E with request and response bodies |
| `50-silva-cmdb-ci-sysid-explained/` | What each SILVA object means |
| `51.sh` | Pull real traces: Automation API, SILVA audit, PagerDuty |

## Commands

See [`51.sh`](51.sh).
