# OPEN And CLOSE Workflow Data Flow

## Decision tree

```
Dynatrace problem event arrives
 │
 ├─ status ACTIVE (CREATED / UPDATED / REOPENED)  → OPEN workflow
 │    1 prepare-payload
 │       a read the trigger event itself (tags, security context, affected entities)   no API
 │       b Problems API getProblem(event.id)  → title, severity, root cause, evidence, zones
 │       c root-cause evidence event          → description, event properties, metric
 │       d Entities API getEntity(root → host) → host name, IP, entity tags
 │       e decide: host, severity, system, environment, business service, group
 │       f build short description + "Additional Information" JSON + notes
 │    2 post-silva-incident-http   (after 1 is OK)
 │       look up CI in cmdb_ci → POST incident → PATCH anything still blank
 │    2 trigger-pagerduty          (after 1 is OK, runs in parallel)
 │       POST trigger with dedup_key dt-problem-<display_id>
 │
 └─ status CLOSED / RESOLVED  → CLOSE workflow
      1 prepare-close-ids
         same display_id → correlationId + dedupKey, build close notes
      2 resolve-silva-incident-http
         GET incident where correlation_id = display_id → PATCH state 6 Resolved
      2 resolve-pagerduty
         POST resolve with the same dedup_key
```

## Short takeaway

| Question | Answer |
|---|---|
| What starts OPEN? | A Davis problem event with status ACTIVE (created, updated or reopened) |
| What starts CLOSE? | A Davis problem event with status CLOSED or transition RESOLVED or CLOSED |
| How many tasks are there? | Three in each workflow: one "prepare" task, then SILVA and PagerDuty in parallel |
| Where does the metadata come from? | Four layers: the trigger event, the Problems API, the root-cause evidence event, and the Entities API |
| What links OPEN and CLOSE? | The problem display id (for example P-2609123). It is the SILVA `correlation_id` and part of the PagerDuty `dedup_key`. |
| Does CLOSE re-derive group and service? | No. It only finds the incident and resolves it. The business service it computes is used in the notes only. |

## Summary

OPEN reads everything Dynatrace knows about the problem in four layers, from cheapest to richest. It decides the host, environment, group and business service with a fixed "first source that has a value wins" order, builds a ticket that looks like the classic integration ticket, and sends it to SILVA and PagerDuty at the same time. CLOSE rebuilds the same display id, uses it to find the incident, and resolves both SILVA and PagerDuty.

---

## Part 1: The OPEN workflow

### 1.1 Trigger

```yaml
filterQuery: event.kind == "DAVIS_PROBLEM" AND event.status == "ACTIVE" AND
  (event.status_transition == "CREATED" OR "UPDATED" OR "REOPENED")
categories: error, resource, slowdown, availability   # all problem types
entityTags: {}                                         # no tag filter, every problem
```

| Setting | What it means |
|---|---|
| `event.kind == "DAVIS_PROBLEM"` | Only Davis AI problems, not raw events |
| `event.status == "ACTIVE"` | The problem is still open |
| `CREATED` | A new problem. This is the case you want. |
| `UPDATED` | The same problem changed (for example, a new affected entity). **This also runs OPEN again and can create a second incident.** |
| `REOPENED` | A closed problem came back |
| `entityTags: {}` | No filter, so every problem in the environment triggers it |

### 1.2 Task 1: `prepare-payload` (all extraction happens here)

This task makes no SILVA calls. It only reads Dynatrace data and returns one object that the next two tasks use.

#### Layer A: the trigger event itself (`readEventMeta`)

The event arrives with the trigger, so reading it costs nothing. `ex.event()` returns it as a flat object.

| Event field | What the code does with it | Result |
|---|---|---|
| `entity_tags` | Removes the `[Context]` prefix, then splits on the first `:` into key and value | `tagList` (key and value) and `rawTags` (original strings for the JSON) |
| `dt.cost.product`, `dt.cost.costcenter`, `k8s.namespace.name`, `k8s.cluster.name` | Added as extra tags (`META_FIELDS`) | For example `dt.cost.product = COMPASSPROXY` |
| `affected_entity_types` and `affected_entity_names` | If a type contains "host", the names are treated as host names | Host candidates |
| `host.name`, `dt.entity.host.name` | Taken as host names | Host candidates |
| `dt.security.context` | Picks the most specific value (the one with the most `_` parts), then takes the last part | `contextEnv`, for example `tst` |
| `affected_entity_ids`, `root_cause_entity_id`, `root_cause_entity_name` | Kept as a backup for the root entity | Backup ids and names |
| All keys | Sorted list | `eventKeys`, for troubleshooting |

Tag parsing example:

```
"[Environment]AGO_AXA_SUPPORTGROUP:InfraSupport_Dist-WindowsHK_L2_ASIA"
   remove "[Environment]"  →  "AGO_AXA_SUPPORTGROUP:InfraSupport_Dist-WindowsHK_L2_ASIA"
   split at first ":"      →  key "AGO_AXA_SUPPORTGROUP", value "InfraSupport_Dist-WindowsHK_L2_ASIA"
```

`isHostName` rejects values with spaces, `*`, `,`, `[` or `]`, so pod names such as `[APP.TST] nginx pod-*` are not used as hosts.

#### Layer B: Problems API (`problemsClient.getProblem`)

The code calls it with `ev["event.id"]`. If it fails, the workflow keeps going with empty data, and `problemApi` records the error.

| Problem field | Used for |
|---|---|
| `title` | Problem title (backups: `event.name`, `problem.title`) |
| `displayId` | Backup for the display id (the event's `display_id` wins) |
| `problemId` | The internal id, written as `problem_id` in the JSON |
| `impactLevel` | Part of "OPEN APPLICATION Problem P-xxx: title" |
| `severityLevel` | Severity (backups: `event.category`, `problem.severity`, then ERROR) |
| `rootCauseEntity` | The root entity id and name. Also sets `isRootCause` to "true" or "false". |
| `affectedEntities[0]` | Used as the root entity when there is no root cause |
| `evidenceDetails.details` | The root-cause evidence event (Layer C) |
| `entityTags` | More tags |
| `managementZones` | The `managementZones` list in the JSON |

#### Layer C: the root-cause evidence event

This is the most detailed source. The code picks the first evidence item with `evidenceType == "EVENT"` and `rootCauseRelevant`. If there is none, it takes any EVENT item.

| Property | Used for |
|---|---|
| All `data.properties` | `event_properties` in the JSON, sorted by key like the classic ticket |
| `dt.event.description` | The headline, used in the short description and as the first line of the description |
| `dt.event.title` | `title` in the JSON |
| `dt.event.metric_selector` or `dt.event.metric_key` | `metricName` in the JSON |

#### Layer D: Entities API (`monitoredEntitiesClient.getEntity`)

| Step | What happens |
|---|---|
| 1 | Get the root entity by `rootId` |
| 2 | If its type is HOST, it is the host |
| 3 | Otherwise `firstHostId` searches `fromRelationships` for the first id starting with `HOST-` (for example a process runs on a host), then gets that host |
| 4 | From the host: `displayName` (host name) and `properties.ipAddress` (IP list) |
| 5 | From the root entity: `tags` and `managementZones` |

All tags are merged in this order: event tags, then problem tags, then entity tags. When the code looks up a tag key, the first match wins, so event tags have priority.

#### Step E: the decisions

**Host name** (first value found wins):

| Order | Source |
|---|---|
| 1 | Host entity `displayName` (Layer D) |
| 2 | Host names from the event (Layer A) |
| 3 | The `host` tag, plus `.` and the `AGO_DOMAIN` tag if the host has no domain |
| 4 | The text "on host X" in the description or title |

**Severity and priority:**

| Severity contains | PagerDuty severity | Impact and urgency (before the fixed values) |
|---|---|---|
| AVAILABILITY | critical | 1 and 1 |
| ERROR | error | 2 and 2 |
| CUSTOM or INFO | info | 4 and 4 |
| Anything else | warning | 3 and 3 |

`FIXED_IMPACT = "4"` and `FIXED_URGENCY = "4"` then override the SILVA values, so every ticket gets Priority 4 - Low. The PagerDuty severity still follows the table.

**System (`findSystem`):** the code collects candidate text from the `system`, `app` and `dt.cost.product` tags, the security context, the root-cause name and the affected entity names. It then looks for a `SYSTEM_MAP` key as a whole word. `EIP` matches `ALJ-EIP-01`, but it does not match `RECEIPT`.

**Environment** (first value found wins):

| Order | Source | Example |
|---|---|---|
| 1 | `SYSTEM_MAP[system].environment` | EIP always gives Production |
| 2 | Tag `AGO_AXAENVIRONMENTNAME`, then `env`, then `environment`, translated by the `ENVIRONMENT` map | Integration-Test becomes "Integration / Test" |
| 3 | The last part of the security context | `..._tst` becomes "Integration / Test" |
| 4 | `FIXED_ENVIRONMENT` | Development |

`toEnv` only returns labels from `SILVA_ENVIRONMENTS`. SILVA silently drops unknown labels, so an unknown value falls back to the default instead of being lost.

**Business service** (first value found wins):

| Order | Source | What `businessServiceSource` says |
|---|---|---|
| 1 | `SYSTEM_MAP[system].businessService` | map |
| 2 | Tag `snow-service`, `ago_axa_businessservice`, `business-service` or `u_business_service` | tag name |
| 3 | `BUSINESS_SERVICE` (uk-sap-fscd-dev) | default |

When the source is "default", the POST task does not send a business service. SILVA derives it from the CI (see 1.3).

**Service offering:**

| Case | Offering used |
|---|---|
| A system matched | The map's offering, else the offering tag, else blank |
| No system, but a business service tag was found | The offering tag, else blank (so no wrong default offering is paired with it) |
| No system and no tag | The offering tag, else `SERVICE_OFFERING` |

**Assignment group** (first value found wins):

| Order | Source |
|---|---|
| 0 | `TEST_ASSIGNMENT_GROUP`, if filled (testing only, overrides everything) |
| 1 | Tag `AGO_AXA_SUPPORTGROUP`, then `AGO_DEFAULT_ASSIGNMENT_GROUP`, `support-group`, `assignment-group` |
| 2 | `SYSTEM_MAP[system].l2Group` (tier L2) |
| 3 | `DEFAULT_GROUPS.L2` = Ops_Middleware_Monitoring_AXAJP |

`assigned_to` = "Shuge KUI" only when the group is the default L2 group, because SILVA rejects a person who is not a member of the group.

#### Step F: the ticket text

| Field | How it is built | Example |
|---|---|---|
| Short description | `[DYNATRACE JAPAN][host] - headline`, cut at 160 characters | `[DYNATRACE JAPAN][TS12.hk.intraxa] - CPU saturation ...` |
| Description | headline + "Additional Information:" + the JSON, cut at 12,000 characters | Same layout as INC30339746 |
| comments (customer visible) | Cause, problem, entity, link | "=== Dynatrace alert P-xxx ===" |
| work_notes (internal) | Sync keys + the "Metadata used" block showing where each value came from | "Assignment group : X (tag ago_axa_supportgroup)" |

The Additional Information JSON:

| JSON key | Source |
|---|---|
| correlation_id | Root entity id (like the classic ticket), else the display id |
| discovered_name | Root entity name |
| dynatrace_severity | Severity |
| environmentId | The first part of the Dynatrace URL host name |
| environmentName | `DT_ENVIRONMENT_NAME` (AXA AS STG) |
| event_properties | Layer C properties, sorted |
| ip_addresses | Host IPs from Layer D |
| isRootCause | "true" only if the problem has a root cause entity |
| managementZones | Problem and entity zones, without duplicates |
| metricName | Metric selector or key |
| problemDescription | "OPEN impactLevel Problem displayId: title" |
| problem_displayId / problem_id | Display id and internal id |
| tags | Raw tag strings |
| title | `dt.event.title` (left out when empty) |
| u_business_service | The business service, or `<<UNKNOWN>>` when it is the default |
| u_external_url | Problem link |

The JSON is printed with `"key" : value` (space before the colon), like the classic integration.

### 1.3 Task 2a: `post-silva-incident-http`

Runs only if `prepare-payload` is OK. Every call is plain HTTP with Basic auth.

| Step | Call | Purpose |
|---|---|---|
| 1 | GET `cmdb_ci` where name = full host, or original host, or short name, or fqdn = full host (up to 5 rows, prefer install_status 1) | Get the host's sys_id |
| 2 | Decide `deriveFromCi` | True when LET_SILVA_DERIVE_SERVICE is on, the business service came from the default, and the CI was found |
| 3 | If not deriving: GET `cmdb_ci_service` and `service_offering` by name (prefer operational_status 1) | Get sys_ids for the chosen service and offering |
| 4 | POST `incident` with `sysparm_input_display_value=true` | Create the ticket (fields below) |
| 5 | If deriving and SILVA left business_service blank: GET `svc_ci_assoc` for the CI. If that is also empty, look up the defaults. | Fill the business service afterwards |
| 6 | PATCH `incident/<sys_id>` with sys_ids only | Set anything still blank, because insert rules can clear fields |
| 7 | Return `stored` (what SILVA actually saved) and `notFilled` | So you can see blanks in the execution log |

POST body:

| SILVA field | Value |
|---|---|
| short_description / description | From step F |
| correlation_id | **display id**, which is the key CLOSE searches for |
| impact / urgency | "4 - Low" labels |
| caller_id | Tech_DynatraceJP_WS |
| contact_type / company / category / subcategory | Event, AXA GROUP OPERATIONS, Other, Other |
| u_host | Host name |
| u_environment | Environment label |
| assignment_group | Routed group |
| cmdb_ci | Host sys_id (only if found) |
| business_service / service_offering | Only when not deriving from the CI |
| assigned_to | Only for the default L2 group |
| comments / work_notes | Customer notes, then sync keys and the metadata block |

### 1.4 Task 2b: `trigger-pagerduty`

Runs in parallel with 2a.

| PagerDuty field | Value |
|---|---|
| event_action | trigger |
| dedup_key | `dt-problem-<display id>`, which CLOSE reuses |
| payload.summary | The short description |
| payload.source | Host name (or "dynatrace") |
| payload.severity | critical, error, warning or info |
| payload.group | Environment |
| payload.component | Application (system key, `app` tag, or EIP) |
| custom_details | Problem id, title, URL, host, IPs, entity, environment, service, group, impact, urgency, severity, correlation id |

---

## Part 2: The CLOSE workflow

### 2.1 Trigger

`event.kind == "DAVIS_PROBLEM"` and (status CLOSED, or transition RESOLVED or CLOSED), with the same categories as OPEN.

### 2.2 Task 1: `prepare-close-ids`

| Value | Source |
|---|---|
| problemId | `display_id`, else `problem.id`, `event.id`, `pid`. It must match what OPEN used. |
| correlationId | problemId |
| dedupKey | `dt-problem-` + problemId |
| title, root entity, evidence (top 3), start and end time | Problems API |
| Duration | end time minus start time, shown as "x h y min" |
| Business service / application (notes only) | Same `SYSTEM_MAP` idea as OPEN, else the `snow-service` tag, else the default |
| closeNotes | "[RESOLVED] ... Duration ... Cause ... Dynatrace link" |
| customerNotes | Cause, links, service block (sent as work_notes) |

### 2.3 Task 2a: `resolve-silva-incident-http`

| Step | Call |
|---|---|
| 1 | GET `incident?sysparm_query=correlation_id=<display id>&sysparm_limit=1` |
| 2 | Nothing found: return `found: false` without failing (OPEN may have been skipped) |
| 3 | Found: PATCH `incident/<sys_id>` with state 6 (Resolved), close_code "Solved (Permanently)", close_notes, comments "Resolved", work_notes |

### 2.4 Task 2b: `resolve-pagerduty`

POST to the PagerDuty Events API with `event_action: resolve` and the same `dedup_key`.

---

## Part 3: The sync keys

| Key | OPEN writes | CLOSE reads |
|---|---|---|
| SILVA `correlation_id` field | display id | GET incident where correlation_id = display id |
| PagerDuty `dedup_key` | dt-problem-display id | resolve with the same key |
| JSON `correlation_id` (inside the description) | root entity id | Not used by CLOSE. It is only there to look like the classic ticket. |

If someone changes how the display id is chosen in one workflow but not the other, CLOSE will not find the ticket.

## Part 4: Risks found while reading the code

| Risk | Where | What happens | Suggested fix |
|---|---|---|---|
| Duplicate incidents | OPEN trigger includes UPDATED | Every problem update creates another INC with the same correlation_id | Remove UPDATED, or GET by correlation_id before the POST and skip if it exists |
| Only one duplicate is closed | CLOSE uses `sysparm_limit=1` | If duplicates exist, the others stay open | Fetch all rows with that correlation_id that are not resolved, and PATCH each |
| EIP forces Production | `SYSTEM_MAP.EIP.environment = "Production"` is checked before the tag | An EIP test problem is labelled Production | Put the tag first, or make the map per environment (seq 31) |
| Placeholder text in close notes | CLOSE `DASHBOARD_URL` and `PD_SERVICE_URL` still contain `__EIP_DASHBOARD_URL__` and `__PD_SERVICE_URL__` | The placeholder text appears in work notes | Set them to "" like OPEN, or fill in real URLs |
| CLOSE host is weaker | CLOSE reads host only from the event | "on host" can be missing in close notes | Cosmetic only |
| Tier is always L2 | `DEFAULT_TIER = "L2"`, and the Production rule also gives L2 | The L1 group is never used | Expected per Abhay. Change DEFAULT_TIER if L1 routing is wanted. |
| Secrets in the file | Password and routing key are hard-coded | Leak risk if pushed (app/Adocs is a GitHub repo) | Do not push. Later move them to Dynatrace credentials. |

## Data flow map

```
                    Dynatrace problem event (trigger)
                                 │
          ┌──────────────────────┴───────────────────────┐
     status ACTIVE                                  status CLOSED
          │                                               │
  prepare-payload                                  prepare-close-ids
   A event: tags, sec-context, affected           display_id → correlationId, dedupKey
   B getProblem: title, severity, root, zones     getProblem → duration, cause, notes
   C evidence event: description, properties              │
   D getEntity: root → HOST → name, IP, tags        ┌─────┴──────────┐
   E decide host / env / service / group           │                │
   F short desc + Additional Information JSON   GET incident      POST PD resolve
          │                                     by correlation_id  dedup_key
     ┌────┴──────────────┐                          │
     │                   │                      PATCH state 6
 GET cmdb_ci (host)   POST PD trigger             Resolved
 POST incident        dedup_key dt-problem-<id>
 (correlation_id = display_id)
 GET svc_ci_assoc if blank
 PATCH blanks
```

## Related files

| File | Purpose |
|---|---|
| `../27-open-match-inc30339746/1-open-silva-http-and-pagerduty.workflow.yaml` | The OPEN workflow explained here |
| `../27-open-match-inc30339746/2-close-silva-http-and-pagerduty.workflow.yaml` | The CLOSE workflow explained here |
| `../28-how-env-service-group-derived/` | Short version of the environment, service and group rules |
| `../31-env-business-service-pairs/` | Per-environment business services for SYSTEM_MAP |
| `../32-silva-common-api-reference/` | The SILVA APIs used by the workflows |
| `33.sh` | Commands to check a run's result in SILVA and Dynatrace |

## Commands

See `33.sh` (not run). For example, check which incidents exist for one problem:

```bash
curl -s -u 'Tech_DynatraceJP_WS:__SNOW_PASSWORD__' -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/incident?sysparm_query=correlation_id=__DISPLAY_ID__%5EORDERBYsys_created_on&sysparm_fields=number,state,sys_created_on,cmdb_ci,business_service,assignment_group,u_environment&sysparm_display_value=true&sysparm_exclude_reference_link=true" | jq '.result'
```
