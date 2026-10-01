# V4 Workflow Flow Logic

## Decision tree

```
Davis problem created (ACTIVE)
 │
 ├─ TASK 1 extract-event-tags  (reads the event, no network except Problems API)
 │    ├─ real event? ── no → use SAMPLE_EVENT (your Oracle input)
 │    ├─ Problems API allowed? ── no → keep going with event only
 │    ├─ parse every tag "KEY:value"
 │    ├─ group tags → group_candidates (support → specific → default)
 │    ├─ service tag → service_tag (none in your input)
 │    ├─ environment tag → label (real env → patch env → security context → default)
 │    ├─ maintenance → event field → AGO_Maintenance tag
 │    └─ host / DB / db_type / trigram / region → search inputs
 │
 ├─ TASK 2 resolve-snow-values  (GET only to SILVA)
 │    ├─ GROUP
 │    │    ├─ GROUP_MAP → check in SILVA
 │    │    ├─ each tag candidate → check in SILVA → first found wins (with sys_id)
 │    │    ├─ none found but tag exists → keep tag name (verified false)
 │    │    └─ no tag → service group → CI group → default
 │    └─ BUSINESS SERVICE
 │         ├─ A SERVICE_MAP or service tag → exact name
 │         ├─ B host / DB CI → CI field → svc_ci_assoc → cmdb_rel_ci
 │         ├─ C searches → score → clear winner ≥ 5
 │         └─ not found → candidates list
 │
 └─ TASK 3 display-result  (no network)
      ├─ group name missing? → ready_for_snow false
      ├─ no service and no CI? → ready_for_snow false
      ├─ maintenance on? → create_incident false
      └─ build SNOW + PagerDuty previews → console.log + return
```

## Short takeaway

| Question | Answer |
|---|---|
| How many tasks? | Three, run one after another |
| Where do values come from? | The Dynatrace event (mainly `entity_tags`) |
| Where is SILVA used? | Only task 2, with GET calls |
| What decides the group? | The group tag. SILVA only adds the sys_id. |
| What decides the business service? | Fixed map, then the CI link, then a scored search |
| Is anything sent? | No. Task 3 only builds previews. |

## Summary

Task 1 turns the raw event into clean inputs. Task 2 uses those inputs to ask SILVA for the group sys_id and the business service. Task 3 checks if SNOW has what it needs and builds the SNOW and PagerDuty bodies without sending them.

## Task 1 — extract-event-tags

### Step by step

| Step | What happens | Your Oracle input |
|---|---|---|
| 1 | Read the trigger event with `ex.event()` | Oracle DB Instance down |
| 2 | If there is no real event (manual Run), use `SAMPLE_EVENT` | Sample = your input4.sh |
| 3 | Call the Problems API for extra tags and evidence | Fails today: missing scope `environment-api:problems:read` |
| 4 | Read `entity_tags` and split each into key and value | 13 tags |
| 5 | Sort tags into AGO tags and other tags | 12 AGO tags, plus `host` and `Test_Maintenance` |
| 6 | Collect group candidates | Database_AXAJP (from the Oracle tag; the default tag has the same value) |
| 7 | Look for a business service tag | None |
| 8 | Work out the environment | ACCEPTANCE → "Integration / Test" |
| 9 | Work out maintenance | Event field first, then `AGO_Maintenance:True` |
| 10 | Pick search inputs | host deaa310b, db_type ORACLE, trigram ALJ, region AP-SOUTHEAST-1 |
| 11 | Build `dynatrace_alert` | Name, severity, profile, problem id, URL |

### How one tag is split

```
"AGO_ORACLE_ASSIGNMENT_GROUP:Database_AXAJP"
          │                        │
          key (before first ":")   value (after first ":")

"[Kubernetes]app:web"  → the "[Kubernetes]" context is removed first
"AGO_DB:ORACLE"        → key AGO_DB, value ORACLE
```

### Which tag feeds which field

| Output field | Tag rule (key, lower case) | Your value |
|---|---|---|
| Group candidates, first | `ago_axa_supportgroup` | none |
| Group candidates, second | ends with `assignment_group` or `support_group`, not the default tag | Database_AXAJP |
| Group candidates, third | `ago_default_assignment_group` | same value, so not added twice |
| Service tag | `snow-service`, `ago_axa_businessservice`, `business-service`, `u_business_service` | none |
| Environment, first choice | `ago_axaenvironmentname` | none |
| Environment, second choice | `env` or `environment` | none |
| Environment, third choice | contains `environment`, not `patch` | none |
| Environment, last choice | contains `patch` and `environment` | ACCEPTANCE |
| DB type | `ago_db` | ORACLE |
| Trigram | contains `trigram` | ALJ |
| Region | contains `region` | AP-SOUTHEAST-1 |
| Platform | contains `platform` | AWS_IAAS |
| Host | `host` | deaa310b |
| Domain | `ago_domain` or contains `domain` | none |

### Non-tag event fields used

| Event field | Used for |
|---|---|
| `display_id` | Problem id, SNOW correlation_id, PagerDuty dedup_key |
| `event.name` | Short description |
| `event.description` | Incident description |
| `event.severity` | Severity |
| `labels.alerting_profile` | Alerting profile |
| `dt.davis.impact_level` | Impact level |
| `affected_entity_types` | Tells which field holds the entity name |
| `dt.entity.sql:...oracle_instance` | DB name (DEA10B01) |
| `root_cause_entity_name` | Service name if present |
| `affected_entity_ids` | Dynatrace entity id (not sent to SILVA) |
| `maintenance.is_under_maintenance` | Maintenance decision |
| `dt.security.context` | Backup source for the environment |

## Task 2 — resolve-snow-values

### Group

| Order | Source | Kept when |
|---|---|---|
| 1 | `GROUP_MAP` in the script | Found active in SILVA |
| 2 | Group tag candidates in order | Found active in SILVA (adds sys_id) |
| 3 | First group tag, even if not found | Always. `verified_in_silva` is false. |
| 4 | Business service assignment group | Only when there is no group tag |
| 5 | Business service support group | Only when there is no group tag |
| 6 | CI support group | Only when there is no group tag |
| 7 | `DEFAULT_GROUP` | Last resort |

### Business service

| Path | What it does | SILVA table |
|---|---|---|
| A | Uses a fixed name from `SERVICE_MAP` or a service tag | `cmdb_ci_service` |
| B1 | Finds the host by name, fqdn and domain list, then by "starts with" | `cmdb_ci` |
| B2 | Finds the DB by exact name, then by "contains" | `cmdb_ci` |
| B3 | Reads the CI's own `business_service` or `service` field (only a real sys_id) | `cmdb_ci` |
| B4 | Looks up the CI-to-service link | `svc_ci_assoc` |
| B5 | Looks for a parent service in relationships | `cmdb_rel_ci` |
| C | Runs up to five searches, merges results, scores each | `cmdb_ci_service`, `cmdb_ci_service_technical` |

### The five searches in path C

| Search | Query idea | Your values |
|---|---|---|
| 1 | Services owned by the group sys_id | Database_AXAJP sys_id |
| 2 | Name contains DB type and environment | Oracle and ACCEPTANCE |
| 3 | Name contains DB type and region | Oracle and AP-SOUTHEAST |
| 4 | Name contains trigram | ALJ |
| 5 | Technical services with DB type and environment | Oracle and ACCEPTANCE |

### Scoring

| Rule | Points |
|---|---|
| Owned by the resolved group | 3 |
| Name has the DB type | 2 |
| Name has the environment tag | 2 |
| Name has the trigram as a whole word | 2 |
| Name has the region prefix | 1 |
| Operational | 1 |
| Is a business service | 1 |
| Found by each extra search | 1 |

A service is picked only if it has at least 5 points and more points than the next one. Otherwise nothing is picked, and the top 10 are shown in `service_candidates`.

### Offering

After a service is found, task 2 reads its offerings and picks the one whose environment matches the label (for example "Integration / Test"). If there is only one offering, it takes that one.

## Task 3 — display-result

| Check | Result |
|---|---|
| Group name exists | Needed for `ready_for_snow` |
| Service sys_id or CI sys_id exists | Needed for `ready_for_snow` |
| Maintenance on and skip enabled | `create_incident` false |
| Everything fine | `create_incident` true (preview only) |

Then it builds:

| Output | Built from |
|---|---|
| `snow_incident_payload` | Alert, group, service, offering, CI, environment, all tags in Additional Information |
| `pagerduty_payload` | Same summary, dedup_key `dt-problem-<display_id>`, placeholder routing key |

## Data flow

```
Dynatrace event
  │  entity_tags, display_id, event.*, maintenance field
  ▼
TASK 1 extract-event-tags
  │  dynatrace_alert
  │  snow_inputs: group_candidates, service_tag, environment,
  │               maintenance, host, db names, db_type, trigram, region
  ▼
TASK 2 resolve-snow-values ── GET ──► SILVA
  │     sys_user_group    → group sys_id
  │     cmdb_ci           → host or DB CI
  │     svc_ci_assoc      → service of CI
  │     cmdb_rel_ci       → parent service
  │     cmdb_ci_service   → searches
  │     service_offering  → offering
  │  snow_required, servicenow_enrichment, candidates, steps
  ▼
TASK 3 display-result
  │  ready_for_snow, missing, decision
  │  snow_incident_payload, pagerduty_payload
  ▼
console.log + task result (nothing sent)
```

## Related files

| File | What it is |
|---|---|
| `../3-extract-v4-business-service-and-group/3-extract-v4-business-service-and-group.workflow.yaml` | The workflow explained here |
| `../4-assignment-group-from-tag/` | Why the tag decides the group |
| `5.sh` | Manual checks for each SILVA step |

## Commands

See `5.sh` for one curl per SILVA step.
