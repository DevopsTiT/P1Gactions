# Extract Workflow Flow Logic

## Decision tree

```
START
 │
 ├─ Trigger: DAVIS_PROBLEM + ACTIVE + CREATED ?  ── no ──► workflow does not run
 │        yes (or you pressed Run)
 ▼
TASK 1 extract-event-tags
 │ event has event.kind or event.id ?
 │    no  → use SAMPLE_EVENT (test mode), skip Problems API
 │    yes → use the real event
 │           USE_PROBLEM_API on and event.id present ?
 │              yes → getProblem → ok, or "failed: ..." (keep going)
 │              no  → skip
 │ collect tags: entity_tags + problem entityTags (no duplicates)
 │ parse each tag: remove [Context] → split at first ":" → key / value
 │ sort into tags.ago (AGO_*) and tags.other
 │ find hints by key name (first match wins)
 │ build dynatrace_alert (first non-empty source per field)
 │ return result ──► task 1 OK
 ▼
TASK 2 lookup-silva   (runs only if task 1 is OK)
 │ ENABLED ?  no → return found:false "disabled" ─────────────────────┐
 │ yes                                                                  │
 │ STEP A  business service tag? or SERVICE_MAP[trigram]?               │
 │    yes → GET cmdb_ci_service name=X                                  │
 │           rows? → pick operational (status 1) or first → FOUND (A)   │
 │           none  → go to STEP B                                       │
 │    no  → go to STEP B                                                │
 │ STEP B  (only if not found)                                          │
 │    for each name in: host tag, host fields, affected entity names   │
 │       GET cmdb_ci name / short name / fqdn                           │
 │       rows? → pick installed (status 1) or first → stop loop         │
 │    CI found?                                                         │
 │       yes → GET svc_ci_assoc ci_id=CI                                │
 │              service_id? → GET cmdb_ci_service sys_id → FOUND (B)    │
 │              none        → NOT FOUND                                 │
 │       no  → NOT FOUND                                                │
 │ STEP C  group tag present?                                           │
 │    yes → GET sys_user_group name=G → exists / sys_id / active        │
 │    no  → tag_assignment_group = null                                 │
 │ FOUND     → servicenow_enrichment = 17 fields from the service       │
 │ NOT FOUND → servicenow_enrichment = { found:false, reason }          │
 │ return result + steps (every GET: status, matches, error) ──► OK    │
 ▼                                                                      │
TASK 3 display-result   (runs only if task 2 is OK) ◄──────────────────┘
 │ combine: dynatrace_alert + servicenow_enrichment + routing + tags + lookup
 │ console.log(pretty JSON) → Log tab
 │ return the same JSON → Result tab
END   (nothing is written to SILVA, nothing is sent to PagerDuty)
```

## Short takeaway

| Question | Answer |
|---|---|
| How many tasks? | Three, one after the other: extract, then lookup, then display |
| What happens if the Problems API fails? | Task 1 keeps going with the event data only. `problem_api` shows the error. |
| What happens if SILVA finds nothing? | Task 2 still succeeds, with `found: false`. `steps` shows why. |
| What happens if SILVA is unreachable? | Each GET records status 0 and the error. The result is `found: false`. |
| When does a task fail outright? | Only on a script error. Then the next task does not run, because each one waits for the previous task to be OK. |
| Does anything get written? | No. There are only GET calls to SILVA and no PagerDuty calls. |

## Summary

The workflow is a straight line of three tasks. Task 1 turns the raw event into clean tags, hints and alert fields. Task 2 uses the hints to find one business service in SILVA: by name first, then through the host. Task 3 prints the combined result. Every lookup is "first match wins", and every SILVA call is recorded in `steps` so you can see why something was or was not found.

## Task 1 logic in detail

### Step 1.1: choose the event

| Condition | Event used | Problems API |
|---|---|---|
| Real trigger (the event has `event.kind` or `event.id`) | The real event | Called if `USE_PROBLEM_API = true` |
| Started with Run (empty event) | `SAMPLE_EVENT` | Skipped |

### Step 1.2: collect and parse the tags

| Order | Source |
|---|---|
| 1 | Event `entity_tags` |
| 2 | Problem `entityTags` (`stringRepresentation`), added only if not already in the list |

Parsing rule for each tag:

| Input | Step | Output |
|---|---|---|
| `[Environment]AGO_AXA_SUPPORTGROUP:X` | Remove `[Environment]` and keep it as the context | `AGO_AXA_SUPPORTGROUP:X` |
| `AGO_AXA_SUPPORTGROUP:X` | Split at the first `:` | key `AGO_AXA_SUPPORTGROUP`, value `X` |
| `AGO_DB` (no colon) | Whole text is the key | key `AGO_DB`, value empty |
| Same key twice | Values collected into a list | `["A", "B"]` |

### Step 1.3: find the hints (first match wins)

| Hint | Checks, in order |
|---|---|
| assignment_group | 1. key = `ago_axa_supportgroup` 2. key = `ago_default_assignment_group` 3. key ends with `assignment_group` or `supportgroup` |
| business_service | key is one of `snow-service`, `ago_axa_businessservice`, `business-service`, `u_business_service` |
| environment | 1. key = `ago_axaenvironmentname` 2. key contains `environment` 3. key = `env` |
| trigram | key contains `trigram` |
| platform | key contains `platform` |
| region | key contains `region` |
| maintenance | key contains `maintenance` |
| host | key = `host` |

Keys are compared in lower case, and a tag with an empty value is skipped.

### Step 1.4: build dynatrace_alert (first non-empty value wins)

| Field | Order of sources |
|---|---|
| service_name | root cause name, then affected entity names, then the entity-type field values, then problem affected entities, then host tag, then affected entity id |
| alerting_profile | `labels.alerting_profile` |
| severity | `event.severity`, then `event.category`, then problem `severityLevel` |
| event_name | `event.name`, then problem title |
| error_rate | evidence property with "failure rate" or "error rate", then an event field with that name. A plain number becomes `xx.xx%`. |
| problem_id | `display_id`, then problem `displayId` |
| impact_level | `dt.davis.impact_level`, then problem `impactLevel` |

### Step 1.5: candidates handed to task 2

| Output | Content |
|---|---|
| hostCandidates | host tag value, `host.name`, `dt.entity.host.name` |
| ciCandidates | all affected entity names, plus the root cause name |

## Task 2 logic in detail

### Step A: service by name

| Condition | Action |
|---|---|
| A business service tag exists | Name = the tag value |
| No tag, but the trigram or service tag value is in `SERVICE_MAP` | Name = the map value |
| Neither | Skip to Step B |
| GET `cmdb_ci_service name=<name>` returns rows | Pick the row with operational_status 1, else the first. Method = tag or SERVICE_MAP. |
| Returns no rows | Go to Step B |

### Step B: service through the CI

| Order | Action |
|---|---|
| 1 | Loop through hostCandidates, then ciCandidates |
| 2 | For each name, GET `cmdb_ci` where name = lower case, or name = original, or name = short name, or fqdn = lower case |
| 3 | First name with rows wins. Pick install_status 1, else the first row. |
| 4 | GET `svc_ci_assoc ci_id=<CI sys_id>`, take the first service_id |
| 5 | GET `cmdb_ci_service sys_id=<service_id>`. Method = "CI name -> svc_ci_assoc". |

### Step C: group check

| Condition | Result |
|---|---|
| assignment_group hint exists | GET `sys_user_group name=<value>`, returns from_tag, name, sys_id, exists_in_silva, active |
| No hint | `tag_assignment_group = null` |

### Result of task 2

| Case | servicenow_enrichment | found | method |
|---|---|---|---|
| Found in Step A | 17 fields from the service | true | tag name or SERVICE_MAP |
| Found in Step B | 17 fields from the service | true | CI name -> svc_ci_assoc |
| Not found | found false, reason | false | (empty) |
| ENABLED false | (none) | false | reason "disabled" |

## Task 3 logic

| Output block | Filled from |
|---|---|
| dynatrace_alert | Task 1 |
| servicenow_enrichment | Task 2 |
| routing.assignment_group_from_tag | Task 2 Step C |
| routing.configuration_item | Task 2 Step B (null if not used) |
| routing.environment_tag / trigram_tag / maintenance_tag | Task 1 hints |
| tags (count, ago, other, raw) | Task 1 |
| lookup (found, method, steps, used_sample_event, problem_api) | Tasks 1 and 2 |

## Walkthrough with your Oracle event

| Step | What happens |
|---|---|
| 1.1 | Run pressed, so SAMPLE_EVENT is used and the Problems API is skipped |
| 1.2 | 13 tags parsed. None has a `[Context]` prefix. |
| 1.3 | assignment_group = Database_AXAJP (`AGO_DEFAULT_ASSIGNMENT_GROUP`), trigram = ALJ, environment = ACCEPTANCE, host = deaa310b |
| 1.4 | service_name = `CUSTOM_DEVICE-C782F52B95F89F6F` (no names in the event), severity 3, profile Default |
| A | No business service tag, and SERVICE_MAP is empty, so skip |
| B | GET cmdb_ci for `deaa310b`. If found, go to svc_ci_assoc and then the service. If not found, the result is NOT FOUND. |
| C | GET sys_user_group `Database_AXAJP` |
| 3 | Print the JSON. If not found, add `ALJ: "<service name>"` to SERVICE_MAP and run again. |

## How to read steps when something is missing

| steps shows | Meaning | Fix |
|---|---|---|
| No "service by name" step | No service tag and no SERVICE_MAP hit | Add the trigram to SERVICE_MAP |
| "service by name" with matches 0 | The name is not exact in SILVA | Copy the exact name from SILVA |
| "ci by name" with matches 0 for every name | Host or entity not in the CMDB | Use SERVICE_MAP, or ask for the CI to be added |
| "svc_ci_assoc" with matches 0 | CI exists but has no service link | SERVICE_MAP, or a CMDB fix |
| Any status 401 | Wrong password | Fix PASSWORD |
| Any status 403 | No read access | Ask the SILVA admin |
| status 0 with an error | Not on the allowlist, or a network error | Add silvastg.service-now.com to External requests |

## Data flow map

```
event ─(1.1)─► event or SAMPLE_EVENT
          └─(1.1)─► getProblem? ─► extra tags, title, evidence
                          ▼
   (1.2) raw tags ─► parse ─► tags.ago / tags.other
   (1.3)               └──► hints ──────────────┐
   (1.4) fields ──► dynatrace_alert ──────┐     │
                                           │     ▼
                      TASK 2  A: service tag / SERVICE_MAP ─► cmdb_ci_service
                              B: host / entity ─► cmdb_ci ─► svc_ci_assoc ─► cmdb_ci_service
                              C: group tag ─► sys_user_group
                                           │     │
                                           ▼     ▼
                      TASK 3  { dynatrace_alert, servicenow_enrichment, routing, tags, lookup }
                              ─► Log tab + Result tab
```

## Related files

| File | Purpose |
|---|---|
| `../1-extract-tags-silva-enrichment/1-extract-tags-silva-enrichment.workflow.yaml` | The workflow this logic describes |
| `../1-extract-tags-silva-enrichment/1.sh` | Same SILVA GETs as curl commands |
| `2.sh` | Pointer commands (not run) |

## Commands

See `2.sh`. They are the same checks as task 2 Step B for the sample host.
